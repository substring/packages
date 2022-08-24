#!/bin/bash
RELEASE=${RELEASE:-dev}
env_vars_file=env_vars
mkdir -p work/output
chmod -R 777 work

echo "+++++++++++++++++++++++++++++"
echo "+++     ENV vars used     +++"
echo "+++++++++++++++++++++++++++++"
grep -v "^#" "$env_vars_file"
echo

echo "+++++++++++++++++++++++++++++"
echo "+++ Building docker image +++"
echo "+++++++++++++++++++++++++++++"
docker build -f Dockerfile -t "groovy-ux-${RELEASE}" . &&

# The env_var file can use MAKEPKG_OPTS and DP?T_DOWNLOAD_JUST_BUILD vars
# easier to have them in a file than set them on command like each time
# the env_vars can also be used to push other env vars, like the ones for ES
echo "+++++++++++++++++++++++++++++"
echo "+++ Running container     +++"
echo "+++++++++++++++++++++++++++++"
docker run \
  --tty \
  --name "groovy-ux-${RELEASE}-$$" \
  --rm \
  --volume "$(pwd)/work/output":/work/output \
  --volume "$(pwd)/work/cache":/work/cache \
  --env-file="$env_vars_file" \
  "groovy-ux-${RELEASE}" "$@"
#  --env MAKEPKG_OPTS \
#  --env DONT_DOWNLOAD_JUST_BUILD \
