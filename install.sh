#!/bin/bash
#
# install.sh - Installer for latest Sweet Home 3D
#
# Copyright (C) 2023 Rodrigo Silva (MestreLion) <linux@rodrigosilva.com>
# License: GPLv3 or later, at your choice. See <http://www.gnu.org/licenses/gpl>
#------------------------------------------------------------------------------
set -Eeuo pipefail  # exit on any error
trap '>&2 echo "error: line $LINENO, status $?: $BASH_COMMAND"' ERR
#------------------------------------------------------------------------------

slug=sweethome3d
prefix=$HOME/.local/opt

#------------------------------------------------------------------------------

self=${0##*/}
here=$(dirname "$(readlink -f "$0")")

debdir=$here/sweethome3d_7.0.2+dfsg-3_all
srcdir=$here/SweetHome3D-7.2

exec=SweetHome3D  # relative to source dir
icon=SweetHome3DIcon.png  # relative to source dir
size=128

#------------------------------------------------------------------------------

argerr()  { printf "%s: %s\n" "$self" "${1:-error}" >&2; usage 1; }
missing() { argerr "missing ${1:+$1 }argument${2:+ from $2}."; }
relpath() { local base=$1; shift; realpath --relative-to="$base" "$@"; }
usage() {
	if [[ "${1:-}" ]] ; then exec >&2; fi
	cat <<-USAGE
	Usage: $self [options]
	USAGE
	if [[ "${1:-}" ]] ; then
		cat <<- USAGE
		Try '$self --help' for more information.
		USAGE
		exit 1
	fi
	cat <<-USAGE

	Sweet Home 3D installer for Debian/Ubuntu

	Options:
	  -h|--help - show this page.
	  -s|--source-dir DIR - Upstream sources directory   [Default: $(relpath . ${srcdir})]
	  -d|--debian-dir DIR - Debian integration directory [Default: $(relpath . ${debdir})]

	Will install as '${slug}' at ${prefix}/${slug}

	Copyright (C) 2023 Rodrigo Silva (MestreLion) <linux@rodrigosilva.com>
	License: GPLv3 or later. See <http://www.gnu.org/licenses/gpl.html>
	USAGE
	exit 0
}
for arg in "$@"; do [[ "$arg" == "-h" || "$arg" == "--help" ]] && usage ; done
while (($#)); do
	# shellcheck disable=SC2221,SC2222
	case "$1" in
	-s|--source-dir) shift; srcdir=${1:-};;
	--source-dir=*) srcdir=${1#*=};;
	-d|--debian-dir) shift; debdir=${1:-};;
	--debian-dir=*) debdir=${1#*=};;
	*) argerr "$1";;
	esac
	shift || break
done

#------------------------------------------------------------------------------

[[ "${srcdir:-}" ]] || missing "DIR" "--source-dir"
[[ "${debdir:-}" ]] || missing "DIR" "--debian-dir"

desktop=$debdir/usr/share/applications/sweethome3d.desktop
manual=$debdir/usr/share/man/man1/sweethome3d.1.gz
mime=$debdir/usr/share/mime/packages/sweethome3d.xml

target=$prefix/$slug  # assumed to be inside $prefix
mandir=${XDG_DATA_HOME:-$HOME/.local/share}/man/man1
mimetarget=$target/$(basename -- "$mime" .xml).mimeinfo.xml

#------------------------------------------------------------------------------

echo "Installing to $target"

# Create needed tree
mkdir -pv -- "$(dirname -- "$target")" "$mandir"

# Copy sources
cp -aT -- "$srcdir" "$target"

# Patch executable (add '-f' to `readlink`)
cp -av -- "$target"/{"$exec","$slug"}
sed -i '/^PROGRAM=/s/readlink "/readlink -f "/' -- "$target"/"$slug"

# Patch mime (add icon)
sed -e '/<glob/a\' -e '     <icon name="sweethome3d"/>' "$mime" > "$mimetarget"

# Install integration
ln -srfv -- "$target"/"$slug" "${XDG_BIN_HOME:-$HOME/.local/bin}"/"$slug"
cp -v -t "$mandir" -- "$manual"
xdg-icon-resource install --novendor --size "$size" "$target"/"$icon" "$slug"
xdg-mime          install --novendor "$mimetarget"
xdg-desktop-menu  install --novendor "$desktop"
