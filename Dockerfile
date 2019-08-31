FROM archlinux/base:latest

RUN pacman-key --init && \
    pacman-key --populate archlinux

RUN pacman -Syu --noconfirm --needed \
  mkinitcpio \
  asp \
  base-devel \
  ccache \
  haveged \
  namcap \
  wget \
  dos2unix \
  mercurial

RUN curl -L https://github.com/aktau/github-release/releases/download/v0.7.2/linux-amd64-github-release.tar.bz2 | tar -jx --strip-components 3 -C /usr/local/bin bin/linux/amd64/github-release

RUN useradd -ms /bin/bash -d /work build

# Don't build on a single thread
RUN sed -i 's/#MAKEFLAGS="-j2"/MAKEFLAGS="-j'$(nproc)'"/' /etc/makepkg.conf

# Activate ccache
RUN sed -ri 's/^BUILDENV=(.*)\!ccache(.*)/BUILDENV=\1ccache\2/' /etc/makepkg.conf

WORKDIR /work

RUN echo 'build ALL=(root) NOPASSWD:ALL' > /etc/sudoers.d/user && \
    chmod 0440 /etc/sudoers.d/user

COPY package /work/package
COPY buildPackages.sh /work
COPY include.sh /work
COPY packages_arch.lst /work
COPY packages_aur.lst /work
COPY packages_groovy.lst /work
COPY groovy-ux-repo.conf /etc/pacman.d
COPY release.sh /work
COPY settings /work

RUN grep -q groovy-ux-repo.conf /etc/pacman.conf || echo -e "\nInclude = /etc/pacman.d/groovy-ux-repo.conf" >> /etc/pacman.conf
RUN sed -i 's/#MAKEFLAGS="-j2"/MAKEFLAGS="-j'$(nproc)'"/' /etc/makepkg.conf
RUN sed -ri 's/^BUILDENV=(.*)\!ccache(.*)/BUILDENV=\1ccache\2/' /etc/makepkg.conf
RUN CCACHE_DIR=/work/cache/ccache ccache -s


USER build

RUN mkdir -p /work /work/cache/ccache

#CMD sudo pacman -Syu --noconfirm && /work/buildPackages.sh
#CMD sudo pacman -Syu --noconfirm && MAKEPKG_OPTS="--nobuild --nodeps" /bin/bash -x /work/buildPackages.sh -g
#CMD sudo pacman -Syu --noconfirm && MAKEPKG_OPTS="--nobuild --nodeps" /bin/bash -x /work/buildPackages.sh linux-rt
#CMD sudo pacman -Syu --noconfirm && /work/buildPackages.sh -g
#CMD sudo pacman -Syu --noconfirm && MAKEPKG_OPTS="--packagelist" /work/buildPackages.sh
#CMD sudo pacman -Syu --noconfirm && /work/buildPackages.sh linux-rt
#CMD sudo pacman -Syu --noconfirm && /bin/bash -x /work/buildPackages.sh -s "aur/gamemode"
#CMD sudo pacman -Syu --noconfirm && /bin/bash -x /work/buildPackages.sh -s "groovy/switchres"
CMD sudo pacman -Syu --noconfirm && /bin/bash -x /work/buildPackages.sh -s "kitty"
