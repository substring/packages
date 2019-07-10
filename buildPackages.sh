#!/bin/bash
#set -x

# shellcheck disable=SC1091
source include.sh
_output="$_OUTPUT"
built_packages="$_output/built_packages_$(date +%s%3N)"
export CCACHE_DIR=/work/cache/ccache

extract_package_name() {
  # sadly this method doesn't work fine for a git package in the form of advancemenuplus-git-ff27752-1-x86_64.pkg.tar.xz
  echo "$1" | sed -E "s+([[:alnum:]-]*)-[0-9].*+\1+"
}

# Expects that cwd has a PKGBUILD
# returns 0 if should build
# returns 1 if package was downloaded from repo
# returns 255 in case of an error
check_if_download_or_build() {
  local repo_found
  [[ ! -f PKGBUILD ]] && return 255
  for pkgfile in $(makepkg --packagelist) ; do
    filename=$(basename "$pkgfile")
    pkgname=$(extract_package_name "$filename")
    
    # Exceptions ... This is dirty sadly
    case $pkgname in
      mame)
        pkgname=groovymame
        filename="groovy$filename"
        ;;
      advancemenuplus-git-*)
        pkgname=advancemenuplus
        ;;
    esac
    
    echo "Package name was determined as: $pkgname"
    for repo in groovyarcade-testing groovyarcade ; do
      repo_package_name=$(pacman -Sl $repo | sed -E "s/groovyarcade ([[:alnum:][:punct:]]+) ([[:alnum:][:punct:]]+)/\1-\2-$(uname -m).pkg.tar.xz/" | grep "^$pkgname")
      if [[ -n $repo_package_name ]] ; then
        echo "Found $pkgname in repo $repo"
        repo_found="$repo"
        break
      fi
    done
    if [[ -n $repo_found ]] ; then
      # YES: fine, just download it for a createrepo later, no need to build
      log "$filename is in the $repo_found repo -> download and copy to $_output"
      sudo pacman -Sddw --noconfirm "$pkgname" || return 255
      # Again dirty trick : linux means 4 packages, advancemenu-git packages name is tricked
      # So circumvent those 2 cases
      if [[ -f /var/cache/pacman/pkg/"$repo_package_name" ]] ; then
        # Need to copy as $"filename because of what built_packages file will hold
        cp /var/cache/pacman/pkg/"$repo_package_name" "$_output"/"$filename" || return 255
        return 1
      elif [[ -f /var/cache/pacman/pkg/"$filename" ]] ; then
        cp /var/cache/pacman/pkg/"$filename" "$_output" || return 255
        return 1
      else
        echo "Couldn't determine downloaded package filename. Aborting..." >&2
        return 255
      fi
    else
      log "$filename is not in the repo -> BUILD IT!!!"
      return 0
    fi
  done
}

post_build() {
  # TODO: if we've exited just above, the following folder would always exist, could cause some confusion
  mkdir -p "${_output}/${package}"
  makepkg --printsrcinfo > "${_output}/${package}/".SRCINFO
  cp PKGBUILD "${_output}/${package}"
  makepkg --packagelist >> "$built_packages"

  # use the SRCINFO to find the current version and purge previous versions of the package
  echo
  return 0
}

do_the_job() {
  echo "+-------------------------"
  echo "| Building $package"
  echo "+-------------------------"

  package="$1"

  if [[ -x /work/package/$package/patch.sh ]] ; then
    echo "Applying patch /work/package/$package/patch.sh"
    /work/package/"$package"/patch.sh || return 1
  fi

  cwd="$(pwd)"
  # Handle community/AUR package
  for pkgdir in "/work/$package/repos/core-x86_64" "/work/$package/repos/community-x86_64" "/work/$package" "/work/package/$package" ; do
    if [[ -d "$pkgdir" ]] ; then
      cd "$pkgdir" || return 1
      break
    fi
  done
  if [[ $cwd == $(pwd) ]] ; then
    err "Haven't found any package dir for $package"
    return 1
  fi

  check_if_download_or_build
  rc=$?
  # Had to download the file
  [[ $rc == 1 ]] && post_build && return 0
  # Something went wrong, abort
  [[ $rc == 255 ]] && return 1


  # The CI can set MAKEPKG_OPTS to "--nobuild --nodeps" for a simple basic check for every branch not tag nor master)
  # So if empty, set some default value
  export MAKEPKG_OPTS=${MAKEPKG_OPTS:-"--syncdeps"}
  # shellcheck disable=SC2086
  PKGDEST="$_output" makepkg --noconfirm --skippgpcheck $MAKEPKG_OPTS

  # rc=13 if the package was already built -> skip that error
  # This only happens in a local build
  rc=$?
  if [[ $rc != 0 && $rc != 13 ]] ; then
    echo "rc= $rc"
    return 2
  elif [[ $rc == 13 ]] ; then
    echo "Output package already exists, can recover and keep going..."
  fi

  post_build
}

build_native() {
# Native arch packages
while read -r package ; do
  echo "$package" | grep -q "^#" && continue
  cd /work || { echo "Couldn't cd to the work dir" ; exit 1 ; } 
  asp update "$package"
  asp checkout "$package"
  do_the_job "$package" || exit 1
done < <(grep "^${package_to_build}$" /work/packages_arch.lst)
}

build_aur() {
# AUR packages
while read -r package ; do
  echo "$package" | grep -q "^#" && continue
  cd /work || { echo "Couldn't cd to work dir" ; exit 1 ; } 
  wget https://aur.archlinux.org/cgit/aur.git/snapshot/"${package}".tar.gz
  tar xvzf "${package}".tar.gz
  do_the_job "$package" || exit 1
done < <(grep "^${package_to_build}$" /work/packages_aur.lst)
}

build_groovy() {
while read -r package ; do
  echo "$package" | grep -q "^#" && continue
  cd /work || { echo "Couldn't cd to work dir" ; exit 1 ; } 
  cp -R package/"$package" .
  do_the_job "$package" || exit 1
done < <(grep "^${package_to_build}$" /work/packages_groovy.lst)
}

namcap_packages() {
for pack in /work/output/*.pkg.tar.xz ; do
  namcap -i "$pack"
done
}

rm "$_output"/built_packages* 2>/dev/null

package_to_build=".*"
# Parse command line
# shellcheck disable=SC2220
while getopts "nagc" option; do
  case "${option}" in
    n)
      build_native
      exit $?
      ;;
    a)
      build_aur
      exit $?
      ;;
    g)
      build_groovy
      exit $?
      ;;
    c)
      namcap_packages
      exit $?
      ;;
  esac
done

# Tricky thing : if $1 exists, it's a package
# as we'll grep the .lst files, we need a trick if $1 is empty
package_to_build=${1:-".*"}

build_native ; build_aur ; build_groovy

# run tests on output packages
