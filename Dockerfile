FROM debian:jessie

RUN echo deb http://httpredir.debian.org/debian jessie-backports main >> /etc/apt/sources.list
RUN echo deb http://www.deb-multimedia.org jessie main non-free >> /etc/apt/sources.list
RUN echo deb http://software.ligo.org/lscsoft/debian jessie contrib >> /etc/apt/sources.list
RUN apt-get update
RUN apt-get install -y --allow-unauthenticated deb-multimedia-keyring
RUN apt-get install -y --allow-unauthenticated lscsoft-archive-keyring

RUN apt-get update
RUN apt-get install -y git lal-octave lalxml-octave lalpulsar-octave lalapps
RUN apt-get install -y epstool ffmpeg ghostscript gnuplot-nox libcfitsio-dev libgsl-dev liboctave-dev make pkg-config pstoedit swig3.0 texinfo transfig

COPY . /tmp/octapps
WORKDIR /tmp/octapps

RUN make
RUN echo ". /tmp/octapps/octapps-user-env.sh" >> /root/.bashrc
RUN . /root/.bashrc
RUN make -j2 check NOSKIP=1
RUN make -j2 html
