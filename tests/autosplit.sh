#!/usr/bin/env bash
set -euo pipefail

# builds a dummy package with this tree's makepkg, then checks the splits:
# file names, man pages, optdepends hints, arch, rejected custom types
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
autosplit=(docs lang pyc-opt)

package() {
	install -Dm755 /dev/null "$pkgdir/usr/bin/foo"
	install -Dm644 /dev/null "$pkgdir/usr/share/doc/foo/README"
	install -Dm644 /dev/null "$pkgdir/usr/share/man/man1/foo.1"
	install -Dm644 /dev/null "$pkgdir/usr/share/locale/fr/LC_MESSAGES/foo.mo"
}
EOF

export MAKEPKG_LIBRARY=$root/lib PKGDEST=$tmp/out PKGEXT=.pkg.tar
mkdir "$tmp/out"
cd "$tmp"
mkpkg() {
	"$root/makepkg" --config "$root/makepkg.conf" "$@"
}

mkpkg --packagelist > listed
mkpkg --nocheck
find out -name '*.pkg.tar' -printf "$PKGDEST/%f\n" | sort > built

expected="$PKGDEST/foo-1-1-x86_64.pkg.tar
$PKGDEST/foo-docs-1-1-any.pkg.tar
$PKGDEST/foo-lang-1-1-any.pkg.tar
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

# built splits are hinted, empty -pyc-opt is not
hints=$(bsdtar -xOf out/foo-1-1-x86_64.pkg.tar .PKGINFO |
	sed -n 's/^optdepend = //p')
if [[ $hints != $'foo-docs: documentation\nfoo-lang: translations' ]]; then
	printf 'unexpected optdepends:\n%s\n' "$hints" >&2
	ret=1
fi

# an override changing arch would build a file --packagelist doesn't name
cp PKGBUILD PKGBUILD.orig
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

# per-package splits (-qt) go in pkgname=(), not autosplit
sed 's/^autosplit=(docs/autosplit=(qt docs/' PKGBUILD.orig > PKGBUILD
echo 'split_qt() { :; }' >> PKGBUILD
if mkpkg -f --nocheck; then
	echo "custom split type qt accepted, build should fail" >&2
	ret=1
fi
((ret)) || echo "autosplit: ok"
exit $ret
