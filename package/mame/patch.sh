# Get mame version
version=`grep 'pkgver=' /work/mame/repos/community-x86_64/PKGBUILD | cut -d "=" -f 2 | tr -d '.'`
patch -p1 -d /work < /work/package/mame/patch/PKGBUILD.patch
