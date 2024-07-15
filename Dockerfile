FROM ubuntu:18.04

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update \
    && apt-get --yes install \
        sudo \
        curl \
        wget \
        git \
        build-essential \
        debhelper \
        libssl-dev \
        linux-libc-dev \
        libpcre2-dev \
        pbuilder \
        expect \
        debconf \
        qemu-user-static
COPY ./debian_files /home/ubuntu/debian_files
COPY . /home/ubuntu/openarmor-hids
# `docker build` cannot handle `pbuilder create` because it uses `mount` which needs privilege
# RUN /home/ubuntu/openarmor-hids/contrib/debian-packages/generate_openarmor.sh -d
# RUN /home/ubuntu/openarmor-hids/contrib/debian-packages/generate_openarmor.sh -u
# RUN /home/ubuntu/openarmor-hids/contrib/debian-packages/generate_openarmor.sh -b

CMD ["/bin/sh"]
