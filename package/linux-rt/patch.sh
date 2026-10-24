#echo "CONFIG_PREEMPT_RT=y" >> /work/build/linux-rt/config
sed -i 's/\$pkgbase-v${_/linux-rt-v${_/' /work/build/linux-rt/PKGBUILD
