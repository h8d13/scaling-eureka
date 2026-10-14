#!/usr/bin/bash
#
#   doc.sh - Split documentation into $pkgname-doc
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

[[ -n "$LIBMAKEPKG_SPLIT_DOC_SH" ]] && return
LIBMAKEPKG_SPLIT_DOC_SH=1

MAKEPKG_LIBRARY=${MAKEPKG_LIBRARY:-'/usr/share/makepkg'}

source "$MAKEPKG_LIBRARY/util/util.sh"

split_types+=('doc')

# port of abuild default_doc, minus licenses (kept in every package) and
# man page compression (done by the zipman option)
default_split_doc() {
	local d

	pkgdesc+=" (documentation)"
	arch=('any')

	for d in doc man info html sgml gtk-doc ri help; do
		split_move "usr/share/$d"
	done

	return 0
}
