#!/usr/bin/bash
#
#   pyc-opt.sh - Split optimized Python bytecode into $pkgname-pyc-opt
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

[[ -n "$LIBMAKEPKG_SPLIT_PYC_OPT_SH" ]] && return
LIBMAKEPKG_SPLIT_PYC_OPT_SH=1

MAKEPKG_LIBRARY=${MAKEPKG_LIBRARY:-'/usr/share/makepkg'}

source "$MAKEPKG_LIBRARY/util/util.sh"

split_types+=('pyc-opt')
split_any+=('pyc-opt')

# Only read by python -O/-OO, unlike plain .pyc which unprivileged users can
# not regenerate under /usr. abuild default_pyc moves all three levels and
# relies on install_if to bring them back, which pacman lacks.
default_split_pyc-opt() {
	local -a dirs files

	pkgdesc+=" (optimized bytecode for python -O/-OO)"
	depends=("$pkgname=$(get_full_version)")

	dirs=(usr/lib/python3*)
	[[ -d ${dirs[0]} ]] || return 0

	mapfile -d '' -t files < <(find "${dirs[@]}" -path '*/__pycache__/*' \
		\( -name '*.opt-1.pyc' -o -name '*.opt-2.pyc' \) -print0)
	(( ${#files[@]} )) && split_move "${files[@]}"

	return 0
}
