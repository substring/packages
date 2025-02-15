FROM archlinux:base-devel

RUN pacman-key --init && \
    pacman-key --populate archlinux

RUN pacman -Syu --noconfirm --needed \
  base-devel \
  devtools \
  mkinitcpio \
  haveged \
  namcap \
  wget \
  dos2unix \
  pacman-contrib \
  curl \
  github-cli \
  yq

RUN useradd -ms /bin/bash -d /work build

# Disable the debug package
RUN sed -i 's/ debug/ !debug/' /etc/makepkg.conf
# Enable debug
RUN sed -i 's/ !debug/ debug/' /etc/makepkg.conf
RUN sed -i 's/strip /!strip /' /etc/makepkg.conf
# Don't build on a single thread
RUN sed -i 's/#MAKEFLAGS="-j2"/MAKEFLAGS="-j'$(nproc)'"/' /etc/makepkg.conf
# Change the user agent, some sites prevent curl from downloadin (mameinfo.dat ...)
RUN sed -i 's+curl +curl -A Mozilla +' /etc/makepkg.conf
# Change the arch
#RUN sed -i 's+march=x86-64+march=x86-64-v3+' /etc/makepkg.conf
# Change the optimisation level
#RUN sed -i 's+\-O2+-O3+' /etc/makepkg.conf
# Set cland as the defafult compiler
#RUN echo -e "export CC=clang\nexportCXX=clang++\nexportLD=lld" >>/etc/makepkg.conf

WORKDIR /work

RUN echo 'build ALL=(root) NOPASSWD:ALL' > /etc/sudoers.d/user && \
    chmod 0440 /etc/sudoers.d/user

COPY package /work/package
COPY package-nox11 /work/package-nox11
COPY buildPackages.sh /work
COPY pkgbuild-patcher.sh /work
COPY include.sh /work
COPY packages_arch.lst /work
COPY packages_aur.lst /work
COPY packages_groovy.lst /work
COPY packages_dkms.lst /work
COPY groovy-ux-repo.conf /etc/pacman.d
COPY release.sh /work
COPY settings /work

RUN grep -q groovy-ux-repo.conf /etc/pacman.conf || echo -e "\nInclude = /etc/pacman.d/groovy-ux-repo.conf" >> /etc/pacman.conf

#Check if the testing repo exists. If not disable it
RUN [[ $(curl -L -o /dev/null -s -w "%{http_code}\n" https://github.com/substring/packages/releases/download/testing/groovyarcade-testing.db) == 200 ]] || sed -Ei '1,3s/^(.*)/#\1/g' /etc/pacman.d/groovy-ux-repo.conf
RUN cat /etc/pacman.d/groovy-ux-repo.conf

RUN pacman -Syu --noconfirm

USER build

RUN mkdir -p /work /work/output

ENTRYPOINT ["/work/buildPackages.sh"]
CMD ["-s","groovy/switchres"]
#CMD ["-s","aur/gamemode"]
#CMD ["-s", "kitty"]
#CMD ["-g"]
#CMD ["linux"]
