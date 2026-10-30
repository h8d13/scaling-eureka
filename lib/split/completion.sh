#!/usr/bin/bash
#
#   completion.sh - Split shell completions into $pkgname-<shell>-completion
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

[[ -n "$LIBMAKEPKG_SPLIT_COMPLETION_SH" ]] && return
LIBMAKEPKG_SPLIT_COMPLETION_SH=1

MAKEPKG_LIBRARY=${MAKEPKG_LIBRARY:-'/usr/share/makepkg'}

source "$MAKEPKG_LIBRARY/util/util.sh"

split_types+=('bash-completion' 'zsh-completion' 'fish-completion')
split_any+=('bash-completion' 'zsh-completion' 'fish-completion')

# ports of abuild default_{bash,zsh,fish}comp
default_split_bash-completion() {
	pkgdesc+=" (bash completions)"

	split_move usr/share/bash-completion/completions

	return 0
}

default_split_zsh-completion() {
	pkgdesc+=" (zsh completions)"

	split_move usr/share/zsh/site-functions

	return 0
}

default_split_fish-completion() {
	pkgdesc+=" (fish completions)"

	split_move usr/share/fish/vendor_completions.d usr/share/fish/completions

	return 0
}
