tinygo-libs:
	@if [ ! -e lib/tinygo/README.md ]; then echo "Submodules have not been downloaded. Please download them using:\n  git submodule update --init"; exit 1; fi
	cd lib/tinygo && git submodule update --init && make wasi-libc binaryen

tinygo-release:
	scripts/install-tinygo.sh