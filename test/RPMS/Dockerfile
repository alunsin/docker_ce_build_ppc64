#docker build -t als_test_centos8 --build-arg DISTRO_NAME=centos --build-arg DISTRO_VER=8 .
ARG DISTRO_NAME=fedora
ARG DISTRO_VER=32
ARG DOCKER_CE_VER=20.10.6-3
ARG CONTAINERD_VER=1.4.4-3.1

ARG GOLANG_VERSION=1.15.2

ARG LOCAL_WEB_SERVER="pwr-rt-bionic1:8080"

FROM ppc64le/$DISTRO_NAME:$DISTRO_VER

ARG LOCAL_WEB_SERVER
ARG GOLANG_VERSION
ARG DOCKER_CE_VER
ARG CONTAINERD_VER
ARG DISTRO_NAME
ARG DISTRO_VER

WORKDIR /workspace
RUN mkdir -p /workspace
ENV WORKSPACE=/workspace \
    TERM=xterm
ENV PATH /usr/local/go/bin:$PATH

RUN set -eux; yum -y install wget make gcc findutils procps-ng
RUN set -eux;wget ${LOCAL_WEB_SERVER}/docker-ce/bundles-ce-${DISTRO_NAME}-${DISTRO_VER}-ppc64le.tar.gz &&\
    tar -xvzf bundles-*.tar.gz --wildcards  --strip-components 6 '*/RPMS/*' &&\
    wget -r -nd -Appc64le.rpm ${LOCAL_WEB_SERVER}/containerd/${DISTRO_NAME}/${DISTRO_VER}/ppc64le/ &&\
    yum -y localinstall *.rpm

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
    wget http://${LOCAL_WEB_SERVER}/dockertest.tar.gz &&\
    tar -xvzf dockertest.tar.gz &&\
    rm dockertest.tar.gz

RUN set -eux; \
	url="https://storage.googleapis.com/golang/go${GOLANG_VERSION}.linux-ppc64le.tar.gz";\
    wget -O go.tgz "$url" --progress=dot:giga; \
    tar -C /usr/local -xzf go.tgz; \
    rm go.tgz; \
    go version;

COPY launch_test.sh /
RUN chmod a+x /launch_test.sh

VOLUME /var/lib/docker
EXPOSE 2375 2376

ENTRYPOINT ["dockerd-entrypoint.sh"]
