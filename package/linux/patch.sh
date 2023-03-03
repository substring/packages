patch -Np2 -d /work/build/linux < /work/package/linux/patch/PKGBUILD.patch
[[ $? -gt 0 ]] && exit 1
sed -i "s/# CONFIG_EFI_HANDOVER_PROTOCOL is not set/CONFIG_EFI_HANDOVER_PROTOCOL=y/" /work/build/linux/repos/core-x86_64/config || exit 1
sed -i \
-e '/pkgver=.*/a _kernelversion="$(echo ${pkgver} | cut -d '.' -f 1,2)"' \
-re 's/pkgbase=linux.*/pkgbase=linux-15khz/' \
/work/build/linux/repos/core-x86_64/PKGBUILD || exit 1
( cd /work/build/linux/repos/core-x86_64 && makepkg -g >> PKGBUILD )

# Find the current pkgrel
#pkgrel="$(egrep "^pkgrel=" /work/build/linux/repos/core-x86_64/PKGBUILD | cut -d '=' -f 2)"
# Increase it by one so we don't overlap with the real Arch pkg
#pkgrel=$((pkgrel+1))
#sed -i \
  #-e "s/pkgrel=.*/pkgrel=${pkgrel}/" \
  #/work/build/linux/repos/core-x86_64/PKGBUILD || exit 1

# Simply build DRM
#sed -i 's+make bzImage modules htmldocs+make -C . M=drivers/gpu/drm+g' /work/build/linux/repos/core-x86_64/PKGBUILD || exit 1
# We need to patch the config. So, find its hash first, patch, recompute hash, then patch PKGBUILD
# Keep the code commented, if we ever need to patch config later
#oldhash=$(sha256sum /work/build/linux/repos/core-x86_64/config | cut -d ' ' -f1)
#sed -i "/CONFIG_LOCALVERSION_AUTO=/s/m$/n/" /work/build/linux/repos/core-x86_64/config || exit 1
#newhash=$(sha256sum /work/build/linux/repos/core-x86_64/config | cut -d ' ' -f1)
#sed -i "s/$oldhash/$newhash/" /work/build/linux/repos/core-x86_64/PKGBUILD || exit 1
