# //toolchains/repositories.bzl
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def _aarch64_toolchain_impl():
    """Fetches and unpacks the aarch64 cross-compiler."""
    http_archive(
        name = "aarch64_linux_gnu_toolchain",
        # Example URL for a Linaro toolchain. Replace with your chosen toolchain.
        urls = ["https://releases.linaro.org/components/toolchain/binaries/.../gcc-linaro-7.2.1-2017.11-x86_64_aarch64-linux-gnu.tar.xz"],
        sha256 = "...",
        strip_prefix = "gcc-linaro-7.2.1-2017.11-x86_64_aarch64-linux-gnu",
        build_file_content = """
filegroup(
    name = "all_files",
    srcs = glob(["**"]),
    visibility = ["//visibility:public"],
)
""",
    )

aarch64_toolchain_ext = module_extension(implementation = _aarch64_toolchain_impl)