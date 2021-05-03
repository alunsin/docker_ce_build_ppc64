#/bin/bash

###
#TODO
# - docker login
# - skip deb/raspbian as this is for IOT, no ppc64
# -ubuntu-groovy, fatal: unable to access 'https://github.com/rootless-containers/rootlesskit.git/': gnutls_handshake() failed: Error in the pull function.
make[1]: *** [debian/rules:11: override_dh_auto_build] Error 128
# - ubuntu-hirsute, #8 2.894 Err:4 http://ports.ubuntu.com/ubuntu-ports hirsute-security InRelease
#8 2.894   gpgv, gpgv2 or gpgv1 required for verification, but neither seems installed
#
# rm -rf cli docker-ce-packaging moby scan-cli-plugin
#nohup bash -x mybuild.sh > logs.out 2>&1 & sleep 1; tail -f logs.out

REPO_LIST="https://github.com/docker/cli.git \
           https://github.com/moby/moby.git"

REF='v20.10.6'

BUILD_OUT_DIR='/docker-ce'

if [ ! -d "$BUILD_OUT_DIR" ]; then
  echo "Build output directory does not exist ${DIR}"  >&2
  exit 1
fi

git clone --depth 1 https://github.com/docker/scan-cli-plugin.git
git clone --depth 1 https://github.com/docker/docker-ce-packaging.git

for REPO in $REPO_LIST
do
 echo "cloning repo:$REPO:$REF"
 git clone -q --depth 1 --single-branch --branch $REF $REPO
done


echo "populate docker-ce-packaging/src folders"
mkdir -p docker-ce-packaging/src/github.com/docker/cli
mkdir -p docker-ce-packaging/src/github.com//docker/docker
mkdir -p docker-ce-packaging/src/github.com/docker/scan-cli-plugin

cp -r cli/* docker-ce-packaging/src/github.com/docker/cli
cp -r moby/* docker-ce-packaging/src/github.com/docker/docker
cp -r scan-cli-plugin/* docker-ce-packaging/src/github.com/docker/scan-cli-plugin

echo "building rpms"
pushd docker-ce-packaging/rpm

RPM_LIST=`ls -1d fedora-* rhel-* centos-*`
for RPM in $RPM_LIST
do
 echo "building for:$RPM"
 VERSION=$REF make $RPM
 echo ""
 echo "================================================="
 echo "==   Building for:$RPM                         =="
 echo "================================================="
done

popd

echo "building debs"
pushd docker-ce-packaging/deb
DEB_LIST=`ls -1d debian-* ubuntu-* raspbian-*`
for DEB in $DEB_LIST
do
 echo ""
 echo "================================================="
 echo "==   Building for:$DEB                         =="
 echo "================================================="

 VERSION=$REF make $DEB
done
popd


 echo ""
 echo "================================================="
 echo "==   Copying packages to $BUILD_OUT_DIR        =="
 echo "================================================="

cp -r docker-ce-packaging/deb/debbuild/* $BUILD_OUT_DIR
cp -r docker-ce-packaging/rpm/rpmbuild/* $BUILD_OUT_DIR

#(cd docker-ce-packaging/deb && VERSION=$REF make deb)
#(cd docker-ce-packaging/rpm && VERSION=$REF make rpm)

