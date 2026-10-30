#!/usr/bin/bash
#
#   docs.sh - Split documentation into $pkgname-docs
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

[[ -n "$LIBMAKEPKG_SPLIT_DOCS_SH" ]] && return
LIBMAKEPKG_SPLIT_DOCS_SH=1

MAKEPKG_LIBRARY=${MAKEPKG_LIBRARY:-'/usr/share/makepkg'}

source "$MAKEPKG_LIBRARY/util/util.sh"

split_types+=('docs')
split_desc[docs]='documentation'
split_any+=('docs')

# port of abuild default_doc, minus licenses (kept in every package) and
# man pages (kept in the main package, as Arch does with -docs splits)
default_split_docs() {
	local d

	for d in doc info html sgml gtk-doc ri help; do
		split_move "usr/share/$d"
	done

	return 0
}
