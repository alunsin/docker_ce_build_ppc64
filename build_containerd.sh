#/bin/bash


DATE=`date +%d%m%y-%H%S`
BUILD_OUT_DIR="/docker-ce/containerd-$DATE"
mkdir $BUILD_OUT_DIR


git clone https://github.com/docker/containerd-packaging.git
cd containerd-packaging


if [ $# -eq 0 ]
then
	TAG=$(git ls-remote  --refs  --tags https://github.com/containerd/containerd.git | cut --delimiter='/' --fields=3 | sort --version-sort| tail --lines=1)
else
	TAG=$1
fi

export DEBS="ubuntu:xenial ubuntu:bionic ubuntu:focal"
export RPMS="centos:7 centos:8 fedora:31 fedora:32"


export DISTROS="$DEBS $RPMS"

for DISTRO in $DISTROS
do
	make REF=${TAG} docker.io/library/$DISTRO
done

cp -r containerd-packaging/build/* $BUILD_OUT_DIR
