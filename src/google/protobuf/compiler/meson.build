# === @begin: plugin.proto ===
plugin_proto = ['plugin.proto']

# @begin: proto_py
plugin_proto_py = custom_target(
    input: plugin_proto,
    kwargs: proto_py_default_kwargs + {
        'install_dir': proto_py_default_install_dir / 'compiler'
    }
)
# @end: proto_py
# === @end: plugin.proto ===
