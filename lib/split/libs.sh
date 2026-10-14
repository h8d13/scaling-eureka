#!/usr/bin/bash
#
#   libs.sh - Split shared libraries into $pkgname-libs
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

[[ -n "$LIBMAKEPKG_SPLIT_LIBS_SH" ]] && return
LIBMAKEPKG_SPLIT_LIBS_SH=1

MAKEPKG_LIBRARY=${MAKEPKG_LIBRARY:-'/usr/share/makepkg'}

source "$MAKEPKG_LIBRARY/util/util.sh"

split_types+=('libs')
split_required+=('libs')

# port of abuild default_libs. The main package depends on the result, and
# the libraries keep the main package's depends since pacman has no sibling
# soname tracing yet.
default_split_libs() {
	pkgdesc+=" (libraries)"
	depends=("${main_depends[@]}")

	split_move usr/lib/lib*.so.[0-9]*

	return 0
}
