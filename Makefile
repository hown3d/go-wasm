build-wasm:
	GOOS=js GOARCH=wasm go build -o normal-go/out/main.wasm normal-go/main.go

build-tinygo-wasm:
	docker run --rm -v $(shell pwd):/src -w /src tinygo/tinygo:0.23.0 tinygo build -o tinygo/out/main.wasm -target=wasi ./tinygo/main.go

run-tinygo-wasmedge: 
	docker run --rm -v $(shell pwd)/tinygo/out:/app -w /app --entrypoint=/root/.wasmedge/bin/wasmedge wasmedge/appdev_x86_64:0.9.0 main.wasm 

copy-wasm-exec:
	cp "$(shell go env GOROOT)/misc/wasm/wasm_exec.js" $(shell pwd)/normal-go/out

start-fileserver:
	go run cmd/server/main.go
