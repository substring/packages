FROM archlinux:latest

RUN export patched_glibc=glibc-linux4-2.33-4-x86_64.pkg.tar.zst && \
  curl -LO https://repo.archlinuxcn.org/x86_64/$patched_glibc && \
  bsdtar -C / -xvf $patched_glibc
RUN pacman-key --init && \
    pacman-key --populate archlinux

RUN pacman -Syu --noconfirm --needed \
  base-devel \
  devtools \
  mkinitcpio \
  asp \
  haveged \
  namcap \
  wget \
  dos2unix \
  pacman-contrib

RUN curl -L https://github.com/github-release/github-release/releases/download/v0.10.0/linux-amd64-github-release.bz2 | bzip2 -d > /usr/local/bin/github-release && chmod +x /usr/local/bin/github-release

RUN useradd -ms /bin/bash -d /work build

# Don't build on a single thread
RUN sed -i 's/#MAKEFLAGS="-j2"/MAKEFLAGS="-j'$(nproc)'"/' /etc/makepkg.conf
# Change the user agent, some sites prevent curl from downloadin (mameinfo.dat ...)
RUN sed -i 's+curl +curl -A Mozilla +' /etc/makepkg.conf

WORKDIR /work

RUN echo 'build ALL=(root) NOPASSWD:ALL' > /etc/sudoers.d/user && \
    chmod 0440 /etc/sudoers.d/user

COPY package /work/package
COPY buildPackages.sh /work
COPY include.sh /work
COPY packages_arch.lst /work
COPY packages_aur.lst /work
COPY packages_groovy.lst /work
COPY packages_dkms.lst /work
COPY groovy-ux-repo.conf /etc/pacman.d
COPY release.sh /work
COPY settings /work

RUN grep -q groovy-ux-repo.conf /etc/pacman.conf || echo -e "\nInclude = /etc/pacman.d/groovy-ux-repo.conf" >> /etc/pacman.conf

RUN pacman -Syu --noconfirm

USER build

RUN mkdir -p /work /work/output

ENTRYPOINT ["/work/buildPackages.sh"]
CMD ["-s","groovy/switchres"]
#CMD ["-s","aur/gamemode"]
#CMD ["-s", "kitty"]
#CMD ["-g"]
#CMD ["linux"]
