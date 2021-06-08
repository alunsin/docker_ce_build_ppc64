#/bin/bash

###
#TODO
# - docker login
# - skip deb/raspbian as this is for IOT, no ppc64
# -ubuntu-groovy, fatal: unable to access 'https://github.com/rootless-containers/rootlesskit.git/': gnutls_handshake() failed: Error in the pull function.
#make[1]: *** [debian/rules:11: override_dh_auto_build] Error 128
# - ubuntu-hirsute, #8 2.894 Err:4 http://ports.ubuntu.com/ubuntu-ports hirsute-security InRelease
#8 2.894   gpgv, gpgv2 or gpgv1 required for verification, but neither seems installed
##

##
# How to run
# 1) Run a docker in docker container + mount a docker-ce directory as the ouput directory for the build packages
#   $ mkdir docker-ce
#   $:~$ docker run -d -v ~/docker-ce:/docker-ce  --privileged  --name docker-build quay.io/alunsin/all_in_one_dind
# 2) Open a shell in the container
#   $docker exec -it docker-build /bin/bash
# 3) execute those comamnds inside the container
#  #rm -rf cli docker-ce-packaging moby scan-cli-plugin
#  cp -r /docker-ce/.docker /root
#  git clone https://github.com/alunsin/docker_ce_build_ppc64.git
#  DATE=`date +%d%m%y-%H%S`; export DATE && nohup bash -x docker_ce_build_ppc64/build_docker-ce.sh> logs_$DATE.out 2>&1 & sleep 1; tail -f logs_$DATE.out
##

REF='v20.10.7'
PACKAGING_REF='2455a897c45a7ab7f155950d3f69f28147c1526f'
DATE=`date +%d%m%y-%H%S`
BUILD_OUT_DIR="/docker-ce/docker-ce-$DATE"
mkdir $BUILD_OUT_DIR

#Workaround for builkit cache issue where fedora-32/Dockerfile
# (or the 1st Dockerfile used by buildkit) is used for all fedora's version
# See https://github.com/moby/buildkit/issues/1368
patchDockerFiles() {
  Dockfiles="$(find $1  -name 'Dockerfile')"
  d=$(date +%s)
  i=0
  for file in $Dockfiles; do
      i=$(( i + 1 ))
      echo "patching timestamp for $file"
      touch -d @$(( d + i )) "$file"
  done
}

if [ ! -d "$BUILD_OUT_DIR" ]; then
  echo "Build output directory does not exist ${DIR}"  >&2
  exit 1
fi

echo "Populating docker-ce-packaging from git ref=$PACKAGING_REF"

PACKAGING_DIR="docker-ce-packaging"
mkdir $PACKAGING_DIR
pushd $PACKAGING_DIR

git init
git remote add origin  https://github.com/docker/docker-ce-packaging.git
git fetch --depth 1 origin $PACKAGING_REF
git checkout FETCH_HEAD


echo "populate docker-ce-packaging/src folders"
make REF=$REF checkout
popd

echo "building debs"
pushd docker-ce-packaging/deb
patchDockerFiles .
DEB_LIST=`ls -1d debian-* ubuntu-*`
for DEB in $DEB_LIST
do
 echo ""
 echo "================================================="
 echo "==   Building for:$DEB                         =="
 echo "================================================="

 VERSION=$REF make debbuild/bundles-ce-$DEB-ppc64le.tar.gz
done
popd

echo "building rpms"
pushd docker-ce-packaging/rpm
patchDockerFiles .
RPM_LIST=`ls -1d fedora-* centos-*`
for RPM in $RPM_LIST
do
 
 echo ""
 echo "================================================="
 echo "==   Building for:$RPM                         =="
 echo "================================================="
 
 VERSION=$REF make rpmbuild/bundles-ce-$RPM-ppc64le.tar.gz
done
popd

 echo ""
 echo "================================================="
 echo "==   Copying packages to $BUILD_OUT_DIR        =="
 echo "================================================="

cp -r docker-ce-packaging/deb/debbuild/* $BUILD_OUT_DIR
cp -r docker-ce-packaging/rpm/rpmbuild/* $BUILD_OUT_DIR
