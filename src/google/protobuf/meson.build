#
# Well-known .proto file compilation targets.
#
# Each custom_target() below corresponds to a dep in the Bazel build:
#   python/dist/BUILD.bazel -> py_proto_library("well_known_proto_py_pb2")
# which depends on proto_library targets defined in:
#   src/google/protobuf/BUILD.bazel (aliased from root BUILD.bazel as //:*_proto)
#
# If upstream adds new well-known .proto files, a corresponding entry must be added here.
# Check: git diff upstream/main -- python/dist/BUILD.bazel | grep 'well_known_proto_py_pb2' -A20
#

# === @begin: any.proto ===
# Bazel: //:any_proto -> src/google/protobuf:any_proto
any_proto = ['any.proto']

# @begin: proto_py
any_proto_py = custom_target(
    input: any_proto,
    kwargs: proto_py_default_kwargs
)
# @end: proto_py
# === @end: any.proto ===


# === @begin: api.proto ===
# Bazel: //:api_proto -> src/google/protobuf:api_proto
api_proto = ['api.proto']

# @begin: proto_py
api_proto_py = custom_target(
    input: api_proto,
    kwargs: proto_py_default_kwargs
)
# @end: proto_py
# === @end: api.proto ===


# === @begin: descriptor.proto ===
# Bazel: //:descriptor_proto -> src/google/protobuf:descriptor_proto
# Special: also compiled to upb C headers (descriptor_proto_cpp_upb) because
# the _message.so extension depends on descriptor.upbdefs.h at build time.
# Bazel equivalent for the upb target: //src/google/protobuf:descriptor_upb_reflection_proto
descriptor_proto = ['descriptor.proto']

# @begin: proto_cpp_upb
descriptor_proto_cpp_upb = custom_target(
    input: descriptor_proto,
    kwargs: proto_cpp_upb_default_kwargs
)

descriptor_proto_cpp_upb_dep = declare_dependency(
    sources: descriptor_proto_cpp_upb,
    dependencies: [protobuf_libupb]
)
# @end: proto_cpp_upb

# @begin: proto_py
descriptor_proto_py = custom_target(
    input: descriptor_proto,
    kwargs: proto_py_default_kwargs
)
# @end: proto_py
# === @end: descriptor.proto ===


# === @begin: duration.proto ===
# Bazel: //:duration_proto -> src/google/protobuf:duration_proto
duration_proto = ['duration.proto']

# @begin: proto_py
duration_proto_py = custom_target(
    input: duration_proto,
    kwargs: proto_py_default_kwargs
)
# @end: proto_py
# === @end: duration.proto ===


# === @begin: empty.proto ===
# Bazel: //:empty_proto -> src/google/protobuf:empty_proto
empty_proto = ['empty.proto']

# @begin: proto_py
empty_proto_py = custom_target(
    input: empty_proto,
    kwargs: proto_py_default_kwargs
)
# @end: proto_py
# === @end: empty.proto ===


# === @begin: field_mask.proto ===
# Bazel: //:field_mask_proto -> src/google/protobuf:field_mask_proto
field_mask_proto = ['field_mask.proto']

# @begin: proto_py
field_mask_proto_py = custom_target(
    input: field_mask_proto,
    kwargs: proto_py_default_kwargs
)
# @end: proto_py
# === @end: field_mask.proto ===


# === @begin: source_context.proto ===
# Bazel: //:source_context_proto -> src/google/protobuf:source_context_proto
source_context_proto = ['source_context.proto']

# @begin: proto_py
source_context_proto_py = custom_target(
    input: source_context_proto,
    kwargs: proto_py_default_kwargs
)
# @end: proto_py
# === @end: source_context.proto ===


# === @begin: struct.proto ===
# Bazel: //:struct_proto -> src/google/protobuf:struct_proto
struct_proto = ['struct.proto']

# @begin: proto_py
struct_proto_py = custom_target(
    input: struct_proto,
    kwargs: proto_py_default_kwargs
)
# @end: proto_py
# === @end: struct.proto ===


# === @begin: timestamp.proto ===
# Bazel: //:timestamp_proto -> src/google/protobuf:timestamp_proto
timestamp_proto = ['timestamp.proto']

# @begin: proto_py
timestamp_proto_py = custom_target(
    input: timestamp_proto,
    kwargs: proto_py_default_kwargs
)
# @end: proto_py
# === @end: timestamp.proto ===


# === @begin: type.proto ===
# Bazel: //:type_proto -> src/google/protobuf:type_proto
type_proto = ['type.proto']

# @begin: proto_py
type_proto_py = custom_target(
    input: type_proto,
    kwargs: proto_py_default_kwargs
)
# @end: proto_py
# === @end: type.proto ===


# === @begin: wrappers.proto ===
# Bazel: //:wrappers_proto -> src/google/protobuf:wrappers_proto
wrappers_proto = ['wrappers.proto']

# @begin: proto_py
wrappers_proto_py = custom_target(
    input: wrappers_proto,
    kwargs: proto_py_default_kwargs
)
# @end: proto_py
# === @end: wrappers.proto ===


# === @begin: compiler/ ===
# Bazel: python/dist/BUILD.bazel -> py_proto_library("plugin_py_pb2")
#        deps = ["//:compiler_plugin_proto"] -> src/google/protobuf/compiler:plugin_proto
subdir('compiler/')
# === @end: compiler/  ===

