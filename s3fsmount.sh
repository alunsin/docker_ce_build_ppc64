#/bin/bash

##
# Mount s3fs related to docker build
##
chmod 400 /docker-ce/.s3fs_cos_secret
mkdir -p /mnt/s3_ppc64le-docker
mkdir -p /mnt/s3_ibm-docker-builds
s3fs ppc64le-docker /mnt/s3_ppc64le-docker -o url=https://s3.us-south.cloud-object-storage.appdomain.cloud -o passwd_file=/docker-ce/.s3fs_cos_secret -o ibm_iam_auth -o allow_other
s3fs ibm-docker-builds /mnt/s3_ibm-docker-builds -o url=https://s3.us-east.cloud-object-storage.appdomain.cloud -o passwd_file=/docker-ce/.s3fs_cos_secret -o ibm_iam_auth -o allow_other
