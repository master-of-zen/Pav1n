FROM archlinux:base-devel

ENV MPLCONFIGDIR="/home/app_user/"

# Fix keyring
RUN rm -fr /etc/pacman.d/gnupg && \
    pacman-key --init && \
    pacman-key --populate archlinux

# Create user
RUN useradd app_user --system --shell /usr/bin/nologin --create-home && \
    echo "app_user ALL=(ALL) NOPASSWD: ALL" > "/etc/sudoers.d/allow_app_user"

# Speed up compile
RUN sed -i 's,^#MAKEFLAGS=.*,MAKEFLAGS="-j$(nproc)",g' /etc/makepkg.conf

USER app_user

# Recommended to update entire base image due to rolling release
RUN sudo pacman -Syu --noprogressbar --noconfirm

# Install requirements
RUN sudo pacman -S --noprogressbar --noconfirm opencv opencv-samples hdf5 qt5-base git cmake yasm doxygen python python-pip go 

# Install x265 and x264
RUN sudo pacman -S --noprogressbar --noconfirm x265 x264

# Install aomenc
RUN git clone https://aur.archlinux.org/aom-git.git /home/app_user/aom-git
WORKDIR /home/app_user/aom-git
RUN yes | makepkg -sri

# Install rav1e
RUN git clone https://aur.archlinux.org/rav1e-git.git /home/app_user/rav1e-git
WORKDIR /home/app_user/rav1e-git
RUN yes | makepkg -sri

# Install svt-av1
RUN git clone https://aur.archlinux.org/svt-av1-git.git /home/app_user/svt-av1-git
WORKDIR /home/app_user/svt-av1-git
RUN yes | makepkg -sri

# Install svt-vp9
RUN git clone https://aur.archlinux.org/svt-vp9-git.git /home/app_user/svt-vp9-git
WORKDIR /home/app_user/svt-vp9-git
RUN yes | makepkg -sri

# Install vpx
RUN git clone https://aur.archlinux.org/libvpx-full-git.git /home/app_user/libvpx-full-git
WORKDIR /home/app_user/libvpx-full-git
RUN yes | makepkg -sri

# Install VTM
RUN git clone https://vcgit.hhi.fraunhofer.de/jvet/VVCSoftware_VTM.git /home/app_user/VTM && \
    mkdir -p /home/app_user/VTM/build
WORKDIR /home/app_user/VTM/build
RUN cmake .. -DCMAKE_BUILD_TYPE=Release && \
    make -j$(nproc) && \
    sudo ln -s ../bin/EncoderAppStatic /usr/local/bin/vvc_encoder

# Install makemkv vapoursynth
RUN sudo pacman -S --noprogressbar --noconfirm mkvtoolnix-cli vapoursynth

# Install ffms2
RUN git clone https://aur.archlinux.org/ffms2-git.git /home/app_user/ffms2-git
WORKDIR /home/app_user/ffms2-git
RUN yes | makepkg -sri

# Install lsmash
RUN git clone https://aur.archlinux.org/vapoursynth-plugin-lsmashsource-git.git /home/app_user/vapoursynth-plugin-lsmashsource-git
WORKDIR /home/app_user/vapoursynth-plugin-lsmashsource-git
RUN yes | makepkg -sri

# Install av1an
COPY . /home/app_user/Av1an
WORKDIR /home/app_user/Av1an
RUN sudo python setup.py install

# Change permissions
RUN sudo chmod 777 -R /home/app_user

VOLUME ["/videos"]
WORKDIR /videos

ENTRYPOINT [ "/home/app_user/Av1an/av1an.py" ]
