sed -i 's/\-j6//' /work/build/iemulationstation-de/PKGBUILD
sed -i 's/cmake/cmake -DDEINIT_ON_LAUNCH=on/' /work/build/iemulationstation-de/PKGBUILD
