FROM debian:jessie

RUN echo deb http://httpredir.debian.org/debian jessie-backports main >> /etc/apt/sources.list
RUN echo deb http://www.deb-multimedia.org jessie main non-free >> /etc/apt/sources.list
RUN echo deb http://software.ligo.org/lscsoft/debian jessie contrib >> /etc/apt/sources.list
RUN apt-get update
RUN apt-get install -y --allow-unauthenticated deb-multimedia-keyring
RUN apt-get install -y --allow-unauthenticated lscsoft-archive-keyring

RUN apt-get update
RUN apt-get install -y git
RUN apt-get install -y make pkg-config octave liboctave-dev swig3.0 texinfo libgsl-dev
RUN apt-get install -y lal-octave lalxml-octave lalpulsar-octave lalapps
RUN apt-get install -y ffmpeg libcfitsio-dev

COPY . /tmp/octapps
WORKDIR /tmp/octapps

RUN make
RUN echo source /octapps/octapps-user-env.sh >> /root/.bashrc
RUN make -j2 check NOSKIP=1
RUN make -j2 html
