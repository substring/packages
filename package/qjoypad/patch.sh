patch -p1 -d /work/qjoypad < /work/package/qjoypad/patch/PKGBUILD.patch || exit 1
cp /work/package/qjoypad/patch/001-qt5.13-compatibility.patch /work/qjoypad
