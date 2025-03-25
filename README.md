# 🕵️‍♂️ Native Binaries vs WebAssembly Components: A Capability Perspective

This project is a hands-on comparison between traditional Linux executables and WebAssembly components, focused on how each model handles system interaction—especially file system access and security boundaries.

We'll walk through building and inspecting the same simple C program:
- ✅ As a **native Linux binary**, with full syscall access
- 🔒 As a **WASI-based WebAssembly component**, with capability-based imports

> This demo also includes an intentional directory traversal vulnerability to show how WebAssembly’s sandboxing prevents common bugs from becoming exploits.

---

## 📦 What’s Inside

```bash
wasm-vs-native/
├── Dockerfile                  # Reproducible build environment
├── Makefile                    # Easy build and inspection commands
├── read_file.c                # Vulnerable C program
├── example.txt                # Regular file to read
├── inputs/
│   └── secret.txt             # File we shouldn't be allowed to read
└── README.md                  # You're here
```

---

## 🚀 Quick Start

```bash
git clone https://github.com/your-username/wasm-vs-native.git
cd wasm-vs-native
docker build -t wasm-vs-native .
docker run --rm -it wasm-vs-native
```

Or run locally with tools installed:

```bash
make              # Builds native, wasm, and wasm component
make inspect      # Inspect WebAssembly component imports
make trace        # Trace native Linux system calls (Linux only)
make trace-mac    # Trace native macOS system calls (requires sudo)
```

---

## 👾 The Vulnerable C Program

`read_file.c` accepts a file path as a CLI argument and prints its contents. It does **not** sanitize user input, making it vulnerable to directory traversal:

```c
fopen(argv[1], "r");
```

---

## 🛠️ Native Binary Behavior

```bash
make native
./native_read ../inputs/secret.txt
```

✅ This will succeed. Native executables have unrestricted access to the host file system.

🔍 Inspect system calls:

### On Linux:
```bash
strace ./native_read ../inputs/secret.txt
```

You’ll see:

```
openat(AT_FDCWD, "../inputs/secret.txt", O_RDONLY)
read(...)
write(...)
```

### On macOS:
```bash
make trace-mac
```

This uses `dtruss` to show similar syscall-level tracing:

```
open("example.txt", 0x0, 0x1B6)         = 3
read(3, "...")                         = 42
write(1, "...")                        = 42
```

---

## 🧩 WebAssembly Component Behavior

```bash
make wasm component
wash inspect --wit read_file_component.wasm
```

You’ll see something like:

```
import wasi:filesystem/types@0.2.0;
import wasi:filesystem/preopens@0.2.0;
import wasi:cli/stdout@0.2.0;
```

These **explicitly declare the component’s capabilities**. There are no raw syscalls—just structured, sandboxed imports.

Try running:

```bash
wasmtime run --dir=. read_file.wasm ../inputs/secret.txt
```

🚫 This fails because the path `../inputs/secret.txt` is **outside the preopened directory**.

---

## 🔐 Why This Matters

Native binaries run with the full power of the host. Unless sandboxed externally (e.g. seccomp, containers), they can read, write, and execute whatever the OS allows.

WebAssembly components, especially with the [WASI](https://wasi.dev/) standard, follow the **principle of least privilege**:

- 🧭 Imports declare exactly what the module expects
- 🧱 Filesystem access is scoped and preopened
- 🧼 Bugs like directory traversal become harmless

---

## 📚 Summary Table

| Feature                 | Native Executable         | WASI Component                      |
|------------------------|---------------------------|-------------------------------------|
| Syscalls               | Direct (e.g. `openat`)    | None (uses WIT-based imports)       |
| File Access            | Unrestricted              | Scoped via `--dir` and preopens     |
| Introspection          | `strace`, `readelf`       | `wash inspect`, WIT interfaces      |
| Security Boundary      | OS-level                  | Contractual, per import             |
| Vulnerability Impact   | High                      | Often mitigated by default sandbox  |

---

## 🧪 Want to Try More?

- Modify the program to write instead of read — compare `write` capabilities
- Try with `wasi-preview2` style components and more granular imports
- Use [wasmtime](https://wasmtime.dev/)

---

## 🤝 Acknowledgements

Inspired by the growing power of the WebAssembly Component Model and the promise of portable, secure compute everywhere.

Built with ❤️ by developers who believe in sandboxing-by-default.

> PRs welcome!
