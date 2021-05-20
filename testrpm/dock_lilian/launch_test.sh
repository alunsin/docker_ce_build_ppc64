#/bin/bash
export GOPATH=${WORKSPACE}/test:/go
export GO111MODULE=auto
cd /workspace/test/src/github.ibm.com/powercloud/dockertest
make test WHAT="./tests/$1" GOFLAGS="-v"
