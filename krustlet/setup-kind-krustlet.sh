#!/usr/bin/env bash

set -e
# job control
set -m

function getGatewayIP() {
  docker inspect bridge -f "{{ (index .IPAM.Config 0).Gateway }}"
}

function bootstrapToken {
  #FILE_NAME=$(pwd)/bootstrap.conf
  bash <(curl https://raw.githubusercontent.com/krustlet/krustlet/main/scripts/bootstrap.sh)
}

# Retries a command on failure.
# $1 - the max number of attempts
# $2... - the command to run
retry() {
  local -r -i max_attempts="$1"
  shift
  local -r cmd="$@"
  local -i attempt_num=1

  until $cmd; do
    if ((attempt_num == max_attempts)); then
      echo "Attempt $attempt_num failed and there are no more attempts left!"
      return 1
    else
      echo "Attempt $attempt_num failed! Trying again in $attempt_num seconds..."
      sleep $((attempt_num++))
    fi
  done
}

function startKrustlet {
  IP=$(getGatewayIP)
  echo $IP
  RUST_LOG="info" krustlet-wasi --node-ip $IP --node-name=krustlet --hostname=krustlet --bootstrap-file=$HOME/.krustlet/config/bootstrap.conf &
}

function approveClientCert {
  kubectl certificate approve krustlet-tls
}

function installKrustlet {
  # return early if krustlet-wasi is already in path
  command -v krustlet-wasi
  if [ $? ]; then
    return
  fi

  KERNEL=$(uname)
  if [[ $KERNEL == "Darwin" ]]; then
    # override kernel to macos because krustlet specifies their images as macos, not darwin
    KERNEL="macos"
  fi

  ARCH=$(uname -m)
  case $ARCH in
  "x86_64")
    echo "using amd64 arch"
    ARCH="amd64"
    ;;
  esac

  TAR_PATH=$(pwd)/krustlet.tar.gz
  URL="https://krustlet.blob.core.windows.net/releases/krustlet-canary-$KERNEL-$ARCH.tar.gz"
  echo "download krustlet using URL: $URL"
  curl -L -o $TAR_PATH $URL

  tar xfz $TAR_PATH
  # remove junk
  rm $TAR_PATH README.md LICENSE

  echo "Copy krustlet binary to /usr/local/bin"
  sudo mv krustlet* /usr/local/bin/
}

function createKindCluster {
  kind create cluster --name krustlet
}

function deleteKindCluster {
  kind delete cluster --name krustlet
}

function cleanup {
  killall krustlet-wasi
  deleteKindCluster
  rm -rf 
}

trap cleanup EXIT

installKrustlet
createKindCluster
bootstrapToken
startKrustlet
retry 10 approveClientCert

# reattach to krustlet process
fg
