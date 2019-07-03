patch -p2 -d /work/linux < /work/package/linux/patch/PKGBUILD.patch || exit 1
sed -i \
-e '/_srcname=archlinux-linux/a _15kpatchcommitid=cb50d2cf199e333b83260f1be5608e3ab19c4f29' \
-re 's/pkgbase=linux[[:space:]]+/pkgbase=linux-15khz /' \
/work/linux/trunk/PKGBUILD || exit 1

# We need to patch the config. So, find its hash first, patch, recompute hash, then patch PKGBUILD
# Keep the code commented, if we ever need to patch config later
#oldhash=$(sha256sum /work/linux/trunk/config | cut -d ' ' -f1)
#sed -i "/CONFIG_DRM_KMS_HELPER=/s/m$/y/" /work/linux/trunk/config || exit 1
#newhash=$(sha256sum /work/linux/trunk/config | cut -d ' ' -f1)
#sed -i "s/$oldhash/$newhash/" /work/linux/trunk/PKGBUILD || exit 1

