#!/usr/bin/bash
#
#   dev.sh - Split development files into $pkgname-dev
#
#   Copyright (c) 2026 Pacman Development Team <pacman-dev@lists.archlinux.org>
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

[[ -n "$LIBMAKEPKG_SPLIT_DEV_SH" ]] && return
LIBMAKEPKG_SPLIT_DEV_SH=1

MAKEPKG_LIBRARY=${MAKEPKG_LIBRARY:-'/usr/share/makepkg'}

source "$MAKEPKG_LIBRARY/util/util.sh"

split_types+=('dev')

# port of abuild default_dev
default_split_dev() {
	local f
	local -a files types

	pkgdesc+=" (development files)"
	depends=("$pkgname=$(get_full_version)")

	split_move usr/include usr/lib/pkgconfig usr/share/pkgconfig \
		usr/share/aclocal usr/share/gettext usr/bin/*-config \
		usr/share/vala/vapi usr/share/gir-[0-9]* usr/share/qt*/mkspecs \
		usr/lib/qt*/mkspecs usr/lib/cmake usr/share/cmake \
		usr/lib/glade/modules usr/share/glade/catalogs

	[[ -d usr ]] || return 0

	# static libraries stay here unless a static split takes them
	get_autosplit types
	if ! in_array static "${types[@]}"; then
		mapfile -d '' -t -O "${#files[@]}" files \
			< <(find usr -name '*.a' -print0)
	fi
	# whole include dirs, loose sources/objects elsewhere
	mapfile -d '' -t -O "${#files[@]}" files < <(find usr \
		-name include -type d -prune -print0 -o \
		\( -name '*.[cho]' -o -name '*.prl' \) -print0)
	(( ${#files[@]} )) && split_move "${files[@]}"

	# unversioned .so links are only needed to link against the library
	for f in usr/lib/*.so; do
		[[ -L $f ]] && split_move "$f"
	done

	return 0
}
