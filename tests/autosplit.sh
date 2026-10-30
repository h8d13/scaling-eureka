#!/usr/bin/env bash
set -euo pipefail

# builds a dummy package with this tree's makepkg, then checks the splits:
# file names, man pages, optdepends hints, .so provides, arch overrides
root=$(realpath "$(dirname "$0")/..")
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

cat > "$tmp/PKGBUILD" <<'EOF'
pkgname=foo
pkgver=1
pkgrel=1
arch=(x86_64)
license=(0BSD)
options=(!debug)
provides=(libfoo.so)
autosplit=(docs lang libs pyc-opt)

build() {
	printf 'int f(void) { return 0; }\n' |
		gcc -shared -fPIC -Wl,-soname,libfoo.so.1 -x c - -o libfoo.so.1.0
}

package() {
	install -Dm755 libfoo.so.1.0 "$pkgdir/usr/lib/libfoo.so.1.0"
	ln -s libfoo.so.1.0 "$pkgdir/usr/lib/libfoo.so.1"
	ln -s libfoo.so.1 "$pkgdir/usr/lib/libfoo.so"
	install -Dm755 /dev/null "$pkgdir/usr/bin/foo"
	install -Dm644 /dev/null "$pkgdir/usr/share/doc/foo/README"
	install -Dm644 /dev/null "$pkgdir/usr/share/man/man1/foo.1"
	install -Dm644 /dev/null "$pkgdir/usr/share/locale/fr/LC_MESSAGES/foo.mo"
}
EOF

export MAKEPKG_LIBRARY=$root/lib PKGDEST=$tmp/out PKGEXT=.pkg.tar
mkdir "$tmp/out"
cd "$tmp"
# PKGBUILD options=(autodeps) fails lint in 7.1, only the config can set it
cp "$root/makepkg.conf" .
echo 'OPTIONS+=(autodeps)' >> makepkg.conf
mkpkg() {
	"$root/makepkg" --config "$tmp/makepkg.conf" "$@"
}

mkpkg --packagelist > listed
mkpkg --nocheck
find out -name '*.pkg.tar' -printf "$PKGDEST/%f\n" | sort > built

expected="$PKGDEST/foo-1-1-x86_64.pkg.tar
$PKGDEST/foo-docs-1-1-any.pkg.tar
$PKGDEST/foo-lang-1-1-any.pkg.tar
$PKGDEST/foo-libs-1-1-x86_64.pkg.tar
$PKGDEST/foo-pyc-opt-1-1-any.pkg.tar"

ret=0
if [[ $(< listed) != "$expected" ]]; then
	printf 'unexpected --packagelist:\n%s\n' "$(< listed)" >&2
	ret=1
fi
# no python files: pyc-opt is listed but never built
extra=$(comm -13 <(sort listed) built)
if [[ -n $extra ]]; then
	printf 'built but not listed:\n%s\n' "$extra" >&2
	ret=1
fi
# man pages stay with the main package, -docs only takes the rest
if ! bsdtar -tf out/foo-1-1-x86_64.pkg.tar | grep -q '^usr/share/man/'; then
	echo "man pages missing from foo" >&2
	ret=1
fi

# .PKGINFO values of a built package
info() {
	bsdtar -xOf "out/$1-1-1-x86_64.pkg.tar" .PKGINFO | sed -n "s/^$2 = //p"
}

# built splits are hinted, required -libs and empty -pyc-opt are not
hints=$(info foo optdepend)
if [[ $hints != $'foo-docs: documentation\nfoo-lang: translations' ]]; then
	printf 'unexpected optdepends:\n%s\n' "$hints" >&2
	ret=1
fi

# soname provides follow the library into -libs: v1 (provides=(libfoo.so))
# by moving it, v2 (autodeps, lib:) since it scans each package on its own
if [[ $(info foo provides) ||
	$(info foo-libs provides) != $'libfoo.so=1-64\nlib:libfoo.so.1' ]]; then
	printf 'unexpected provides:\n%s\n--\n%s\n' \
		"$(info foo provides)" "$(info foo-libs provides)" >&2
	ret=1
fi

# an override changing arch would build a file --packagelist doesn't name
cat >> PKGBUILD <<'EOF'
split_docs() {
	default_split_docs
	arch=(x86_64)
}
EOF
if mkpkg -f --nocheck; then
	echo "split_docs changed arch, build should fail" >&2
	ret=1
fi
((ret)) || echo "autosplit: ok"
exit $ret
