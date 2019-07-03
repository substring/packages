# Get mame version
version=`grep 'pkgver=' /work/mame/trunk/PKGBUILD | cut -d "=" -f 2 | tr -d '.'`
cp /work/package/mame/patch/????_groovymame_????.diff /work/mame/trunk
patch -p1 -d /work < /work/package/mame/patch/PKGBUILD.patch
