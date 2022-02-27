#!/bin/bash
set -e

source settings
source include.sh

cancel_and_exit() {
  echo "Required cancel of release. Deleting the release" >&2
  delete_release
  exit 1
}

#
# Check we have something to upload
#
need_assets() {
  if [[ ! -d "$_OUTPUT" ]] ; then
    echo "ERROR: no work dir found"
    exit 1
  fi
}

#
# Create a release
#
create_release() {
  echo "Creating release $tag"
  if [[ $1 != "stable" ]] ; then
$ghr release create "$tag" \
    -R "$GITHUB_USER"/"$GITHUB_REPO" \
    --notes "Automatic build for $(date +"%Y-%m-%d %T") update" \
    --prerelease
  else
$ghr release create "$tag" \
    -R "$GITHUB_USER"/"$GITHUB_REPO" \
    --title "$release_name" \
    --notes "automatic build"
  fi
}

#
# Upload packages
#
upload_assets() {
need_assets
packages_list="$(built_packages_list)"
while read -r file ; do
  filename=$(basename "$file")
  echo "Uploading $filename ($file)..."
  # Upload files
  $ghr release upload "$tag" \
    "${_OUTPUT}/$filename"  \
    -R "$GITHUB_USER"/"$GITHUB_REPO" \
    --clobber || cancel_and_exit
done < "$packages_list"
}

#
# Upload pacman repo data
#
upload_repo() {
need_assets

# Just build the repo only if packages are available
echo "Preparing the repo"
command -v repo-add || cancel_and_exit
# determine repo name
repo_name=groovyarcade
[[ $tag != "stable" ]] && repo_name="${repo_name}-${tag}"
ls "${_OUTPUT}"/*.pkg.tar.zst >/dev/null && repo-add "${_OUTPUT}"/"$repo_name".db.tar.gz "${_OUTPUT}"/*.pkg.tar.zst

for file in "${_OUTPUT}"/"$repo_name".files* "${_OUTPUT}"/"$repo_name".db* ; do
  filename=$(basename "$file")
  echo "Uploading repo data $filename ..."
  # Upload files
  $ghr release upload "$tag" \
    "${_OUTPUT}/$filename"  \
    -R "$GITHUB_USER"/"$GITHUB_REPO" \
    --clobber || cancel_and_exit
done
}


#
# Make the release definitive
# This is deprecated since the move to github cli as it can't edit a release.
# Now we upload all assets, and repo data in last. That way, the repo is only
# working once last files have been uploaded
#
publish_release() {
echo "Publihing release $tag"
if [[ $tag != "stable" ]] ; then
$ghr edit \
    --tag "$tag" \
    --name "$tag" \
    --pre-release \
    --description "Automatic build for $(date +"%Y-%m-%d %T") update" || cancel_and_exit
else
$ghr edit \
    --tag "$tag" \
    --name "$tag" \
    --description "Automatic build for $(date +"%Y-%m-%d %T") update" || cancel_and_exit
fi
}

#
# Remove a release
#
delete_release() {
# Shouldn't crash if the release doesn't exist
set +e
echo "Deleting release $tag..."
$ghr release delete "$tag" \
    -R "$GITHUB_USER"/"$GITHUB_REPO" \
    --yes
}

release_name="GroovyArcade "
tag=stable
# $BUILD_TYPE should be set by the CI for daily automatic builds for testing repo
[[ -n $BUILD_TYPE ]] && tag="$BUILD_TYPE"
ghr=gh

# Make sure all env vars exist
export GITHUB_TOKEN=${GH_TOKEN:-$(cat ./GITHUB_TOKEN)}
[[ -z $GITHUB_USER ]] && (echo "GITHUB_USER is undefined, cancelling." ; exit 1 ;)
[[ -z $GITHUB_REPO ]] && (echo "GITHUB_REPO is undefined, cancelling." ; exit 1 ;)
# Allow a local build to release, the CI sets the GITHUB_TOKEN env var
if [[ -z $GH_TOKEN ]] ; then
  echo "GITHUB_TOKEN is undefined, cancelling."
  exit 1
fi

# Parse command line
while getopts "curtpdn:" option; do
  case "${option}" in
    c)
      create_release
      ;;
    r)
      upload_repo
      ;;
    u)
      upload_assets
      ;;
    d)
      delete_release
      ;;
    n)
      tag="$OPTARG"
      ;;
    t)
      # Testing release
      tag=testing
      delete_release
      create_release $tag
      upload_assets
      upload_repo
      ;;
    *)
      echo "ERROR: options can be -c -r -u -p -d or -t only" >&2
      exit 1
      ;;
  esac
done
