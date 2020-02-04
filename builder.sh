#!/bin/bash
RELEASE=${RELEASE:-dev}

mkdir -p work/output
chmod -R 777 work
echo "+++++++++++++++++++++++++++++"
echo "+++ Building docker image +++"
echo "+++++++++++++++++++++++++++++"
docker build -f Dockerfile -t "groovy-ux-${RELEASE}" . &&
echo "+++++++++++++++++++++++++++++"
echo "+++ Running container     +++"
echo "+++++++++++++++++++++++++++++"
docker run \
  --tty \
  --name "groovy-ux-${RELEASE}" \
  --rm \
  --volume "$(pwd)/work/output":/work/output \
  --volume "$(pwd)/work/cache":/work/cache \
  --env MAKEPKG_OPTS \
  --env DONT_DOWNLOAD_JUST_BUILD \
  "groovy-ux-${RELEASE}" "$@"
