sed -i 's/\-j6//' /work/build/emulationstation-de/PKGBUILD
sed -i 's/cmake/cmake -DDEINIT_ON_LAUNCH=on/' /work/build/emulationstation-de/PKGBUILD
