#!/usr/bin/bash
#
#   autosplit.sh - Check the autosplit types and resulting package names
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

[[ -n "$LIBMAKEPKG_LINT_PKGBUILD_AUTOSPLIT_SH" ]] && return
LIBMAKEPKG_LINT_PKGBUILD_AUTOSPLIT_SH=1

MAKEPKG_LIBRARY=${MAKEPKG_LIBRARY:-'/usr/share/makepkg'}

source "$MAKEPKG_LIBRARY/split.sh"
source "$MAKEPKG_LIBRARY/util/message.sh"
source "$MAKEPKG_LIBRARY/util/pkgbuild.sh"
source "$MAKEPKG_LIBRARY/util/util.sh"


lint_pkgbuild_functions+=('lint_autosplit')


lint_autosplit() {
	local type name ret=0
	local -a types

	get_autosplit types
	for type in "${types[@]}"; do
		# PKGBUILDs may add their own types by defining split_<type>
		if ! in_array "$type" "${split_types[@]}" && \
				! have_function "split_$type"; then
			error "$(gettext "%s array contains unknown split type '%s'")" \
					"autosplit" "$type"
			ret=1
		fi

		for name in "${pkgname[@]}"; do
			if in_array "$name-$type" "${pkgname[@]}"; then
				error "$(gettext "%s clashes with split type '%s' of %s")" \
						"$name-$type" "$type" "$name"
				ret=1
			fi
		done
	done

	return $ret
}
