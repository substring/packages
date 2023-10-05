pkgbase=linux-lts-15khz
_kernelversion="$(echo ${pkgver} | cut -d '.' -f 1,2)"
source+=https://raw.githubusercontent.com/D0023R/linux_kernel_15khz/master/linux-${_kernelversion}/01_linux_15khz.patch
source+=https://raw.githubusercontent.com/D0023R/linux_kernel_15khz/master/linux-${_kernelversion}/02_linux_15khz_interlaced_mode_fix.patch
source+=https://raw.githubusercontent.com/D0023R/linux_kernel_15khz/master/linux-${_kernelversion}/03_linux_15khz_dcn1_dcn2_interlaced_mode_fix.patch
source+=https://raw.githubusercontent.com/D0023R/linux_kernel_15khz/master/linux-${_kernelversion}/04_linux_15khz_amdgpu_pll_fix.patch
source+=https://raw.githubusercontent.com/D0023R/linux_kernel_15khz/master/linux-${_kernelversion}/05_linux_switchres_kms_drm_modesetting.patch
