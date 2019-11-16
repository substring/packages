patch -p2 -d /work/linux < /work/package/linux/patch/PKGBUILD.patch || exit 1
sed -i \
-e '/_srcname=archlinux-linux/a _kernelversion="$(echo ${pkgver} | cut -d '.' -f 1,2)"' \
-re 's/pkgbase=linux/pkgbase=linux-15khz/' \
/work/linux/repos/core-x86_64/PKGBUILD || exit 1
( cd /work/linux/repos/core-x86_64 && makepkg -g >> PKGBUILD )

# We need to patch the config. So, find its hash first, patch, recompute hash, then patch PKGBUILD
# Keep the code commented, if we ever need to patch config later
#oldhash=$(sha256sum /work/linux/repos/core-x86_64/config | cut -d ' ' -f1)
#sed -i "/CONFIG_LOCALVERSION_AUTO=/s/m$/n/" /work/linux/repos/core-x86_64/config || exit 1
#newhash=$(sha256sum /work/linux/repos/core-x86_64/config | cut -d ' ' -f1)
#sed -i "s/$oldhash/$newhash/" /work/linux/repos/core-x86_64/PKGBUILD || exit 1

