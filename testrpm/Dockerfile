ARG DISTRIB=fedora
ARG VERSION=32

ARG GOLANG_VERSION=1.15.2

ARG LOCAL_WEB_SERVER="pwr-rt-bionic1.fyre.ibm.com:8080"

# FROM golang:$GOLANG_VERSION AS builder
# ARG TF_VERSION
# ENV TF_VERSION ${TF_VERSION:-v0.12.29}

# RUN go get rsc.io/goversion \
#     && GO111MODULE=on go get github.com/hashicorp/terraform@$TF_VERSION

FROM ppc64le/$DISTRIB:$VERSION

ENV LOCAL_WEB_SERVER ${LOCAL_WEB_SERVER}

WORKDIR /workspace
RUN mkdir -p /workspace
ENV WORKSPACE=/workspace \
    TERM=xterm
ENV PATH /usr/local/go/bin:$PATH

RUN set -eux; dnf -y install wget make findutils
RUN set -eux; wget $LOCAL_WEB_SERVER/docker-ce/fedora-32/RPMS/ppc64le/docker-ce-20.10.6-3.fc32.ppc64le.rpm &&\
wget $LOCAL_WEB_SERVER/docker-ce/fedora-32/RPMS/ppc64le/docker-ce-cli-20.10.6-3.fc32.ppc64le.rpm &&\
wget $LOCAL_WEB_SERVER/docker-ce/fedora-32/RPMS/ppc64le/docker-ce-rootless-extras-20.10.6-3.fc32.ppc64le.rpm &&\
wget $LOCAL_WEB_SERVER/containerd/fedora/32/ppc64le/containerd.io-1.4.4-3.1.fc32.ppc64le.rpm &&\
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
wget http://$LOCAL_WEB_SERVER/dockertest.tar.gz &&\
tar -xvzf dockertest.tar.gz &&\
rm dockertest.tar.gz

RUN set -eux; \
	url="https://storage.googleapis.com/golang/go${GOLANG_VERSION}.linux-ppc64le.tar.gz";\
    wget -O go.tgz "$url" --progress=dot:giga; \
    tar -C /usr/local -xzf go.tgz; \
    rm go.tgz; \
    go version; \
    wget -O ibm_cloud.tgz "$ibm_cloud_url" --progress=dot:giga; \
    tar -xf ibm_cloud.tgz; \
    rm ibm_cloud.tgz;


VOLUME /var/lib/docker
EXPOSE 2375 2376

ENTRYPOINT ["dockerd-entrypoint.sh"]
