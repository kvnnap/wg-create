# Dev container

FROM ubuntu:latest
LABEL authors="Kevin Napoli kvnnap@gmail.com"

ARG MYUSER=ubuntu
ARG HOME=/home/$MYUSER

RUN export DEBIAN_FRONTEND=noninteractive \
 && apt-get update \
 && apt-get -y --no-install-recommends install sudo wireguard-tools iptables qrencode git \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
#  && useradd -ms /bin/bash $MYUSER \
 && echo $MYUSER ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$MYUSER \
 && chmod 0440 /etc/sudoers.d/$MYUSER

USER $MYUSER
WORKDIR $HOME
