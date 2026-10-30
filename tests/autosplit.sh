#!/usr/bin/env bash
set -euo pipefail

# builds a dummy package with this tree's makepkg, then checks that
# --packagelist names every built file, splits included
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
autosplit=(docs lang dev)

package() {
	install -Dm755 /dev/null "$pkgdir/usr/bin/foo"
	install -Dm644 /dev/null "$pkgdir/usr/share/doc/foo/README"
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
$PKGDEST/foo-dev-1-1-x86_64.pkg.tar"

ret=0
if [[ $(< listed) != "$expected" ]]; then
	printf 'unexpected --packagelist:\n%s\n' "$(< listed)" >&2
	ret=1
fi
# dev has nothing to carve, listed but never built
extra=$(comm -13 <(sort listed) built)
if [[ -n $extra ]]; then
	printf 'built but not listed:\n%s\n' "$extra" >&2
	ret=1
fi
((ret)) || echo "autosplit: ok"
exit $ret
