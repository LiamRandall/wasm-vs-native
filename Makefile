WASI_SDK_PATH ?= /opt/wasi-sdk
WIT_BINDGEN ?= wit-bindgen

# Building with command since c program relies on main and has no bindgen exports
ADAPTER_URL ?= https://github.com/bytecodealliance/wasmtime/releases/download/v31.0.0/wasi_snapshot_preview1.command.wasm
ADAPTER_FILE ?= wasi_snapshot_preview1.command.wasm
# ADAPTER_URL ?= https://github.com/bytecodealliance/wasmtime/releases/download/v31.0.0/wasi_snapshot_preview1.reactor.wasm

all: native wasm component inspect

native:
	gcc read_file.c -o native_read

wasm:
	${WASI_SDK_PATH}/bin/clang \
		--target=wasm32-wasi \
		--sysroot=${WASI_SDK_PATH}/share/wasi-sysroot \
		-o read_file.wasm read_file.c

adapter:
	@if [ ! -f ${ADAPTER_FILE} ]; then \
		echo "Downloading WASI preview1 adapter..."; \
		curl -fL -o ${ADAPTER_FILE} ${ADAPTER_URL}; \
	fi

component: wasm adapter
	wasm-tools component new read_file.wasm \
		--adapt ${ADAPTER_FILE} \
		--output read_file_component.wasm

inspect:
	wash inspect --wit read_file_component.wasm

trace:
	strace ./native_read example.txt

clean:
	rm -f native_read read_file.wasm read_file_component.wasm ${ADAPTER_FILE}
