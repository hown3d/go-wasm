#!/bin/sh
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && /bin/pwd)"
NERDCTL="limactl shell fedora nerdctl"
IMAGE_TAR=$DIR/tinygo-wasm.tar

podman build --annotation "module.wasm.image/variant=compat" -f $DIR/../Dockerfile.tinygo $DIR/../. -t tinygo-wasm
podman image save --quiet -o $IMAGE_TAR tinygo-wasm

$NERDCTL load -i $IMAGE_TAR
rm $IMAGE_TAR
$NERDCTL run --rm --runtime crun --label "module.wasm.image/variant=compat" localhost/tinygo-wasm
