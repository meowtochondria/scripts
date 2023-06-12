FROM ubuntu:22.04 AS build-stage

# Official docs - https://github.com/FreeRDP/FreeRDP/wiki/Compilation#install-the-suggested-base-dependencies
# Debian source - https://salsa.debian.org/debian-remote-team/freerdp2/-/tree/master/debian
# Build flags of current build - freerdp-shadow-cli -sec-rdp  /buildconfig
# docker run -it --entrypoint /bin/bash ubuntu:jammy

ENV DEBIAN_FRONTEND noninteractive

# Update the system.
RUN apt-get update
RUN apt-get upgrade -y

# Following is needed to use add-apt-repository command
RUN apt-get install -y software-properties-common

# Add xtradeb repo to get latest version of openh264 that contains fixes for https://github.com/cisco/openh264/issues/3476
RUN add-apt-repository --yes ppa:xtradeb/apps

RUN apt-get install -y ninja-build autotools-dev build-essential cdbs cmake debhelper docbook-xsl doxygen dpkg-dev git-core libasound2-dev libavcodec-dev libavutil-dev libcairo2-dev libcunit1-dev libcups2-dev libdbus-glib-1-dev libdirectfb-dev libfaac-dev libfaad-dev libfuse-dev libgsm1-dev libgstreamer-plugins-base1.0-dev libgstreamer1.0-dev libjpeg-dev libkrb5-dev libopenh264-dev libpcsclite-dev libpulse-dev libssl-dev libswresample-dev libswscale-dev libudev-dev libusb-1.0-0-dev libwayland-dev libx11-dev libxcursor-dev libxdamage-dev libxext-dev libxfixes-dev libxi-dev libxinerama-dev libxkbcommon-dev libxkbfile-dev libxml2-dev libxrandr-dev libxrender-dev libxtst-dev libxv-dev pkg-config uuid-dev xmlto xmlto xsltproc

RUN git clone https://github.com/FreeRDP/freerdp.git
# RUN cd freerdp && git checkout tags/2.10.0
RUN mkdir freerdp/build

# RUN cmake -Bfreerdp/build -Hfreerdp -GNinja \
#     -DCMAKE_BUILD_TYPE=RelWithDebInfo \
#     -DWITH_DEBUG_ALL=OFF \
#     -DBUILD_TESTING=OFF \
#     -DWITH_CHANNELS=ON \
#     -DBUILTIN_CHANNELS=ON \
#     -DWITH_SERVER=ON \
#     -DWITH_PROXY=OFF \
#     -DWITH_CLIENT_INTERFACE=OFF \
#     -DWITH_PULSE=ON \
#     -DWITH_ICU=ON \
#     -DWITH_CUPS=ON \
#     -DWITH_PCSC=ON \
#     -DWITH_JPEG=ON \
#     -DWITH_ALSA=ON \
#     -DWITH_LIBSYSTEMD=ON \
#     -DWITH_WAYLAND=OFF \
#     -DWITH_GSM=ON \
#     -DWITH_SWSCALE=ON \
#     -DWITH_DSP_FFMPEG=OFF \
#     -DWITH_OPENH264=ON \
#     -DWITH_GFX_H264=ON \
#     -DWITH_OPENSSL=ON \
#     -DWITH_OSS=ON \
#     -DWITH_PAM=ON \
#     -DWITH_SSE2=ON \
#     -DWITH_WINPR_TOOLS=ON \
#     -DWITH_X11=ON \
#     -DWITH_XCURSOR=ON \
#     -DWITH_XDAMAGE=ON \
#     -DWITH_XEXT=ON \
#     -DWITH_XFIXES=ON \
#     -DWITH_XI=ON \
#     -DWITH_XINERAMA=ON \
#     -DWITH_XKBFILE=ON \
#     -DWITH_XRANDR=ON \
#     -DWITH_XRENDER=ON \
#     -DWITH_XSHM=ON \
#     -DWITH_XTEST=ON \
#     -DWITH_XV=ON \
#     -DWITH_ZLIB=ON
RUN cmake -Bfreerdp/build -Hfreerdp -GNinja \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DWITH_DEBUG_ALL=OFF \
    -DBUILD_TESTING=OFF \
    -DWITH_CHANNELS=ON \
    -DBUILTIN_CHANNELS=ON \
    -DWITH_SERVER=ON \
    -DWITH_SERVER_CHANNELS=ON \
    -DWITH_SERVER_INTERFACE=ON \
    -DWITH_SHADOW=ON \
    -DWITH_PROXY=OFF \
    -DWITH_CLIENT_INTERFACE=OFF \
    -DWITH_PULSE=ON \
    -DWITH_ICU=ON \
    -DWITH_CUPS=ON \
    -DWITH_PCSC=ON \
    -DWITH_JPEG=ON \
    -DWITH_ALSA=ON \
    -DWITH_LIBSYSTEMD=ON \
    -DWITH_WAYLAND=OFF \
    -DWITH_GSM=ON \
    -DWITH_SWSCALE=ON \
    -DWITH_DSP_FFMPEG=ON \
    -DWITH_FFMPEG=ON \
    -DWITH_OPENH264=ON \
    -DWITH_GFX_H264=ON \
    -DWITH_OPENSSL=ON \
    -DWITH_OSS=ON \
    -DWITH_PAM=ON \
    -DWITH_SSE2=ON \
    -DWITH_WINPR_TOOLS=ON \
    -DWITH_X11=ON \
    -DWITH_XCURSOR=ON \
    -DWITH_XDAMAGE=ON \
    -DWITH_XEXT=ON \
    -DWITH_XFIXES=ON \
    -DWITH_XI=ON \
    -DWITH_XINERAMA=ON \
    -DWITH_XKBFILE=ON \
    -DWITH_XRANDR=ON \
    -DWITH_XRENDER=ON \
    -DWITH_XSHM=ON \
    -DWITH_XTEST=ON \
    -DWITH_XV=ON \
    -DWITH_ZLIB=ON \
    -DWITH_VAAPI=ON \
    -DWITH_FAAC=ON \
    -DWITH_FAAD2=ON \
    -DWITH_INTERNAL_MD4=ON \
    -DWITH_INTERNAL_MD5=ON

RUN cmake --build freerdp/build --target package

FROM scratch AS export-stage
COPY --from=build-stage /freerdp/build/freerdp*.sh /
COPY --from=build-stage /freerdp/build/freerdp*.tar.gz /

# Executing this script using Docker
# sudo DOCKER_BUILDKIT=1  docker build --pull --network=host --output type=local,dest=$PWD --file Dockerfile $PWD
