#!/usr/bin/bash
#
#   static.sh - Split static libraries into $pkgname-static
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

[[ -n "$LIBMAKEPKG_SPLIT_STATIC_SH" ]] && return
LIBMAKEPKG_SPLIT_STATIC_SH=1

MAKEPKG_LIBRARY=${MAKEPKG_LIBRARY:-'/usr/share/makepkg'}

source "$MAKEPKG_LIBRARY/util/util.sh"

split_types+=('static')

# port of abuild default_static. Only sees the .a files left by the
# staticlibs option, which by default drops those with a .so sibling.
default_split_static() {
	local -a files types

	pkgdesc+=" (static libraries)"
	get_autosplit types
	if in_array dev "${types[@]}"; then
		depends=("$pkgname-dev=$(get_full_version)")
	else
		depends=("$pkgname=$(get_full_version)")
	fi

	[[ -d usr ]] || return 0
	mapfile -d '' -t files < <(find usr -name '*.a' -print0)
	(( ${#files[@]} )) && split_move "${files[@]}"

	return 0
}
