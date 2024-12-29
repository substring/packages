set -x
sed -i 's/^_kernelname=/&-15khz/' /work/build/broadcom-wl/PKGBUILD || exit 1
# This is a possible fix for dkms aut-zstd-ing the built module, which fails the build
#sed -i 's+module/\*\.ko+module/*.ko*+' /work/build/broadcom-wl/PKGBUILD || exit 1
