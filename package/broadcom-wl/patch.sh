set -x
sed -i 's/^_kernelname=/&-15khz/' /work/build/broadcom-wl/PKGBUILD || exit 1
