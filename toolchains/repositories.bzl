# //toolchains/repositories.bzl
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def _aarch64_toolchain_impl(ctx):
    """Fetches and unpacks the aarch64 cross-compiler."""
    http_archive(
        name = "aarch64_linux_gnu_toolchain",
        # ... 其他參數 ...
        # 這是 Linaro toolchain 的範例 URL (請替換為您選擇的可靠來源)
        urls = ["https://releases.linaro.org/components/toolchain/binaries/.../gcc-linaro-7.2.1-2017.11-x86_64_aarch64-linux-gnu.tar.xz"],
        sha256 = "...", # 必須填寫正確的 SHA256 Hash
        strip_prefix = "gcc-linaro-7.2.1-2017.11-x86_64_aarch64-linux-gnu",
        # 定義 BUILD 檔案內容以暴露所有文件 (all_files)
        build_file_content = """
filegroup(
    name = "all_files",
    srcs = glob(["**"]),
    visibility = ["//visibility:public"],
)
""",
    )

aarch64_toolchain_ext = module_extension(implementation = _aarch64_toolchain_impl)