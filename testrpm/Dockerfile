ARG DISTRIB=fedora
ARG VERSION=32

ARG GOLANG_VERSION=1.15.2

ARG LOCAL_WEB_SERVER="pwr-rt-bionic1.fyre.ibm.com:8080"

FROM golang:$GOLANG_VERSION AS builder
ARG TF_VERSION
ENV TF_VERSION ${TF_VERSION:-v0.12.29}

RUN go get rsc.io/goversion \
    && GO111MODULE=on go get github.com/hashicorp/terraform@$TF_VERSION

FROM ppc64le/$DISTRIB:$VERSION

WORKDIR /workspace
RUN mkdir -p /workspace
ENV WORKSPACE=/workspace \
    TERM=xterm
ENV PATH /usr/local/go/bin:$PATH

COPY --from=builder /go/bin/* /usr/local/bin/

# RUN apt-get update && apt-get install -y --no-install-recommends \
#     apt-transport-https \
#     ca-certificates \
#     curl \
#     gnupg2 \
#     software-properties-common \
#     lsb-release && \
#     rm -rf /var/lib/apt/lists/*

# RUN apt-get update && apt-get install -y --no-install-recommends \
#     build-essential \
#     ca-certificates \
#     curl \
#     file \
#     git \
#     make \
#     openssh-client \
#     pkg-config \
#     procps \
#     rsync \
#     unzip \
#     wget \
#     xz-utils \
#     zip \
#     zlib1g-dev
# ARG DISTRO
# ADD containerd.io_1.4.4-1_ppc64el.deb ./
# ADD docker-ce-cli_20.10.6~3-0~ubuntu-bionic_ppc64el.deb ./
# ADD docker-ce_20.10.6~3-0~ubuntu-bionic_ppc64el.deb ./
# RUN apt update && apt install -f && apt install -y jq curl iptables libdevmapper1.02.1 wget &&\
#     dpkg -i ./containerd.io_1.4.4-1_ppc64el.deb &&\
#     dpkg -i ./docker-ce-cli_20.10.6~3-0~ubuntu-bionic_ppc64el.deb &&\
#     dpkg -i ./docker-ce_20.10.6~3-0~ubuntu-bionic_ppc64el.deb &&\
#     dockerd -v /var/run/docker.sock:/var/run/docker.sock

RUN set -eux; dnf -y install wget make findutils
RUN set -eux; wget pwr-rt-bionic1.fyre.ibm.com:8080/docker-ce/fedora-32/RPMS/ppc64le/docker-ce-20.10.6-3.fc32.ppc64le.rpm &&\
wget pwr-rt-bionic1.fyre.ibm.com:8080/docker-ce/fedora-32/RPMS/ppc64le/docker-ce-cli-20.10.6-3.fc32.ppc64le.rpm &&\
wget pwr-rt-bionic1.fyre.ibm.com:8080/docker-ce/fedora-32/RPMS/ppc64le/docker-ce-rootless-extras-20.10.6-3.fc32.ppc64le.rpm &&\
wget pwr-rt-bionic1.fyre.ibm.com:8080/containerd/fedora/32/ppc64le/containerd.io-1.4.4-3.1.fc32.ppc64le.rpm &&\
dnf -y install *.rpm

##
#Docker in Docker inspired from
#  https://github.com/docker-library/docker/tree/master/20.10/dind
# set up subuid/subgid so that "--userns-remap=default" works out-of-the-box
##
RUN set -eux; \
	groupadd --system dockremap; \
	adduser --system -g dockremap dockremap; \
	echo 'dockremap:165536:65536' >> /etc/subuid; \
	echo 'dockremap:165536:65536' >> /etc/subgid

# https://github.com/docker/docker/tree/master/hack/dind
ENV DIND_COMMIT ed89041433a031cafc0a0f19cfe573c31688d377

RUN set -eux; \
	wget -O /usr/local/bin/dind "https://raw.githubusercontent.com/docker/docker/${DIND_COMMIT}/hack/dind"; \
	chmod +x /usr/local/bin/dind;

RUN set -eux; \
    wget https://raw.githubusercontent.com/docker-library/docker/094faa88f437cafef7aeb0cc36e75b59046cc4b9/20.10/dind/dockerd-entrypoint.sh;\
    chmod +x dockerd-entrypoint.sh;\
    mv dockerd-entrypoint.sh /usr/local/bin


RUN set -eux; \
OUTDIR=${WORKSPACE}/test/src/github.ibm.com/powercloud ; \
mkdir -p $OUTDIR && cd $OUTDIR &&\
wget http://pwr-rt-bionic1.fyre.ibm.com:8080/dockertest.tar.gz &&\
tar -xvzf dockertest.tar.gz &&\
rm dockertest.tar.gz

VOLUME /var/lib/docker
EXPOSE 2375 2376

ENTRYPOINT ["dockerd-entrypoint.sh"]
