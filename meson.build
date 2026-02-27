# === @begin: General ===
#
# This Meson build replaces upstream's setuptools-based build at `python/dist/setup.py`.
# It produces the same `google._upb._message` C extension module, but links against
# system-installed `libupb`/`utf8_range` instead of bundling their sources.
#
# The canonical source of truth for the Python extension build is the Bazel build:
#   - Extension module:   python/BUILD.bazel          (py_extension "_message")
#   - C source files:     python/BUILD.bazel           (filegroup "message_srcs")
#   - Well-known protos:  python/dist/BUILD.bazel      (py_proto_library "well_known_proto_py_pb2")
#   - Plugin proto:       python/dist/BUILD.bazel      (py_proto_library "plugin_py_pb2")
#   - Python source glob: python/build_targets.bzl     (filegroup "python_src_files")
#   - Wheel packaging:    python/dist/BUILD.bazel      (pkg_files "generated_wkt", "generated_wkt_compiler")
#
# When upstream changes Bazel targets, this Meson build must be updated to match.
# See copilot-instructions.md "Keeping meson.build files in sync" for the full procedure.
#
project(
    'protobuf',
    'c', 'cpp',
    default_options: [
        'c_std=gnu17',
        'cpp_std=gnu++23',
        'buildtype=release',
    ],
    meson_version: '>=1.3.0',
    # Version is extracted dynamically from the upstream-maintained version file.
    # This keeps us in sync automatically after upstream merges — no manual version bumps needed.
    # Upstream defines this in: python/google/protobuf/__init__.py
    version: run_command([
        'sed', '-n',
        's/__version__\\s*=\\s*[\'"]\\([^\'\"]*\\)[\'\"]/\\1/p',
        meson.project_source_root() / 'python' / 'google' / 'protobuf' / '__init__.py'
    ], check: true).stdout().strip()
)
# === @end: General ===


# === @begin: Meson modules imports ===
# `pure: false` is required because this package includes a compiled C extension (_message.so),
# not just pure Python files. This tells meson-python to produce a platform-specific wheel.
py = import('python').find_installation(pure: false)
# === @end: Meson modules imports ===


# === @begin: Dependencies ===
#
# These are system-installed libraries from the native protobuf CMake build (`cmake --install build`).
# Upstream's setuptools build bundles upb and utf8_range sources directly into _message.so
# (see the glob patterns in `python/dist/setup.py`). We instead link against the pre-built
# system libraries, which avoids duplicating symbols and reduces build time.
#
# Bazel equivalent deps (from python/BUILD.bazel `py_extension` "_message"):
#   protobuf_libupb  ↔  //upb/base, //upb/hash, //upb/message, //upb/port, //upb/reflection,
#                       //upb/text, //upb/util:def_to_proto, //upb/util:required_fields,
#                       //upb/wire:eps_copy_input_stream, //upb/wire:reader
#   utf8_range       ↔  //third_party/utf8_range
#
# All of these individual Bazel targets are compiled into a single `libupb.a` by the CMake build.
# The CMake config files provide the `protobuf::libupb` and `utf8_range::utf8_range` targets.
#
protobuf_libupb = dependency('protobuf', method: 'cmake', modules: ['protobuf::libupb'])
utf8_range = dependency('protobuf', method: 'cmake', modules: ['utf8_range::utf8_range'])

# System-installed `protoc` from the native CMake build. Used to compile .proto files
# to *_pb2.py (Python) and .upbdefs.h/.upbdefs.c (upb C headers) at Meson build time.
protoc_cpp = find_program('protoc')
# === @end: Dependencies ===


# === @begin: Utils ===
#
# Shared protoc invocation templates used by custom_target() rules in the
# src/google/protobuf/meson.build and src/google/protobuf/compiler/meson.build subdirs.
#

# @begin: proto_cpp_upb
#
# Generates upb C reflection headers from .proto files. Only used for descriptor.proto,
# because the _message.so extension needs descriptor.upbdefs.h at compile time.
#
# Bazel equivalent: //src/google/protobuf:descriptor_upb_reflection_proto
#   (which is a dep of the py_extension in python/BUILD.bazel)
#
protoc_cpp_upb_with_default_args = [
    protoc_cpp,
    '--proto_path=@SOURCE_ROOT@/src/',
    '--upbdefs_out=@BUILD_ROOT@/src/',
    '--upb_minitable_out=@BUILD_ROOT@/src/',
    '@INPUT@'
]
proto_cpp_upb_default_kwargs = {
    'command': protoc_cpp_upb_with_default_args,
    'output': ['@BASENAME@.upbdefs.h', '@BASENAME@.upbdefs.c']
}
# @end: proto_cpp_upb

# @begin: proto_py
#
# `/src/` part is required to strip `src` from the `protoc` generation logic. W/O that, it produces corrupted Python
# (10x times smaller) files failing at runtime.
#
# Generates *_pb2.py Python stubs from .proto files for the well-known types.
#
# Bazel equivalent: python/dist/BUILD.bazel
#   py_proto_library("well_known_proto_py_pb2")   — 11 well-known types
#   py_proto_library("plugin_py_pb2")             — compiler/plugin.proto
#
# The `--proto_path` and `--python_out` both use `@SOURCE_ROOT@/src/` and `@BUILD_ROOT@/src/`
# respectively. The `/src/` prefix is required so protoc strips it from the output path.
# Without it, protoc generates corrupted (10x smaller) Python files that fail at runtime
# because it produces `src/google/protobuf/foo_pb2.py` instead of `google/protobuf/foo_pb2.py`.
#
protoc_py_with_default_args = [
    protoc_cpp,
    '--proto_path=@SOURCE_ROOT@/src/',
    '--python_out=@BUILD_ROOT@/src/',
    '@INPUT@'
]
proto_py_default_install_dir = py.get_install_dir() / 'google' / 'protobuf'
proto_py_default_kwargs = {
    'command': protoc_py_with_default_args,
    'output': ['@BASENAME@_pb2.py'],
    'install': true,
    'install_dir': proto_py_default_install_dir
}
# @end: proto_py
# === @end: Utils ===


# === @begin: src/google/protobuf/ ===
#
# Compiles well-known .proto files to *_pb2.py and generates upb C headers for descriptor.proto.
# The targets defined here correspond to:
#   Bazel: python/dist/BUILD.bazel  →  "well_known_proto_py_pb2", "plugin_py_pb2", "generated_wkt"
#   Bazel: src/google/protobuf/BUILD.bazel  →  individual proto_library targets
#
# If upstream adds new well-known .proto files (check python/dist/BUILD.bazel "well_known_proto_py_pb2" deps),
# add corresponding custom_target() entries in src/google/protobuf/meson.build.
#
subdir('src/google/protobuf/')
# === @end: src/google/protobuf/ ===


# === @begin: _message.so ===
#
# Builds the `google._upb._message` C extension module — the native backend for
# the Python protobuf package.
#
# Bazel equivalent: python/BUILD.bazel → py_extension("_message")
# setuptools equivalent: python/dist/setup.py → Extension('google._upb._message', ...)
#
# The Bazel build defines the C sources in the "message_srcs" filegroup (python/BUILD.bazel).
# When upstream adds/removes .c files from that filegroup, update the list below to match.
#
py.extension_module(
    '_message',
    [
        # ── C source files ──
        # Synced with: python/BUILD.bazel → filegroup("message_srcs")
        # Also cross-ref: python/dist/setup.py → glob('python/*.c')
        #
        # If upstream adds new .c files, they'll appear in the "message_srcs" filegroup.
        # Files under upb/ and utf8_range/ are NOT listed here — they're in system libupb/utf8_range.
        'python/convert.c',
        'python/descriptor_containers.c',
        'python/descriptor_pool.c',
        'python/descriptor.c',
        'python/extension_dict.c',
        'python/map.c',
        'python/message.c',
        'python/protobuf.c',
        'python/repeated.c',
        'python/unknown_fields.c',

        # ── Backend selection files ──
        # Here, we can select from 3 protobuf implementations:
        # 1. upb-based
        # 2. C++ bindings for the fully-fledged libprotobuf. This only supported v2 language level, since it has been deprecated and now it seems to be abandoned.
        # 3. pure Python (quite slow)
        #
        # Inclusion of `use_*` files into the complication makes Python `protobuf` package select given backend as a
        # default one. Inclusion of `link_error_*` associated with the given `protobuf` backend ensures that no
        # other implementations are linked at the same time. Check `python/README.md` for more.
        #
        # Noteworthy, wheels published on PyPi ships with the first implementation. Pure Python variant is also pusblished
        # on PyPi but it's only used by default if the wheel suitable for a given Python installation and platform isn't found.


        # upb-based (fastest, default):
        'python/google/protobuf/link_error_upb.cc',
        'python/google/protobuf/use_upb_protos.cc',

        # NOTE: intentionally commented out
        # C++ bindings for libprotobuf (aka: `fast_cpp` or, simply, `cpp`):
        #'python/google/protobuf/link_error_fast_cpp.cc',
        #'python/google/protobuf/use_fast_cpp_protos.cc',
        #'python/google/protobuf/proto_api.cc',
        #'python/google/protobuf/proto_api.р',
        #'python/google/protobuf/pyext/{*}',

        # NOTE: intentionally commented out
        # pure Python (slow):
        #'python/google/protobuf/link_error_pure_python.cc',
        #'python/google/protobuf/use_pure_python.cc',
    ],
    include_directories: [
        # This is required to properly grab `descriptor_proto_cpp_upb_dep` headers.
        # In `protoc`, it injects the header paths into generated code sources relatively from the directory you invoke that. Yeah, meh.
        # This may cause issues if `python/protobuf` would depend on `google/protobuf/*` headers, as this folder incldues the same headers as `native/protobuf` we install.
        # And because `python/protobuf` depends only on `libupb` subcomponent from `native/protobuf` and not on the fully-fledged `libprotobuf`, we'll get into troubles as
        # having 2 sets of `google/protobuf/*` symbols but, potentially, with different API/ABI. ODR? Give me two!
        #
        # Good news - the only header `python/protobuf` actually uses from `src/google/` is one generated by `descriptor_proto_cpp_upb_dep`, so we don't get into troubles here but still we should be careful about that when updating `python/protobuf` in future.
        #
        # Bazel equivalent: the Bazel build doesn't need explicit include dirs because upb targets
        # export their headers transitively via `deps`. In Meson, we must add `src/` explicitly.
        #
        # This is required to find `descriptor_proto_cpp_upb_dep` generated headers
        # (e.g., `google/protobuf/descriptor.upbdefs.h`). protoc generates these headers
        # with paths relative to the source root — so we need `src/` on the include path.
        #
        # Risk: this makes `src/google/protobuf/` headers visible, which could conflict with
        # system-installed protobuf headers. Currently safe because the extension only uses the
        # upb backend (not full libprotobuf). The only header actually consumed from `src/google/`
        # is the generated `descriptor.upbdefs.h`. Be careful when updating.
        'src/',
        # Headers of `libupb` from `native/protobuf` are actually mixed with its sources and stored in the `protobuf`'s repo root `@/upb`.
        # This is a problem as this folder is added automatically by `meson` and we couldn't disable that, as otherwise we'll need to add
        # it back explicitely so the build will catch `python/*` headers stored ... also in repo's root `@/python`).
        # To avoid conflicts here, we remove this folder from the tree before building our Python version.
        # We couldn't remove it from the fork as we, obviously, need it to build `native/protobuf`'s `libupb`.
        # Note: upb headers (under repo root `upb/`) are mixed with upb sources in this repo.
        # Meson's implicit include of the project root picks up `python/` headers (needed),
        # but also `upb/` headers, which could conflict with system-installed upb headers.
        # To avoid conflicts, we remove the `upb/` directory from the tree before building
        # the Python extension. The `upb/` sources are still needed for the native CMake build.
        #
        # @Important:
        # We've only checked (and fixed) the conflicts for backend. We never checked the other 2 backends (C++ bindings, pure Python) because they're useless for us.
        # Only the upb backend include paths have been verified. The other 2 backends
        # (C++ bindings, pure Python) are unused and their include paths are unchecked.
    ],
    dependencies: [
        # Package-managed
        # Build-time generated headers for descriptor.proto (upb reflection).
        # Bazel equivalent: //src/google/protobuf:descriptor_upb_reflection_proto
        descriptor_proto_cpp_upb_dep,

        # Eugo-managed
        # System-installed libraries (from native CMake build).
        # Bazel equivalent: the full list of //upb/* deps in python/BUILD.bazel py_extension("_message")
        protobuf_libupb,
        # Bazel equivalent: //third_party/utf8_range
        utf8_range
    ],
    # Linker version script hides all symbols except PyInit__message.
    # This matches upstream Bazel's `-fvisibility=hidden` in python/py_extension.bzl,
    # and the setuptools build's `-fvisibility=hidden` flag.
    # See: python/version_script.lds
    link_args : ['-Wl,--version-script=' + meson.project_source_root() / 'python' / 'version_script.lds'],
    install: true,
    # Installed to site-packages/google/_upb/_message.so — same path as upstream.
    # Bazel equivalent: python/py_extension.bzl sets output to google/_upb/_message.abi3.so
    subdir: 'google/_upb/',
)
# === @end: _message.so ===


# === @begin: Pure Python ===
#
# Installs all pure-Python files from the `python/google/` source tree into the wheel.
#
# Bazel equivalent: python/build_targets.bzl → filegroup("python_src_files")
#   which globs `google/protobuf/**/*.py` excluding `*_test.py` and `test_util.py`.
#   The Bazel wheel packaging is in python/dist/BUILD.bazel → pkg_files("python_source_files").
#
# We use `install_subdir` with exclusion lists instead of explicit file lists.
# The exclude lists filter out:
#   1. C/C++ source files (compiled into _message.so or unused backends)
#   2. Test files (*_test.py, *.proto test fixtures) — Bazel also excludes these
#   3. pyext/ directory (deprecated C++ backend, not used)
#   4. Build templates and non-Python files
#
# When upstream adds new Python files, they're automatically included.
# When upstream adds new non-.py files, they may need to be added to exclude_files.
#
install_subdir(
    'python/google/',
    install_dir: py.get_install_dir(),
    install_tag: 'python-runtime',

    exclude_directories: [
        # Test-only packages — not shipped in the upstream wheel.
        'protobuf/internal/import_test_package/',
        'protobuf/internal/numpy/',
    ],

    exclude_files: [
        # The top-level google/__init__.py is a namespace package marker.
        # It must NOT be installed — the google namespace is shared with other packages
        # (e.g., google-cloud, googleapis-common-protos). Installing it would break them.
        '__init__.py',

        # Backend selection C/C++ files — compiled into _message.so, not installed as Python files.
        'protobuf/link_error_fast_cpp.cc',
        'protobuf/link_error_pure_python.cc',
        'protobuf/link_error_upb.cc',
        'protobuf/python_protobuf.h',
        'protobuf/use_fast_cpp_protos.cc',
        'protobuf/use_pure_python.cc',
        'protobuf/use_upb_protos.cc',
        'protobuf/proto_api.h',
        'protobuf/proto_api.cc',

        # Deprecated C++ bindings backend (aka: "cpp" or "fast_cpp").
        # These files are NOT compiled or shipped — the upb backend replaced them.
        'protobuf/pyext/descriptor.cc',
        'protobuf/pyext/descriptor.h',
        'protobuf/pyext/descriptor_containers.cc',
        'protobuf/pyext/descriptor_containers.h',
        'protobuf/pyext/descriptor_database.cc',
        'protobuf/pyext/descriptor_database.h',
        'protobuf/pyext/descriptor_pool.cc',
        'protobuf/pyext/descriptor_pool.h',
        'protobuf/pyext/extension_dict.cc',
        'protobuf/pyext/extension_dict.h',
        'protobuf/pyext/field.cc',
        'protobuf/pyext/field.h',
        'protobuf/pyext/map_container.cc',
        'protobuf/pyext/map_container.h',
        'protobuf/pyext/message.cc',
        'protobuf/pyext/message.h',
        'protobuf/pyext/message_factory.cc',
        'protobuf/pyext/message_factory.h',
        'protobuf/pyext/message_module.cc',
        'protobuf/pyext/python.proto',
        'protobuf/pyext/README',
        'protobuf/pyext/repeated_composite_container.cc',
        'protobuf/pyext/repeated_composite_container.h',
        'protobuf/pyext/repeated_scalar_container.cc',
        'protobuf/pyext/repeated_scalar_container.h',
        'protobuf/pyext/safe_numerics.h',
        'protobuf/pyext/scoped_pyobject_ptr.h',
        'protobuf/pyext/unknown_field_set.cc',
        'protobuf/pyext/unknown_field_set.h',
        'protobuf/pyext/free_threading_mutex.h',
        'protobuf/pyext/weak_value_map.h',

        # Internal
        # Test files, .proto fixtures, C++ sources, and templates.
        # These match the exclusion pattern in Bazel: python/build_targets.bzl
        # filegroup("python_src_files") excludes `*_test.py` and `test_util.py`.
        # We also exclude .proto files (test fixtures), .cc files (native code),
        # and .py.template files (build-time codegen templates).
        'protobuf/internal/any_test.py',
        'protobuf/internal/api_implementation.cc',
        'protobuf/internal/decoder_test.py',
        'protobuf/internal/descriptor_database_test.py',
        'protobuf/internal/descriptor_pool_test.py',
        'protobuf/internal/descriptor_pool_test1.proto',
        'protobuf/internal/descriptor_pool_test2.proto',
        'protobuf/internal/descriptor_test.py',
        'protobuf/internal/duration_test.py',
        'protobuf/internal/factory_test1.proto',
        'protobuf/internal/factory_test2.proto',
        'protobuf/internal/field_mask_test.py',
        'protobuf/internal/file_options_test.proto',
        'protobuf/internal/generator_test.py',
        'protobuf/internal/import_test.py',
        'protobuf/internal/json_format_test.py',
        'protobuf/internal/keywords_test.py',
        'protobuf/internal/message_factory_test.py',
        'protobuf/internal/message_set_extensions.proto',
        'protobuf/internal/message_test.py',
        'protobuf/internal/missing_enum_values.proto',
        'protobuf/internal/more_extensions.proto',
        'protobuf/internal/more_extensions_dynamic.proto',
        'protobuf/internal/more_messages.proto',
        'protobuf/internal/no_package.proto',
        'protobuf/internal/packed_field_test.proto',
        'protobuf/internal/proto_builder_test.py',
        'protobuf/internal/proto_json_test.py',
        'protobuf/internal/proto_test.py',
        'protobuf/internal/proto_text_test.py', # NOTE: upstream wheel accidentally includes this test file, but we exclude it intentionally.
        'protobuf/internal/proto_api_test.py',
        'protobuf/internal/proto_api_test_ext.cc',
        'protobuf/internal/pybind11_test_module.cc',
        'protobuf/internal/python_edition_defaults.py.template',
        'protobuf/internal/python_protobuf.cc',
        'protobuf/internal/recursive_message_pybind11_test.py',
        'protobuf/internal/reflection_cpp_test.py',
        'protobuf/internal/reflection_test.py',
        'protobuf/internal/runtime_version_test.py',
        'protobuf/internal/self_recursive.proto',
        'protobuf/internal/self_recursive_from_py.proto',
        'protobuf/internal/service_reflection_test.py',
        'protobuf/internal/symbol_database_test.py',
        'protobuf/internal/test_bad_identifiers.proto',
        'protobuf/internal/test_proto2.proto',
        'protobuf/internal/test_proto3_optional.proto',
        'protobuf/internal/test_util.py',
        'protobuf/internal/text_encoding_test.py',
        'protobuf/internal/text_format_test.py',
        'protobuf/internal/thread_safe_test.py',
        'protobuf/internal/timestamp_test.py',
        'protobuf/internal/unknown_fields_test.py',
        'protobuf/internal/well_known_types_test.proto',
        'protobuf/internal/well_known_types_test.py',
        'protobuf/internal/wire_format_test.py',
    ]
)
# === @end: Pure Python ===
