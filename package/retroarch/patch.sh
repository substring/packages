# Find the current pkgrel
pkgrel="$(egrep "^pkgrel=" /work/build/retroarch/PKGBUILD | cut -d '=' -f 2)"
# Increase it by one so we don't overlap with the real Arch pkg
pkgrel=$((pkgrel+2))
patch -tNp3 -d /work/build/retroarch < /work/package/retroarch/patch/PKGBUILD.patch
[[ $? -gt 0 ]] && exit 1
sed -i \
  -e "s/pkgrel=.*/pkgrel=${pkgrel}/" \
  -e "s/pkgver()/ppkkggvveerr()/" \
  /work/build/retroarch/PKGBUILD || exit 1
( cd /work/build/retroarch/ && makepkg -g >> PKGBUILD )
