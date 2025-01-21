#!/bin/bash
SCRIPT=$(realpath -s "$0")
SCRIPTPATH=$(dirname "$SCRIPT")
TRACKER_FILE="$SCRIPTPATH/package_tracker.yaml"

# Requires jq, yq and gh
if ! $(which jq &>/dev/null) ; then
	echo "Failed to find jq, aborting" >&2
	exit 1
fi

if ! $(which yq &>/dev/null) ; then
	echo "Failed to find yq, aborting" >&2
	echo "You can install with: sudo snap install yq" >&2
	exit 1
fi

query_source_version()
{
	local source="$1"
	case "$source" in
		"github://"*)
			get_version_github ${source:9}
			;;
		"git://"*)
			get_version_git "https://${source:6}"
			;;
		*)
			echo "Unknown source $source" >&2
			echo ""
			;;
	esac
}

get_version_github() {
	user_repo="$1"
	version="$(gh api -H "Accept: application/vnd.github+json"   -H "X-GitHub-Api-Version: 2022-11-28" /repos/$user_repo/releases/latest | jq -r '.tag_name')"
	# Need some stripping:
	#  - libretro is like v1.20.0
	#  - SDL2 is like release-2.30.11
	echo $version | filter_version
}

get_version_git() {
	giturl="$1"
	(cd /dev/shm ; \
	git clone -q --depth 1 "$giturl" myrepo ; \
	cd myrepo ; \
	git describe --tags $(git rev-list --tags --max-count=1) \
	) | filter_version
	rm -rf /dev/shm/myrepo
}

get_origin_version()
{
	case "$1" in
		"arch")
			get_archlinux_version "$2"
			;;
		"groovy")
			get_groovy_version "$2"
			;;
		*)
			echo "Unknown source $1" >&2
			;;
	esac
}

filter_version() {
	local v="$(< /dev/stdin)"
	echo "$v" | sed -E 's/^(release-|v)//'
}

get_groovy_version()
{
		grep -q '^_pkgver=' "$SCRIPTPATH/../package/$1/PKGBUILD" && v="$(grep '^_pkgver=' "$SCRIPTPATH/../package/$1/PKGBUILD")" || v="$(grep '^pkgver=' "$SCRIPTPATH/../package/$1/PKGBUILD")"
		echo ${v#*=} | filter_version
}

get_archlinux_version()
{
	pkg="$1"
	curl -sL https://archlinux.org/packages/search/json/?name=$pkg | yq '.results[0].pkgver'
}

get_archlinux_flag_date()
{
	pkg="$1"
	curl -sL https://archlinux.org/packages/search/json/?name=$pkg | yq '.results[0].flag_date'
}

prepare_recommendation()
{
	[[ $5 == $4 ]] && echo "" && return
	
	# If it's an arch package, check if it's flagged out of date already
	if [[ $3 == "arch" ]] ; then
		flag_date="$(get_archlinux_flag_date "$1")"
		#~ echo $flag_date >&2
		if [[ -n $flag_date ]] ; then
			echo "Already flagged at Arch"
		else
			echo "Flag at Arch"
		fi
	else
		echo "Needs upgrade"
	fi
}

parse_tracker()
{
	tabbed_output=""
	separator='@'
	for p in $(yq 'sort_keys(.) | keys[]' "$TRACKER_FILE") ; do
		pkgname="$(yq ".${p}.pkg" "$TRACKER_FILE")"
		source="$(yq ".${p}.source" "$TRACKER_FILE")"
		origin="$(yq ".${p}.origin" "$TRACKER_FILE")"
		source_version="$(query_source_version $source)"
		version="$(get_origin_version $origin $pkgname)"
		recommendation=$(prepare_recommendation $pkgname $source $origin $source_version $version)
		#~ echo "$pkgname -> $source"
		tabbed_output+="${p}${separator}${pkgname}${separator}${source_version}${separator}${version}${separator}${recommendation}\n"
	done
	echo -e "$tabbed_output" | column -t -o ' | ' -N App,package,source,arch,recommendation -s "${separator}"
}

tests()
{
	#~ get_version_github libsdl-org/SDL
	#~ get_archlinux_version sdl2
	#~ get_version_git "https://gitlab.freedesktop.org/emersion/drm_info.git"
	parse_tracker
}


tests
