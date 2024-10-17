# === @begin: General ===
project(
    'protobuf',
    'c', 'cpp',
    default_options: [
        'c_std=gnu17',
        'cpp_std=gnu++23',
        'buildtype=release',
    ],
    meson_version: '>=1.3.0',
    version: '5.30.0' # Must match pyproject.toml#project
)
# === @end: General ===


# === @begin: Meson modules imports ===
py = import('python').find_installation(pure: false)
# === @end: Meson modules imports ===


# === @begin: Project-wide settings ===
# === @end: Project-wide settings ===


# === @begin: Dependencies ===
protobuf_libupb = dependency('protobuf', method: 'cmake', modules: ['protobuf::libupb'])
utf8_range = dependency('protobuf', method: 'cmake', modules: ['utf8_range::utf8_range'])

protoc_cpp = find_program('protoc')
# === @end: Dependencies ===


# === @begin: Utils ===
# @begin: proto_cpp_upb
protoc_cpp_upb_with_default_args = [
    protoc_cpp,
    '--proto_path=@SOURCE_ROOT@',
    '--upbdefs_out=@BUILD_ROOT@',
    '--upb_minitable_out=@BUILD_ROOT@',
    '@INPUT@'
]
proto_cpp_upb_default_kwargs = {
    'command': protoc_cpp_upb_with_default_args,
    'output': ['@BASENAME@.upbdefs.h', '@BASENAME@.upbdefs.c']
}
# @end: proto_cpp_upb

# @begin: proto_py
protoc_py_with_default_args = [
    protoc_cpp,
    '--proto_path=@SOURCE_ROOT@',
    '--python_out=@BUILD_ROOT@',
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
subdir('src/google/protobuf/')
# === @end: src/google/protobuf/ ===


# === @begin: _message.so ===
py.extension_module(
    '_message',
    [
        'python/convert.c',
        'python/descriptor.c',
        'python/descriptor_containers.c',
        'python/descriptor_pool.c',
        'python/extension_dict.c',
        'python/map.c',
        'python/message.c',
        'python/protobuf.c',
        'python/repeated.c',
        'python/unknown_fields.c',

        # Here, we can select from 3 protobuf implementations:
        # 1. upb-based
        # 2. C++ bindings for the fully-fledged libprotobuf (deprecated and seems to be abandoned)
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

        # C++ bindings for libprotobuf (aka: fast_cpp):
        #'python/google/protobuf/link_error_fast_cpp.cc',
        #'python/google/protobuf/use_fast_cpp_protos.cc',

        # pure Python (slow):
        #'python/google/protobuf/link_error_pure_python.cc',
        #'python/google/protobuf/use_pure_python.cc',

    ],
    include_directories: [
        'src/',
    ],
    install: true,
    subdir: 'google/_upb/',
    dependencies: [
        # Package-managed
        descriptor_proto_cpp_upb_dep,

        # Eugo-managed
        protobuf_libupb,
        utf8_range
    ],
    link_args : ['-Wl,--version-script=' + meson.project_source_root() / 'python' / 'version_script.lds'],
)
# === @end: _message.so ===


# === @begin: Pure Python ===
install_subdir(
    'python/google/',
    install_dir: py.get_install_dir(),
    install_tag: 'python-runtime',

    exclude_directories: [
        'protobuf/internal/import_test_package/',
        'protobuf/internal/numpy/',
    ],

    exclude_files: [
        '__init__.py',

        'protobuf/link_error_fast_cpp.cc',
        'protobuf/link_error_pure_python.cc',
        'protobuf/link_error_upb.cc',
        'protobuf/proto_api.h',
        'protobuf/python_protobuf.h',
        'protobuf/use_fast_cpp_protos.cc',
        'protobuf/use_pure_python.cc',
        'protobuf/use_upb_protos.cc',

        'protobuf/any.py',
        'protobuf/duration.py',
        'protobuf/timestamp.py',

        # C++ bindings (fast cpp)
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
