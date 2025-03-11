pkgrel++
source+="force_modes_refresh.patch"
source+="sdl_restore_crtc_at_DestroyWindow.patch"
prepare() {
  cd SDL2-${pkgver}
  msg2 "Applying pipewire.patch"
  patch -p1 < "$srcdir/pipewire.patch"
  msg2 "Applying force_modes_refresh.patch"
  patch -Np1 -i "$srcdir"/force_modes_refresh.patch
  msg2 "Applying sdl_restore_crtc_at_DestroyWindow.patch"
  patch -Np1 -i "$srcdir"/sdl_restore_crtc_at_DestroyWindow.patch
}
