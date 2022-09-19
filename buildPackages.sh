#!/bin/bash
#set -x

# shellcheck disable=SC1091
source include.sh
_output="$_OUTPUT"
BUILD_DIR=/work/build
built_packages="$_output/built_packages_$(date +%s%3N)"
packages_subfolder=package

extract_package_name() {
  echo "$1" | sed -E "s+([[:alnum:]-]*)(-git)?-.*-[0-9]*.*+\1\2+"
}


# Expects that cwd has a PKGBUILD
# returns 0 if should build
# returns 1 if package was downloaded from repo
# returns 255 in case of an error
check_if_download_or_build() {
  local repo_found
  local rc
  local repo_package_name
  local pkg_version
  local repos="groovyarcade-testing groovyarcade"
  [[ ! -f PKGBUILD ]] && return 255

  # Take care of a non standard package folder, adapt the repo
  case "$packages_subfolder" in
      package-nox11)
        repos="groovymame-nox11"
        ;;
  esac

  for pkgfile in $(makepkg --packagelist) ; do
    log "Processing $pkgfile..."
    filename=$(basename "$pkgfile")
    pkgname=$(extract_package_name "$filename")

    # Exceptions ... This is dirty sadly
    case $pkgname in
      advancemenuplus-git-*)
        pkgname=advancemenuplus-git
        ;;
    esac

    echo "Package name was determined as: $pkgname"
    for repo in $repos ; do
      # Remove repo name, match exact package name, convert to filename
      repo_package_name=$(pacman -Sl $repo | sed "s/^$repo //g" | grep "^$pkgname " | sed -E "s/$repo ([[:alnum:][:punct:]]+) ([[:alnum:][:punct:]]+)/\1-\2-$(uname -m).pkg.tar.zst/")
      pkg_version=$(pacman -Sl $repo | grep "^$repo $pkgname" | cut -d ' ' -f 3)
      if [[ -n $repo_package_name ]] && echo "$filename" | grep -q "$pkg_version" && sudo pacman -Sddw --noconfirm "$repo"/"$pkgname"; then
        echo "Found $pkgname in repo $repo may not have been downloaded from it, but it's here at last"
        repo_found="$repo"
        break
      fi
    done
    if [[ -n $repo_found ]] ; then
      # YES: fine, just download it for a createrepo later, no need to build
      # Again dirty trick : linux means 3 packages, advancemenu-git packages name is tricked
      # So circumvent those 2 cases
      if [[ -f /var/cache/pacman/pkg/"$repo_package_name" ]] ; then
        # Need to copy as $"filename because of what built_packages file will hold
        cp /var/cache/pacman/pkg/"$repo_package_name" "$_output"/"$filename" || return 255
      elif [[ -f /var/cache/pacman/pkg/"$filename" ]] ; then
        cp /var/cache/pacman/pkg/"$filename" "$_output" || return 255
      else
        echo "Couldn't determine downloaded package filename. Aborting..." >&2
        return 255
      fi
    else
      # If a PKGBUILD builds multiple packages, if any is not available, rebuild all anyway
      log "$filename is in no repo -> BUILD IT!!!"
      return 0
    fi
  done

  # If we reach this case, it's because we 've downloaded pkg from the repos
  return 1
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
  echo "| Building ${packages_subfolder}/$package"
  echo "+-------------------------"

  package="$1"

  cwd="$(pwd)"
  # Handle community/AUR package
  for pkgdir in "$BUILD_DIR"/"$package"/repos/core-x86_64 "$BUILD_DIR"/"$package"/repos/extra-x86_64 "$BUILD_DIR"/"$package"/repos/community-x86_64 "$BUILD_DIR"/"$package" ; do
    if [[ -d "$pkgdir" ]] ; then
      cd "$pkgdir" || return 1
      break
    fi
  done
  if [[ $cwd == $(pwd) ]] ; then
    err "Haven't found any package dir for $package"
    return 1
  fi

  # Copy required patch files that would be used in PKGBUILD
  # shellcheck disable=SC2046,SC2014
  find /work/"${packages_subfolder}"/"$package" -maxdepth 1 \( -name "*.patch" -o -name "*.diff" \) -exec echo Copying {} to $(pwd) \; -exec cp {} $(pwd) \;

  # Use the prepatch shell if it exists
  if [[ -x /work/"${packages_subfolder}"/$package/patch.sh ]] ; then
    echo "Applying patch /work/${packages_subfolder}/$package/patch.sh"
    /work/"${packages_subfolder}"/"$package"/patch.sh || return 1
    # patch.sh may have added new files, let's update checksums
    updpkgsums
  fi

  if [[ $DONT_DOWNLOAD_JUST_BUILD != 1 ]] ; then
    check_if_download_or_build
    rc=$?
  else
    rc=0
  fi
  # Could download the file
  [[ $rc == 1 ]] && post_build && return 0
  # Something went wrong, abort -> no, just build the package
  #[[ $rc == 255 ]] && return 1

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

  # Uninstall sfml related packages to allow building both AM and AM+ in the same run
  pacman -Q sfml &>/dev/null && sudo pacman -Rdd --noconfirm "$(pacman -Q sfml | cut -d ' ' -f 1)"

  post_build
}

build_native_single() {
  package="$1"
  cd "$BUILD_DIR" || { echo "Couldn't cd to the work dir" ; exit 1 ; }
  asp update "$package"
  asp checkout "$package"
  do_the_job "$package" || exit 1
}


build_native() {
# Native arch packages
while read -r package ; do
  echo "$package" | grep -q "^#" && continue
  build_native_single "$package" || exit 1
done < <(grep -E "^${package_to_build}$" /work/packages_arch.lst)
}


build_aur_single() {
  package="$1"
  cd "$BUILD_DIR" || { echo "Couldn't cd to $BUILD_DIR dir" ; exit 1 ; }
  wget https://aur.archlinux.org/cgit/aur.git/snapshot/"${package}".tar.gz || return 1
  tar xvzf "${package}".tar.gz
  do_the_job "$package" || exit 1
}


build_aur() {
# AUR packages
while read -r package ; do
  echo "$package" | grep -q "^#" && continue
  build_aur_single "$package" || exit 1
done < <(grep "^${package_to_build}$" /work/packages_aur.lst)
}


build_groovy_single() {
  package="$1"
  cd "$BUILD_DIR" || { echo "Couldn't cd to $BUILD_DIR dir" ; exit 1 ; }
  cp -R /work/"$packages_subfolder"/"$package" . || return 1
  do_the_job "$package" || exit 1
}


build_groovy() {
while read -r package ; do
  echo "$package" | grep -q "^#" && continue
  build_groovy_single "$package" || exit 1
done < <(grep "^${package_to_build}$" /work/packages_groovy.lst)
}


build_dkms() {
while read -r package ; do
  echo "$package" | grep -q "^#" && continue
  build_single_package "$package" || exit 1
done < <(grep "^${package_to_build}$" /work/packages_dkms.lst)
}


namcap_packages() {
for pack in /work/output/*.pkg.tar.zst ; do
  namcap -i "$pack"
done
}


build_single_package() {
  cmd_arg="$1"
  pkgname=${1#*/}
  if [[ $cmd_arg =~ ^aur/ ]] ; then
    # that's a AUR package, let's build it
    build_aur_single "$pkgname"
    [[ $? != 0 ]] && exit $?
  elif [[ $cmd_arg =~ ^groovy/ ]] ; then
    # that's a groovy package, let's build it
    build_groovy_single "$pkgname"
    [[ $? != 0 ]] && exit $?
  else
    # Fallback to a genuine arch package
    build_native_single "$pkgname"
    [[ $? != 0 ]] && exit $?
  fi
  return 0
}


build_sfml_and_attractplus() {
  export MAKEPKG_OPTS="--syncdeps --install $MAKEPKG_OPTS"
  build_single_package groovy/sfml-drm-static
  build_single_package groovy/attractplus-kms
  sudo pacman -R --noconfirm sfml-drm-static
  build_single_package groovy/sfml-static
  build_single_package groovy/attractplus-x11
  sudo pacman -R --noconfirm sfml-static
  build_single_package groovy/attractplus
}

rm "$_output"/built_packages* 2>/dev/null
mkdir -p "$BUILD_DIR"

package_to_build=".*"
# Parse command line
# shellcheck disable=SC2220
while getopts "nagcs:dp:o" option; do
  case "${option}" in
    n)
      # WARNING: very dirty trick to exclude building mame and linux
      # Those must be specified on the script args individually
      package_to_build="($(grep -v -e "^linux$" -e "^mame$" /work/packages_arch.lst | paste -sd "|" - | tr -d '\n'))"
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
    s)
      build_single_package "$OPTARG"
      exit $?
      ;;
    d)
      build_dkms
      exit $?
      ;;
    p)
      packages_subfolder="$OPTARG"
      ;;
    o)
      build_sfml_and_attractplus
      ;;
  esac
done

# Tricky thing : if $1 exists, it's a package
# as we'll grep the .lst files, we need a trick if $1 is empty

package_to_build=${1:-".*"}

build_native ; build_aur ; build_groovy

# run tests on output packages
