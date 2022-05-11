# Find the current pkgrel
pkgrel="$(egrep "^pkgrel=" /work/build/cairo/repos/extra-x86_64/PKGBUILD | cut -d '=' -f 2)"
# Increase it by one so we don't overlap with the real Arch pkg
pkgrel=$((pkgrel+2))
patch -Np1 -d /work/build/cairo < /work/package-nox11/cairo/patch/PKGBUILD.patch
[[ $? -gt 0 ]] && exit 1
sed -i \
  -e "s/pkgrel=.*/pkgrel=${pkgrel}/" \
  /work/build/cairo/repos/extra-x86_64/PKGBUILD || exit 1
( cd /work/build/cairo/repos/extra-x86_64 && makepkg -g >> PKGBUILD )
