#!/usr/bin/bash
#
#   split.sh - functions for automatically splitting packages
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

[[ -n "$LIBMAKEPKG_SPLIT_SH" ]] && return
LIBMAKEPKG_SPLIT_SH=1

MAKEPKG_LIBRARY=${MAKEPKG_LIBRARY:-'/usr/share/makepkg'}

source "$MAKEPKG_LIBRARY/util/message.sh"
source "$MAKEPKG_LIBRARY/util/option.sh"
source "$MAKEPKG_LIBRARY/util/pkgbuild.sh"
source "$MAKEPKG_LIBRARY/util/util.sh"


declare -a split_types split_required split_any
declare -A split_desc

# sourced before tidy.sh, which marks packaging_options readonly
packaging_options+=('autosplit')

for lib in "$MAKEPKG_LIBRARY/split/"*.sh; do
	source "$lib"
done

readonly -a split_types split_required split_any
readonly -A split_desc


# PKGBUILD autosplit=() wins over AUTOSPLIT from makepkg.conf
get_autosplit() {
	local -n _types=$1

	if (( ${#autosplit[@]} )); then
		_types=("${autosplit[@]}")
	else
		_types=("${AUTOSPLIT[@]}")
	fi
}

# Move paths, relative to $pkgdir, into $splitdir. Parent directories are
# recreated with their original mode and owner, emptied ones are removed.
# Returns 1 if any path did not exist, mirroring abuild's amove.
split_move() {
	local f d parents olddir=$PWD ret=0

	cd_safe "$pkgdir"
	for f in "$@"; do
		f=${f#/}
		f=${f%/}
		if [[ ! -e $f && ! -L $f ]]; then
			ret=1
			continue
		fi

		d=${f%/*}
		[[ $d = "$f" ]] && d=.

		if [[ ! -d $splitdir/$d ]]; then
			parents=("$d")
			while [[ ${parents[0]} = */* ]]; do
				parents=("${parents[0]%/*}" "${parents[@]}")
			done
			bsdtar -cnf - "${parents[@]}" | bsdtar -xpf - -C "$splitdir"
		fi
		mv "$f" "$splitdir/$d/"

		while [[ $d != . ]] && dir_is_empty "$d"; do
			rmdir "$d"
			if [[ $d = */* ]]; then
				d=${d%/*}
			else
				d=.
			fi
		done
	done

	cd_safe "$olddir"
	return $ret
}

# Call in a subshell, it resets package metadata before carving $splitdir.
# Split functions start in $pkgdir, like abuild's pre_split, and can read
# the main package's depends from main_depends.
run_split_function() {
	local -a main_depends=("${depends[@]}")

	unset groups provides conflicts replaces backup install changelog \
		optdepends depends
	pkgtype=split
	[[ -n ${split_desc[$1]} ]] && pkgdesc+=" (${split_desc[$1]})"
	# known before the split runs, so --packagelist can name it
	in_array "$1" "${split_any[@]}" && arch=('any')
	local -a split_arch=("${arch[@]}")
	cd_safe "$pkgdir"

	# PKGBUILD override, may call default_split_$1 itself
	if have_function "split_$1"; then
		"split_$1" || return
	else
		"default_split_$1" || return
	fi

	# else the built file no longer matches its --packagelist name
	if [[ ${arch[*]} != "${split_arch[*]}" ]]; then
		error "$(gettext "%s may not change arch, it is set by the split type")" \
				"split_$1"
		return 1
	fi
}

run_autosplit() {
	local type split splitdir
	local -a types

	check_option "autosplit" "n" && return 0

	get_autosplit types
	for type in "${types[@]}"; do
		split=$pkgname-$type
		splitdir="$pkgdirbase/$split"
		mkdir "$splitdir" || exit $E_PACKAGE_FAILED

		# metadata changes must not leak into the main package
		(
			run_split_function "$type" || exit $E_PACKAGE_FAILED

			if dir_is_empty "$splitdir"; then
				rmdir "$splitdir"
				exit 0
			fi

			msg "$(gettext "Splitting \"%s\"...")" "$split"
			pkgname=$split
			pkgdir=$splitdir
			lint_package || exit $E_PACKAGE_FAILED
			create_package
		) || exit $?

		[[ -d $splitdir ]] || continue
		# e.g. binaries left in the main package link against -libs
		if in_array "$type" "${split_required[@]}"; then
			depends+=("$split=$(get_full_version)")
		else
			# pacman shows it on install, else the split goes unnoticed
			optdepends+=("$split${split_desc[$type]:+: ${split_desc[$type]}}")
		fi
	done
}
