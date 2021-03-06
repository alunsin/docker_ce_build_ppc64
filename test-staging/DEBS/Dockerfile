#docker build -t als_test_centos8 --build-arg DISTRO_NAME=centos --build-arg DISTRO_VER=8 .
#docker build --build-arg IMAGE=$DISTRIB:$DISTROS --build-arg DISTRO=$DISTROS --build-arg DISTRIB=$DISTRIB . >> outputtemps.txt
#DISTRO_NAME=ubuntu; DISTRO_VER=bionic; docker build -t als_test_${DISTRO_VER}_${DISTRO_NAME} --build-arg DISTRO_NAME=$DISTRO_NAME --build-arg DISTRO_VER=$DISTRO_VER > build_${DISTRO_VER}_${DISTRO_NAME}.log .2>&1
#docker run -d -v ~/docker-ce:/docker-ce -v ~/.docker:/root/.docker --privileged  --name als_run_${DISTRO_VER}_${DISTRO_NAME} als_test_${DISTRO_VER}_${DISTRO_NAME}

ARG DISTRO_NAME=debian
ARG DISTRO_VER=buster

ARG GOLANG_VERSION=1.15.2

ARG LOCAL_WEB_SERVER="pwr-rt-bionic1:8080"

FROM ppc64le/$DISTRO_NAME:$DISTRO_VER

ARG LOCAL_WEB_SERVER
ARG GOLANG_VERSION
ARG DISTRO_NAME
ARG DISTRO_VER

WORKDIR /workspace
RUN mkdir -p /workspace
ENV WORKSPACE=/workspace \
    TERM=xterm
ENV PATH /usr/local/go/bin:$PATH


RUN if [ -f /bin/rpm  ] ; \
    then\
     echo rpm ; \
     set -eux; yum -y install wget make gcc findutils;\
    else \
        echo deb;\
        apt-get update && apt-get install -y --no-install-recommends \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg2 \
        wget \
        software-properties-common \
        lsb-release\
        ##### Install go tests deps
        make\
        gcc\
        libc-dev\
        procps\
        ##### Install docker-ce deps
        iptables libdevmapper1.02.1 && \
        rm -rf /var/lib/apt/lists/* ;\
    fi

#Install from Docekr-ce staging
RUN set -eux; curl -fsSL https://download-stage.docker.com/linux/${DISTRO_NAME}/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg &&\
    echo "deb [arch=ppc64el signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download-stage.docker.com/linux/${DISTRO_NAME} ${DISTRO_VER} stable"\
    | tee /etc/apt/sources.list.d/docker.list > /dev/null  &&\
    apt-get update && apt-get -y install docker-ce docker-ce-cli containerd.io

##
#Docker in Docker inspired from
#  https://github.com/docker-library/docker/tree/master/20.10/dind
# set up subuid/subgid so that "--userns-remap=default" works out-of-the-box
##
RUN set -eux; \
        addgroup --system dockremap; \
        adduser --system --ingroup dockremap dockremap; \
        echo 'dockremap:165536:65536' >> /etc/subuid; \
        echo 'dockremap:165536:65536' >> /etc/subgid

# https://github.com/docker/docker/tree/master/hack/dind
ENV DIND_COMMIT ed89041433a031cafc0a0f19cfe573c31688d377

RUN set -eux; \
        wget -O /usr/local/bin/dind "https://raw.githubusercontent.com/docker/docker/${DIND_COMMIT}/hack/dind"; \
        chmod +x /usr/local/bin/dind;

#COPY dockerd-entrypoint.sh /usr/local/bin/
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