#!/bin/sh

VERSION="0.23.0"
curl -L -o tinygo.tar.gz https://github.com/tinygo-org/tinygo/releases/download/v$VERSION/tinygo$VERSION.$(uname | awk '{print tolower($0)}')-amd64.tar.gz

mkdir lib/tinygo-release || true
tar xfz tinygo.tar.gz -C lib/tinygo-release
rm tinygo.tar.gz
