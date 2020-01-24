patch -Np2 -d /work/build/linux < /work/package/linux/patch/PKGBUILD.patch
[[ $? -gt 1 ]] && exit 1
sed -i \
-e '/_srcname=archlinux-linux/a _kernelversion="$(echo ${pkgver} | cut -d '.' -f 1,2)"' \
-re 's/pkgbase=linux.*/pkgbase=linux-15khz/' \
-re 's/pkgrel=.*/pkgrel=10/' \
/work/build/linux/repos/core-x86_64/PKGBUILD || exit 1
( cd /work/build/linux/repos/core-x86_64 && makepkg -g >> PKGBUILD )

# Simply build DRM
#sed -i 's+make bzImage modules htmldocs+make -C . M=drivers/gpu/drm+g' /work/build/linux/repos/core-x86_64/PKGBUILD || exit 1
# We need to patch the config. So, find its hash first, patch, recompute hash, then patch PKGBUILD
# Keep the code commented, if we ever need to patch config later
#oldhash=$(sha256sum /work/build/linux/repos/core-x86_64/config | cut -d ' ' -f1)
#sed -i "/CONFIG_LOCALVERSION_AUTO=/s/m$/n/" /work/build/linux/repos/core-x86_64/config || exit 1
#newhash=$(sha256sum /work/build/linux/repos/core-x86_64/config | cut -d ' ' -f1)
#sed -i "s/$oldhash/$newhash/" /work/build/linux/repos/core-x86_64/PKGBUILD || exit 1

