#/bin/bash

cat <<'EOF'>> launch_test.sh
#/bin/bash
export GOPATH=${WORKSPACE}/test:/go
export GO111MODULE=auto
cd /workspace/test/src/github.ibm.com/powercloud/dockertest
make test WHAT="./tests/ubuntu" GOFLAGS="-v"
EOF
cp ~/.docker/config.json ./config.json
              mkdir Test_Result
              touch ./Test_Result/test_result.txt
                cat <<'EOF'>> Dockerfile
ARG IMAGE
ARG GOLANG_VERSION=1.15.2
ARG BAZEL_VERSION=2.2.0
ARG IBM_CLOUD_VERSION=1.2.1
FROM golang:$GOLANG_VERSION AS builder


ARG TF_VERSION
ENV TF_VERSION ${TF_VERSION:-v0.12.29}

RUN go get rsc.io/goversion \
    && GO111MODULE=on go get github.com/hashicorp/terraform@$TF_VERSION

FROM ppc64le/ubuntu:$IMAGE

ARG GOLANG_VERSION
ENV GOLANG_VERSION ${GOLANG_VERSION:-1.15.2}

ARG BAZEL_VERSION
ENV BAZEL_VERSION ${BAZEL_VERSION:-2.2.0}

ARG IBM_CLOUD_VERSION
ENV IBM_CLOUD_VERSION ${IBM_CLOUD_VERSION:-1.2.1}

WORKDIR /workspace
RUN mkdir -p /workspace
ENV WORKSPACE=/workspace \
    TERM=xterm
ENV PATH /usr/local/go/bin:$PATH

COPY --from=builder /go/bin/* /usr/local/bin/

RUN apt-get update && apt-get install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg2 \
    wget \
    software-properties-common \
    lsb-release && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    curl \
    file \
    git \
    make \
    openssh-client \
    pkg-config \
    procps \
    rsync \
    unzip \
    wget \
    xz-utils \
    zip \
    zlib1g-dev

RUN wget https://golang.org/dl/go1.15.2.linux-ppc64le.tar.gz
RUN rm -rf /usr/local/go && tar -C /usr/local -xzf go1.15.2.linux-ppc64le.tar.gz
RUN export PATH=$PATH:/usr/local/go/bin

ARG DISTRO
RUN mkdir /root/.docker/
COPY config.json /root/.docker/
ADD ./package2test/containerd/ubuntu/$DISTRO/ppc64el/containerd.io_1.4.4-1_ppc64el.deb ./
ADD ./package2test/docker-ce/ubuntu-$DISTRO/docker-ce-cli_20.10.6~3-0~ubuntu-$DISTRO\_ppc64el.deb ./
ADD ./package2test/docker-ce/ubuntu-$DISTRO/docker-ce_20.10.6~3-0~ubuntu-$DISTRO\_ppc64el.deb ./
# ADD containerd.io_1.4.4-1_ppc64el.deb ./
# ADD docker-ce-cli_20.10.6~3-0~ubuntu-bionic_ppc64el.deb ./
# ADD docker-ce_20.10.6~3-0~ubuntu-bionic_ppc64el.deb ./
ADD launch_test.sh /
RUN chmod a+x /launch_test.sh
RUN apt update && apt install -f && apt install -y jq curl iptables libdevmapper1.02.1 wget &&\
    dpkg -i ./containerd.io_1.4.4-1_ppc64el.deb &&\
    dpkg -i ./docker-ce-cli_20.10.6~3-0~ubuntu-$DISTRO\_ppc64el.deb &&\
    dpkg -i ./docker-ce_20.10.6~3-0~ubuntu-$DISTRO\_ppc64el.deb &&\
    dockerd -v /var/run/docker.sock:/var/run/docker.sock
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

VOLUME /var/lib/docker
EXPOSE 2375 2376

ENTRYPOINT ["dockerd-entrypoint.sh"]
EOF

                    #UBUNTU_DISTS=bionic xenial focal
                    #for DISTROS in $UBUNTU_DISTS
                    for DISTROS in bionic xenial focal
                    do
                      docker build --build-arg IMAGE=$DISTROS --build-arg DISTRO=$DISTROS . >> outputtemps.txt
                      IMGBUILD=$(tail -1 outputtemps.txt | sed -e "s/^Successfully built //")
                      #if docker build --build-arg IMAGE=$DISTROS --build-arg DISTRO=$DISTROS . ; then echo "Test Successful for ubuntu:"$DISTROS"">>./Test_Result/test_result.txt; else echo "Test failed for ubuntu:"$DISTROS"">>./Test_Result/test_result.txt; fi
                    docker run -d -v ~/package2test/dockertest:/workspace/test/src/github.ibm.com/powercloud/dockertest --privileged --name docker-test-ub $IMGBUILD
                    docker exec -it docker-test-ub /bin/bash /launch_test.sh >> ./Test_Result/test_result_ubuntu_$DISTROS.txt
                    docker stop docker-test-ub
                    docker rm docker-test-ub
                    rm outputtemps.txt
              done

rm config.json
rm Dockerfile
rm launch_test.sh
