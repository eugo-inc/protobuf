# Eugo Protobuf Fork — Copilot Instructions

You are an expert maintainer of Eugo's fork of [protocolbuffers/protobuf](https://github.com/protocolbuffers/protobuf). This fork (`eugo-inc/protobuf`) modifies upstream protobuf to support Eugo's build and deployment pipeline on **Linux only**, targeting **Python >= 3.12** with **C++23** (`gnu++23`).

## Key context

| Item | Value |
|---|---|
| Upstream repo | `https://github.com/protocolbuffers/protobuf.git` (remote: `upstream`) |
| Fork repo | `https://github.com/eugo-inc/protobuf.git` (remote: `origin`) |
| Fork merge-base commit | `079bddd6e6b187001c79e780e83b3c9176a3d107` |
| Fork author emails | `benjamin.w.leff@gmail.com`, `gorloff.slava@gmail.com`, `31761951+gorloffslava@users.noreply.github.com` |
| Target platform | Linux only |
| Python | >= 3.12 |
| C/C++ standards | C: `gnu17`, C++: `gnu++23` |

### What this fork changes

1. **Python `protobuf` build system**: Replaced `setuptools`/`setup.py` (at `python/dist/setup.py`) with **Meson** (`meson.build` + `pyproject.toml` at repo root). The C extension `_message.so` is built via Meson linking against system-installed `libupb`/`utf8_range` (found via CMake config).

2. **Include path fixes**: Three C headers under `python/` had `#include "protobuf.h"` changed to `#include "python/protobuf.h"` to work correctly when Meson compiles with `src/` as an include directory.

3. **Well-known type `*_pb2.py` generation**: Meson `custom_target()` rules compile `.proto` files (any, api, descriptor, duration, empty, field_mask, source_context, struct, timestamp, type, wrappers, compiler/plugin) to Python `*_pb2.py` at build time and install them alongside the pure-Python package.

4. **Native protobuf (C/C++)**: Built with **CMake** (upstream's supported build). **No source-level modifications** — the CMake build is used as-is.

5. **Symbol visibility**: A linker version script (`python/version_script.lds`) exports only `PyInit__message`, hiding all other symbols — matching upstream's `-fvisibility=hidden` behavior.

## Build commands

### native/protobuf (C/C++ libraries)
```bash
# Standard upstream CMake build — installs to /usr/local
cmake -B build -S . -DCMAKE_BUILD_TYPE=Release
cmake --build build -j$(nproc)
cmake --install build
```
This installs `libprotobuf.so`, `libprotobuf-lite.so`, `libprotoc.so`, `libupb.a`, `protoc`, headers, and CMake config files system-wide. The Meson Python build depends on these being installed.

### python/protobuf (Python extension)
```bash
# Meson-based build (our build system)
pip install meson-python meson cmake
pip install . --no-build-isolation  # or: pip wheel .
```
The Meson build file is at `./meson.build`. It:
- Finds `libupb` via `dependency('protobuf', method: 'cmake', modules: ['protobuf::libupb'])`
- Finds `utf8_range` via `dependency('protobuf', method: 'cmake', modules: ['utf8_range::utf8_range'])`
- Builds `_message.so` from 10 C sources in `python/` plus upb backend linkage files
- Compiles well-known `.proto` files to `*_pb2.py`
- Installs pure-Python `google/protobuf/` package files

### Convenience scripts
| Script | Purpose |
|---|---|
| `eugo_meson_setup.sh` | `meson setup --reconfigure eugo_build` |
| `eugo_meson_compile.sh` | `meson compile -C eugo_build` |
| `eugo_pip3_wheel.sh` | `pip3 wheel . -Cbuilddir=eugo_build_whl --no-cache-dir --no-build-isolation --no-deps` |

## Downstream impact: `grpcio_tools` is eliminated

Our fork eliminates `grpcio_tools`. Upstream ships a separate `grpcio_tools` package (`python -m grpc_tools.protoc` / `grpc_tools.protoc.main([...])`) that bundles `protoc` + `grpc_python_plugin` as a Python extension. **Our fork does not need this.** Instead, users invoke the native `protoc` binary (installed by the CMake build) with `grpc_python_plugin` (installed by the `eugo-inc/grpc` CMake build) directly:

```bash
protoc \
  --plugin=protoc-gen-grpc_python="$(which grpc_python_plugin)" \
  --proto_path="${SOURCE_ROOT}" \
  --proto_path=/usr/local/include \
  --python_out="${BUILD_ROOT}" \
  --grpc_python_out="${BUILD_ROOT}" \
  --grpc_python_opt="grpc_2_0" \
  "${INPUT}"
```

This works because we build `native/protobuf` and `native/grpc` via CMake, which installs `protoc`, `grpc_python_plugin`, headers, and libraries system-wide.

### Key differences from `grpcio_tools`

| Topic | `grpcio_tools` (old) | Native `protoc` (Eugo) |
|---|---|---|
| Invocation | `python -m grpc_tools.protoc` or `grpc_tools.protoc.main([...])` | `protoc --plugin=protoc-gen-grpc_python=...` |
| gRPC plugin | Bundled inside the Python package | Separate binary: `grpc_python_plugin` (must be on `$PATH` or passed via `--plugin`) |
| Well-known `.proto` files | Shipped inside the `grpcio_tools` package | Installed to `/usr/local/include/` (or wherever CMake installed them) — add `--proto_path=/usr/local/include` if your protos import `google/protobuf/empty.proto` etc. |
| Modern codegen | N/A | `--grpc_python_opt="grpc_2_0"` produces code using `grpc.method_handlers_generic_handler()` instead of the deprecated `grpc.method_service_handler()` |

### Migration checklist for downstream projects

1. **Remove `grpcio_tools` from dependencies** — it is no longer needed.
2. **Replace `python -m grpc_tools.protoc`** with native `protoc` invocations.
3. **Replace `grpc_tools.protoc.main([...])`** calls in Python build scripts with `subprocess.run(['protoc', ...])`.
4. **Add `--plugin=protoc-gen-grpc_python="$(which grpc_python_plugin)"`** — the gRPC Python plugin must be specified explicitly.
5. **Add `--proto_path=/usr/local/include`** if any `.proto` files import well-known types like `google/protobuf/empty.proto`, `google/protobuf/timestamp.proto`, etc.
6. **Add `--grpc_python_opt="grpc_2_0"`** for modern gRPC codegen output.

## Project structure — Eugo-modified files

### New files (entirely Eugo-created)
| File | Purpose |
|---|---|
| `meson.build` (root) | Meson build for `python/protobuf` — builds `_message.so`, compiles `.proto` files, installs pure-Python files |
| `pyproject.toml` (root) | `meson-python` build backend config for `protobuf` |
| `src/google/protobuf/meson.build` | Meson targets for compiling well-known `.proto` files to `*_pb2.py` |
| `src/google/protobuf/compiler/meson.build` | Meson target for compiling `plugin.proto` to `plugin_pb2.py` |
| `python/version_script.lds` | Linker version script — exports only `PyInit__message`, hides everything else |
| `eugo_meson_setup.sh` | Convenience script for `meson setup` |
| `eugo_meson_compile.sh` | Convenience script for `meson compile` |
| `eugo_pip3_wheel.sh` | Convenience script for `pip3 wheel` |

### Modified upstream files
| File | Change | Marker |
|---|---|---|
| `python/convert.h:11` | `#include "protobuf.h"` → `#include "python/protobuf.h"` | `@EUGO_CHANGE` |
| `python/descriptor_pool.h:13` | `#include "protobuf.h"` → `#include "python/protobuf.h"` | `@EUGO_CHANGE` |
| `python/descriptor_containers.h:25` | `#include "protobuf.h"` → `#include "python/protobuf.h"` | `@EUGO_CHANGE` |
| `.gitignore:224-226` | Added `eugo_build` and `eugo_build_whl` entries | **UNMARKED** — needs `@EUGO_CHANGE` |

## Change marking convention

**All** Eugo modifications to upstream files MUST be wrapped with markers:
```cpp
// @EUGO_CHANGE: changed `original` to `replacement` — <brief description of why>
<changed line>
```

For multi-line changes:
```cpp
// @EUGO_CHANGE: @begin - <brief description>
<changed code>
// @EUGO_CHANGE: @end
```

For config files where comments use `#`:
```toml
# @EUGO_CHANGE: @begin: <brief description>
<changed lines>
# @EUGO_CHANGE: @end
```

### Rules
- Every modification to a file that exists upstream **must** have these markers.
- New files that don't exist upstream do not need markers (the entire file is an Eugo addition).
- The marker should include a brief explanation of **why** the change was made.

## Upstream merge workflow

### Git configuration
```
origin    → https://github.com/eugo-inc/protobuf.git  (our fork)
upstream  → https://github.com/protocolbuffers/protobuf.git (official protobuf)
```

### Merge procedure
```bash
git fetch upstream
git checkout main
git checkout -b <username>/chore/merge-upstream
git merge upstream/main
# Resolve conflicts — always preserve @EUGO_CHANGE blocks
# Test build: cmake for native, meson for python
git push origin <username>/chore/merge-upstream
# Create PR to main
```

### Conflict resolution rules
1. **Include path changes** (`python/convert.h`, `python/descriptor_pool.h`, `python/descriptor_containers.h`): Keep the Eugo side (`HEAD`/ours) — the `#include "python/protobuf.h"` lines. If upstream changes the same headers, merge carefully: keep our include path change but accept any other upstream modifications.
2. **`pyproject.toml` (root)**: Always keep the Eugo (Meson-based) version. Discard any upstream version entirely.
3. **`meson.build` files**: These are Eugo-only so they won't conflict, but may need updates if upstream changes source file locations, adds new `.c` files to the extension build, or adds new `.proto` files to the well-known types.
4. **`.gitignore`**: Keep our `eugo_build`/`eugo_build_whl` entries. Accept upstream additions.
5. **`python/dist/setup.py`**: Accept upstream changes. We don't modify this file — our Meson build replaces it entirely.
6. **`python/google/protobuf/__init__.py`**: Accept upstream's version number. Our `meson.build` reads the version from this file dynamically, so it always stays in sync.
7. **New upstream files**: Accept them. They don't conflict with our changes.

### After merge — validation checklist
- [ ] All `@EUGO_CHANGE` markers are intact
- [ ] No leftover `<<<<<<< HEAD` / `=======` / `>>>>>>>` conflict markers
- [ ] `meson.build` (root) `py.extension_module()` sources match `python/BUILD.bazel` `filegroup("message_srcs")`
- [ ] `src/google/protobuf/meson.build` proto targets match `python/dist/BUILD.bazel` `py_proto_library("well_known_proto_py_pb2")` deps
- [ ] `meson.build` `install_subdir` exclusions are consistent with `python/build_targets.bzl` `filegroup("python_src_files")` excludes
- [ ] If upstream added new `.c` files to `python/BUILD.bazel` `message_srcs`, add them to `meson.build`
- [ ] If upstream added new `.proto` files to `python/dist/BUILD.bazel` `well_known_proto_py_pb2`, add `custom_target()` entries
- [ ] If upstream added new Python files or removed existing ones, update `install_subdir` exclusion lists
- [ ] Native protobuf builds: `cmake -B build && cmake --build build`
- [ ] Python protobuf builds: `pip install .` (Meson)
- [ ] Basic import test passes (see validation section)

## Keeping meson.build files in sync with upstream

This is the most maintenance-intensive part of the fork. Every upstream merge can introduce new source files, new `.proto` files, or changed extension module structure. This applies to both `meson.build` at the root (which builds the `_message.so` extension) and the `meson.build` files under `src/google/protobuf/meson.build` and `src/google/protobuf/compiler/meson.build` which compile the well-known `.proto` files.

### Primary upstream sources to sync against

The Meson build must stay in sync with the **Bazel** build files (the canonical build system), **not** just `python/dist/setup.py`. The setuptools build uses glob patterns and may lag behind Bazel.

| Meson location | Syncs with Bazel file | Bazel target |
|---|---|---|
| `meson.build` `py.extension_module()` sources | `python/BUILD.bazel` | `filegroup("message_srcs")` |
| `meson.build` `py.extension_module()` deps | `python/BUILD.bazel` | `py_extension("_message")` `deps` |
| `src/google/protobuf/meson.build` proto targets | `python/dist/BUILD.bazel` | `py_proto_library("well_known_proto_py_pb2")` |
| `src/google/protobuf/compiler/meson.build` | `python/dist/BUILD.bazel` | `py_proto_library("plugin_py_pb2")` |
| `meson.build` `install_subdir` exclusions | `python/build_targets.bzl` | `filegroup("python_src_files")` glob/exclude |
| `meson.build` visibility/link flags | `python/py_extension.bzl` | `py_extension()` macro (sets `-fvisibility=hidden`) |

### How to check what upstream changed (Bazel-first)

```bash
# Check for new/removed C source files in the _message extension
git diff upstream/main~10..upstream/main -- python/BUILD.bazel | grep -A5 'message_srcs'

# Check for new well-known proto types
git diff upstream/main~10..upstream/main -- python/dist/BUILD.bazel | grep -A20 'well_known_proto_py_pb2'

# Check for new Python source files or changed exclusions
git diff upstream/main~10..upstream/main -- python/build_targets.bzl | grep -A10 'python_src_files'

# Check for new deps on the _message extension
git diff upstream/main~10..upstream/main -- python/BUILD.bazel | grep -A20 'py_extension'

# Also check setup.py as a secondary reference
git diff upstream/main~10..upstream/main -- python/dist/setup.py python/google/protobuf/__init__.py

# Check for new .c or .h files
git diff upstream/main~10..upstream/main -- python/*.c python/*.h

# Check for new .proto files
git diff upstream/main~10..upstream/main -- src/google/protobuf/*.proto
```

### Decision framework for upstream changes

When upstream modifies the Bazel build or `python/dist/setup.py`:

1. **New `.c` source files in `message_srcs` filegroup** (`python/BUILD.bazel`)? → Add them to `meson.build`'s `py.extension_module()` sources. Only files under `python/` need to be added — files under `upb/` or `utf8_range/` are in system libraries.

2. **New deps in `py_extension("_message")`** (`python/BUILD.bazel`)? → Check if the new dep is part of `libupb` (most `//upb/*` targets are). If so, no action needed — our system `libupb` already includes it. If it's a new dependency outside upb, evaluate whether it's available via our CMake build.

3. **New protos in `well_known_proto_py_pb2`** (`python/dist/BUILD.bazel`)? → Add corresponding `custom_target()` entries in `src/google/protobuf/meson.build`.

4. **Changed Python source exclusions in `python_src_files`** (`python/build_targets.bzl`)? → Update `exclude_files` / `exclude_directories` in `meson.build`'s `install_subdir()`.

5. **New include directories or compiler flags?** → Check if Meson's existing `include_directories: ['src/']` covers them. Check `py_extension.bzl` for new `copts`.

6. **Version bump in `__init__.py`?** → Automatic — our `meson.build` reads version from `python/google/protobuf/__init__.py` at configure time.

### How to check what upstream changed
```bash
# See what changed in the Python build between merges
git diff upstream/main~10..upstream/main -- python/dist/setup.py python/google/protobuf/__init__.py

# Check for new .c files in python/
git diff upstream/main~10..upstream/main -- python/*.c python/*.h

# Check for new .proto files
git diff upstream/main~10..upstream/main -- src/google/protobuf/*.proto
```

### Known source files in meson.build

The `_message.so` extension compiles these C sources from `python/`:
```
python/convert.c
python/descriptor_containers.c
python/descriptor_pool.c
python/descriptor.c
python/extension_dict.c
python/map.c
python/message.c
python/protobuf.c
python/repeated.c
python/unknown_fields.c
```

Plus the upb backend selection files:
```
python/google/protobuf/link_error_upb.cc
python/google/protobuf/use_upb_protos.cc
```

If upstream adds or removes files from this set, `meson.build` must be updated accordingly.

### Well-known .proto files compiled to *_pb2.py

| Proto file | Meson target | Install subdir |
|---|---|---|
| `any.proto` | `any_proto_py` | `google/protobuf/` |
| `api.proto` | `api_proto_py` | `google/protobuf/` |
| `descriptor.proto` | `descriptor_proto_py` | `google/protobuf/` |
| `duration.proto` | `duration_proto_py` | `google/protobuf/` |
| `empty.proto` | `empty_proto_py` | `google/protobuf/` |
| `field_mask.proto` | `field_mask_proto_py` | `google/protobuf/` |
| `source_context.proto` | `source_context_proto_py` | `google/protobuf/` |
| `struct.proto` | `struct_proto_py` | `google/protobuf/` |
| `timestamp.proto` | `timestamp_proto_py` | `google/protobuf/` |
| `type.proto` | `type_proto_py` | `google/protobuf/` |
| `wrappers.proto` | `wrappers_proto_py` | `google/protobuf/` |
| `compiler/plugin.proto` | `plugin_proto_py` | `google/protobuf/compiler/` |

Additionally, `descriptor.proto` is also compiled to upb C headers (`descriptor_proto_cpp_upb`) because the `_message.so` extension depends on it at build time.

If upstream adds new well-known `.proto` files, add corresponding `custom_target()` entries in `src/google/protobuf/meson.build`.

### Protobuf backend selection

The upstream Python protobuf package supports 3 backends:
1. **upb-based** (fastest, default) — this is what we use
2. **C++ bindings for libprotobuf** (deprecated, abandoned)
3. **Pure Python** (slow fallback)

Our `meson.build` includes `use_upb_protos.cc` and `link_error_upb.cc` to select the upb backend and prevent other backends from being linked. The other two backends are intentionally commented out. Do not enable them.

### Include directory considerations

The `meson.build` adds `src/` as an include directory. This is required because `protoc` generates upb headers with paths relative to `src/` (e.g., `google/protobuf/descriptor.upbdefs.h`). However, this means `src/google/protobuf/` headers are visible — which could conflict with system-installed protobuf headers. Currently there is no conflict because the extension only uses the upb backend (not full `libprotobuf`); see the detailed comment in `meson.build`.

### Runtime Python dependencies

`pyproject.toml` currently has no runtime Python dependencies (`install_requires=[]`), matching upstream's `python/dist/setup.py`. If upstream adds runtime dependencies, add them to `pyproject.toml` under `[project] dependencies`.

### Linker version script

`python/version_script.lds` exports only `PyInit__message` and hides all other symbols. This matches the upstream `-fvisibility=hidden` flag behavior. If upstream adds new extension modules (new `.pyx` or separate `Extension()` entries in `setup.py`), a corresponding entry must be added to the version script — or a new version script created for each module.

## Validating the Eugo wheel against upstream

Comparing our Meson-built wheel against the upstream `protobuf` wheel from PyPI is the primary correctness gate. If the two wheels contain the same pure-Python files, export the same native symbols, and pass the same runtime smoke tests, then our build is correct.

### Obtaining the two wheels

```bash
# 1. Build the Eugo wheel (requires system-installed libupb + utf8_range)
pip3 wheel . --no-build-isolation --no-deps -w dist/eugo/

# 2. Download the matching upstream wheel from PyPI
PROTOBUF_VERSION=$(python3 -c "exec(open('python/google/protobuf/__init__.py').read()); print(__version__)")
pip3 download protobuf==${PROTOBUF_VERSION} \
    --no-deps \
    --only-binary=:all: \
    --platform manylinux2014_x86_64 \
    --python-version 312 \
    -d dist/upstream/
```

### Step 1: Unpack and diff file listings

```bash
mkdir -p /tmp/eugo_wheel /tmp/upstream_wheel
unzip -o dist/eugo/protobuf-*.whl -d /tmp/eugo_wheel
unzip -o dist/upstream/protobuf-*.whl -d /tmp/upstream_wheel

# List all files relative to the unpack root, ignoring .dist-info metadata
(cd /tmp/eugo_wheel    && find . -type f | grep -v '\.dist-info' | sort) > /tmp/eugo_files.txt
(cd /tmp/upstream_wheel && find . -type f | grep -v '\.dist-info' | sort) > /tmp/upstream_files.txt

diff /tmp/eugo_files.txt /tmp/upstream_files.txt
```

**Expected result**: The file listings should be identical. Every `.py` file, `__init__.py`, `*_pb2.py`, and `_message` shared object present in the upstream wheel must also be present in ours. Any missing file indicates a gap in `meson.build`'s `install_subdir` / `install_data` / `custom_target` rules.

### Step 2: Diff pure-Python file contents

```bash
# Compare every .py file byte-for-byte
diff -rq /tmp/eugo_wheel/google/ /tmp/upstream_wheel/google/ \
    --exclude='*.so' \
    --exclude='*.dylib' \
    --exclude='__pycache__'
```

**Expected result**: No differences in pure Python files. The `*_pb2.py` files are generated by `protoc` and should be identical as long as the same `protoc` version was used. If they differ, check that the `protoc` binary version matches the protobuf source version.

### Step 3: Compare native extension exported symbols

The `_message` shared object will differ at the binary level (different compiler flags, linking strategy), but the **exported symbol set** must be equivalent.

```bash
# Eugo _message
nm -D /tmp/eugo_wheel/google/_upb/_message*.so | grep ' T ' | awk '{print $3}' | sort > /tmp/eugo_symbols.txt

# Upstream _message
nm -D /tmp/upstream_wheel/google/_upb/_message*.so | grep ' T ' | awk '{print $3}' | sort > /tmp/upstream_symbols.txt

diff /tmp/eugo_symbols.txt /tmp/upstream_symbols.txt
```

**Expected result**: Both should export `PyInit__message`. Our Meson build uses the linker version script (`python/version_script.lds`) to hide all other symbols — matching upstream's behavior.

### Step 4: Compare dynamic library dependencies

```bash
# Check what shared libraries each _message links against
readelf -d /tmp/eugo_wheel/google/_upb/_message*.so  | grep NEEDED | awk '{print $5}' | sort > /tmp/eugo_needed.txt
readelf -d /tmp/upstream_wheel/google/_upb/_message*.so | grep NEEDED | awk '{print $5}' | sort > /tmp/upstream_needed.txt

diff /tmp/eugo_needed.txt /tmp/upstream_needed.txt
```

**Expected result**: These will intentionally differ. Upstream bundles all C dependencies statically into `_message.so` (upb, utf8_range, etc.), so it typically has very few `NEEDED` entries (just `libc`, `libpthread`, `libm`, etc.). Our wheel dynamically links against system `libupb.a` (static) and `libutf8_range` — this is by design. The key check is that our wheel **does** list the expected protobuf-related dependencies and doesn't have spurious extras.

### Step 5: Compare package metadata

```bash
diff /tmp/eugo_wheel/protobuf-*.dist-info/METADATA \
     /tmp/upstream_wheel/protobuf-*.dist-info/METADATA
```

**Key fields to verify**:
- `Name`: must be `protobuf` in both
- `Version`: must match
- `Requires-Dist`: both should have no runtime dependencies (currently)

### Step 6: Runtime smoke tests

Install the Eugo wheel into a clean venv and run all tests below. Every test must pass for the wheel to be considered correct.

```bash
python -m venv /tmp/protobuf_test_venv
source /tmp/protobuf_test_venv/bin/activate
pip install dist/eugo/protobuf-*.whl
```

#### Test 6a: Import and basic API surface

Verifies the native extension loads, the version is correct, and fundamental protobuf operations work.

```bash
python -c "
import google.protobuf
print(f'protobuf version: {google.protobuf.__version__}')

# Verify the native extension loads
from google._upb import _message
print(f'_message loaded: {_message}')

# Verify well-known types are importable
from google.protobuf import descriptor_pb2
from google.protobuf import any_pb2
from google.protobuf import timestamp_pb2
from google.protobuf import duration_pb2
from google.protobuf import struct_pb2
from google.protobuf import wrappers_pb2
from google.protobuf import empty_pb2
from google.protobuf import field_mask_pb2
from google.protobuf import source_context_pb2
from google.protobuf import type_pb2
from google.protobuf import api_pb2
from google.protobuf.compiler import plugin_pb2
print('All well-known types importable.')

print('Test 6a passed.')
"
```

#### Test 6b: Serialization roundtrip with well-known types

End-to-end test that creates protobuf messages, serializes them, and deserializes them.

```bash
python -c "
from google.protobuf import timestamp_pb2, duration_pb2, struct_pb2, any_pb2, wrappers_pb2

# Timestamp roundtrip
ts = timestamp_pb2.Timestamp(seconds=1234567890, nanos=123456789)
data = ts.SerializeToString()
ts2 = timestamp_pb2.Timestamp()
ts2.ParseFromString(data)
assert ts2.seconds == 1234567890 and ts2.nanos == 123456789, f'Timestamp mismatch: {ts2}'

# Duration roundtrip
dur = duration_pb2.Duration(seconds=3600, nanos=500000000)
data = dur.SerializeToString()
dur2 = duration_pb2.Duration()
dur2.ParseFromString(data)
assert dur2.seconds == 3600 and dur2.nanos == 500000000, f'Duration mismatch: {dur2}'

# Struct roundtrip
s = struct_pb2.Struct()
s.fields['key'].string_value = 'hello'
s.fields['num'].number_value = 42.0
data = s.SerializeToString()
s2 = struct_pb2.Struct()
s2.ParseFromString(data)
assert s2.fields['key'].string_value == 'hello', f'Struct mismatch: {s2}'

# Any roundtrip
a = any_pb2.Any()
a.Pack(ts)
ts3 = timestamp_pb2.Timestamp()
a.Unpack(ts3)
assert ts3.seconds == 1234567890, f'Any roundtrip mismatch: {ts3}'

# Wrappers
w = wrappers_pb2.StringValue(value='test')
data = w.SerializeToString()
w2 = wrappers_pb2.StringValue()
w2.ParseFromString(data)
assert w2.value == 'test', f'Wrapper mismatch: {w2}'

print('Test 6b passed.')
"
```

#### Test 6c: Protoc code generation + generated stubs

Verifies that the native `protoc` binary (installed by CMake) can compile a `.proto` file and produce working Python stubs.

**Prerequisites**: `protoc` must be on `$PATH` (installed by `cmake --install build`).

```bash
PROTO_TEST_DIR=$(mktemp -d)

cat > "${PROTO_TEST_DIR}/test.proto" << 'EOF'
syntax = "proto3";
package test;

message TestMessage {
    string name = 1;
    int32 id = 2;
    repeated string tags = 3;
}

message TestResponse {
    string result = 1;
}
EOF

# Compile with native protoc
protoc \
  --proto_path="${PROTO_TEST_DIR}" \
  --python_out="${PROTO_TEST_DIR}" \
  "${PROTO_TEST_DIR}/test.proto"

# Verify generated file exists
test -f "${PROTO_TEST_DIR}/test_pb2.py" || { echo "FAIL: test_pb2.py not generated"; exit 1; }

# Verify generated code can be imported and used
python -c "
import sys
sys.path.insert(0, '${PROTO_TEST_DIR}')
import test_pb2

msg = test_pb2.TestMessage(name='hello', id=42, tags=['a', 'b', 'c'])
assert msg.name == 'hello' and msg.id == 42 and list(msg.tags) == ['a', 'b', 'c'], 'Field values incorrect'

# Roundtrip
data = msg.SerializeToString()
msg2 = test_pb2.TestMessage()
msg2.ParseFromString(data)
assert msg2.name == 'hello' and msg2.id == 42, 'Roundtrip failed'

print('Test 6c passed.')
"

rm -rf "${PROTO_TEST_DIR}"
```

#### Test 6d: JSON format support

Verifies `google.protobuf.json_format` works correctly with the native extension.

```bash
python -c "
from google.protobuf import json_format, timestamp_pb2, struct_pb2

# Timestamp → JSON → Timestamp
ts = timestamp_pb2.Timestamp(seconds=1234567890, nanos=0)
json_str = json_format.MessageToJson(ts)
ts2 = json_format.Parse(json_str, timestamp_pb2.Timestamp())
assert ts2.seconds == ts.seconds, f'JSON roundtrip mismatch: {ts2}'

# Dict → Struct → JSON → Struct
s = struct_pb2.Struct()
json_format.ParseDict({'key': 'value', 'num': 42, 'nested': {'a': True}}, s)
json_str = json_format.MessageToJson(s)
s2 = json_format.Parse(json_str, struct_pb2.Struct())
assert s2.fields['key'].string_value == 'value', f'Struct JSON mismatch: {s2}'

print('Test 6d passed.')
"
```

#### Test 6e: Descriptor and reflection API

Verifies the descriptor pool and reflection APIs work end-to-end with the upb backend.

```bash
PROTO_TEST_DIR=$(mktemp -d)

cat > "${PROTO_TEST_DIR}/reflection_test.proto" << 'EOF'
syntax = "proto3";
package reflection_test;

enum Color {
    RED = 0;
    GREEN = 1;
    BLUE = 2;
}

message Person {
    string name = 1;
    int32 age = 2;
    Color favorite_color = 3;
    repeated string hobbies = 4;
    map<string, string> attributes = 5;
}
EOF

protoc \
  --proto_path="${PROTO_TEST_DIR}" \
  --python_out="${PROTO_TEST_DIR}" \
  "${PROTO_TEST_DIR}/reflection_test.proto"

python -c "
import sys
sys.path.insert(0, '${PROTO_TEST_DIR}')
import reflection_test_pb2

# Verify descriptor
desc = reflection_test_pb2.Person.DESCRIPTOR
assert desc.name == 'Person', f'Descriptor name: {desc.name}'
assert len(desc.fields) == 5, f'Field count: {len(desc.fields)}'

# Verify enum
color_desc = reflection_test_pb2.Color.DESCRIPTOR
assert color_desc.values_by_name['RED'].number == 0
assert color_desc.values_by_name['BLUE'].number == 2

# Verify map field works
p = reflection_test_pb2.Person(name='Alice', age=30, favorite_color=reflection_test_pb2.GREEN)
p.hobbies.append('reading')
p.attributes['role'] = 'engineer'

# Roundtrip
data = p.SerializeToString()
p2 = reflection_test_pb2.Person()
p2.ParseFromString(data)
assert p2.name == 'Alice' and p2.age == 30 and p2.favorite_color == 1
assert list(p2.hobbies) == ['reading']
assert p2.attributes['role'] == 'engineer'

print('Test 6e passed.')
"

rm -rf "${PROTO_TEST_DIR}"
```

#### Test summary

```bash
deactivate
rm -rf /tmp/protobuf_test_venv
```

All five tests must pass:
| Test | What it validates |
|---|---|
| 6a | Native `_message` extension loads, version correct, all well-known types importable |
| 6b | Serialization roundtrip with well-known types (Timestamp, Duration, Struct, Any, Wrappers) |
| 6c | `protoc` code generation produces valid Python modules with working serialization |
| 6d | JSON format support (MessageToJson, Parse, ParseDict) |
| 6e | Descriptor and reflection API, enum types, map fields, repeated fields |

### What to do when differences are found

| Difference | Likely cause | Action |
|---|---|---|
| Missing `.py` files in Eugo wheel | Upstream added new Python modules | Update `install_subdir` exclusion lists or add new `install_data` in `meson.build` |
| Extra files in Eugo wheel | Test files or build artifacts included | Add exclusions to `meson.build`'s `exclude_files` / `exclude_directories` |
| Missing `*_pb2.py` files | Upstream added new well-known `.proto` files | Add `custom_target()` in `src/google/protobuf/meson.build` |
| `.py` file content differs | Upstream modified Python source since fork point | Merge upstream (`git merge upstream/main`) |
| Different exported symbols | Upstream changed visibility flags or extension structure | Review `meson.build` and `version_script.lds` |
| `_message` fails to load | Linking issue — `libupb` missing at runtime | Ensure `libupb` and `utf8_range` are installed; check `LD_LIBRARY_PATH` or `ldconfig` |
| Version mismatch | `__init__.py` version not merged | Merge upstream to get the latest version |
| New runtime dependencies | Upstream added a runtime Python dependency | Add it to `pyproject.toml` `[project] dependencies` |

### When to run this comparison

- **After every upstream merge** — before pushing the merge branch
- **After any `meson.build` change** — to catch install rule regressions
- **Before tagging a release** — final validation gate

## Code style

### Python
- Python >= 3.12, use f-strings freely
- Follow upstream protobuf Python style
- `pyproject.toml` uses `meson-python` as build backend — NOT setuptools

### C/C++
- Follow upstream protobuf style
- C17 (`gnu17`), C++23 (`gnu++23`)
- Use `/* ... */` C-style comments in `.c` files (upstream convention)

### Meson build files
- Use section markers: `# === @begin: Section Name ===` / `# === @end: Section Name ===`
- Use sub-section markers: `# @begin: subsection` / `# @end: subsection`
- Include detailed comments explaining **why** choices were made (see existing `meson.build` for reference)
- Every commented-out option must have an explanation of why it's excluded

## Boundaries

### Always do
- Wrap ALL modifications to upstream files with `@EUGO_CHANGE` markers
- Test both native (CMake) and Python (Meson) builds after changes
- Update this file when adding new Eugo modifications

### Never do
- Modify `CMakeLists.txt` or any upstream CMake files — the native build is used as-is
- Enable the C++ or pure-Python protobuf backends in `meson.build` — we use upb only
- Bundle upb or utf8_range sources into the Python extension — we link against system libraries
- Add `grpcio`-specific logic to this repo — that belongs in the `eugo-inc/grpc` fork
