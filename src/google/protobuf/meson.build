# === @begin: any.proto ===
any_proto = ['any.proto']

# @begin: proto_py
any_proto_py = custom_target(
    input: any_proto,
    kwargs: proto_py_default_kwargs
)
# @end: proto_py
# === @end: any.proto ===


# === @begin: api.proto ===
api_proto = ['api.proto']

# @begin: proto_py
api_proto_py = custom_target(
    input: api_proto,
    kwargs: proto_py_default_kwargs
)
# @end: proto_py
# === @end: api.proto ===


# === @begin: descriptor.proto ===
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
duration_proto = ['duration.proto']

# @begin: proto_py
duration_proto_py = custom_target(
    input: duration_proto,
    kwargs: proto_py_default_kwargs
)
# @end: proto_py
# === @end: duration.proto ===


# === @begin: empty.proto ===
empty_proto = ['empty.proto']

# @begin: proto_py
empty_proto_py = custom_target(
    input: empty_proto,
    kwargs: proto_py_default_kwargs
)
# @end: proto_py
# === @end: empty.proto ===


# === @begin: field_mask.proto ===
field_mask_proto = ['field_mask.proto']

# @begin: proto_py
field_mask_proto_py = custom_target(
    input: field_mask_proto,
    kwargs: proto_py_default_kwargs
)
# @end: proto_py
# === @end: field_mask.proto ===


# === @begin: source_context.proto ===
source_context_proto = ['source_context.proto']

# @begin: proto_py
source_context_proto_py = custom_target(
    input: source_context_proto,
    kwargs: proto_py_default_kwargs
)
# @end: proto_py
# === @end: source_context.proto ===


# === @begin: struct.proto ===
struct_proto = ['struct.proto']

# @begin: proto_py
struct_proto_py = custom_target(
    input: struct_proto,
    kwargs: proto_py_default_kwargs
)
# @end: proto_py
# === @end: struct.proto ===


# === @begin: timestamp.proto ===
timestamp_proto = ['timestamp.proto']

# @begin: proto_py
timestamp_proto_py = custom_target(
    input: timestamp_proto,
    kwargs: proto_py_default_kwargs
)
# @end: proto_py
# === @end: timestamp.proto ===


# === @begin: type.proto ===
type_proto = ['type.proto']

# @begin: proto_py
type_proto_py = custom_target(
    input: type_proto,
    kwargs: proto_py_default_kwargs
)
# @end: proto_py
# === @end: type.proto ===


# === @begin: wrappers.proto ===
wrappers_proto = ['wrappers.proto']

# @begin: proto_py
wrappers_proto_py = custom_target(
    input: wrappers_proto,
    kwargs: proto_py_default_kwargs
)
# @end: proto_py
# === @end: wrappers.proto ===


# === @begin: compiler/ ===
subdir('compiler/')
# === @end: compiler/  ===

