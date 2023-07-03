# When building a specific commit, git tags --describe doesn't return just the tag, and this breaks pkgver()
sed -i \
  -e "s+git describe --tags+git describe --tags --abbrev=0+" \
  /work/build/retroarch/PKGBUILD || exit 1