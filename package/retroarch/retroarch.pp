pkgrel+++
source+="fix_drm_buffer_overflow.patch"
prepare() {
  cd RetroArch
  patch -Np1 -i ../retroarch-config.patch
  patch -Np1 -i ../fix_drm_buffer_overflow.patch
}

