#!/bin/bash
RELEASE=${RELEASE:-dev}

mkdir -p work/output
mkdir -p work/cache/ccache
chmod -R 777 work
echo "+++++++++++++++++++++++++++++"
echo "+++ Building docker image +++"
echo "+++++++++++++++++++++++++++++"
docker build -f Dockerfile -t "groovy-ux-${RELEASE}" . &&
echo "+++++++++++++++++++++++++++++"
echo "+++ Running container     +++"
echo "+++++++++++++++++++++++++++++"
docker run --tty --name "groovy-ux-${RELEASE}" --rm -v "$(pwd)/work/output":/work/output -v "$(pwd)/work/cache":/work/cache "groovy-ux-${RELEASE}"
