#!/bin/bash

echo -e "Installing WasmEdge"
if [ -f install.sh ]; then
  rm -rf install.sh
fi
curl -L -o install.sh -q https://raw.githubusercontent.com/WasmEdge/WasmEdge/master/utils/install.sh
sudo chmod a+x install.sh
sudo ./install.sh --path="/usr/local"
rm -rf install.sh

echo -e "Building and installing crun"
OS=$(awk -F= '$1=="ID" { print $2 ;}' /etc/os-release)
if [[ $OS == "fedora" ]]; then
  sudo dnf install -y make python git gcc automake autoconf libcap-devel \
    systemd-devel yajl-devel libseccomp-devel pkg-config \
    go-md2man glibc-static python3-libmount libtool
elif [[ $OS == "ubuntu" || $OS == "debian" ]]; then
  sudo apt install -y make git gcc build-essential pkgconf libtool libsystemd-dev \
    libprotobuf-c-dev libcap-dev libseccomp-dev libyajl-dev \
    go-md2man libtool autoconf python3 automake
else
  echo "unsupported OS: $OS"
  exit
fi

git clone https://github.com/containers/crun /tmp/crun || true
cd /tmp/crun
./autogen.sh
./configure --with-wasmedge
make
sudo make install

