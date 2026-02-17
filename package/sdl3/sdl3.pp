pkgrel++
source+="01-Add-custom_modelines.patch"
prepare() {
  ls -l
  cd SDL3-${pkgver}
  msg2 "Applying 01-Add-custom_modelines.patch"
  patch -Np1 -i "$srcdir"/01-Add-custom_modelines.patch
}
