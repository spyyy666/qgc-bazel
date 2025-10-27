# //third_party/qt/repositories.bzl
load("@bazel_tools//tools/build_defs/repo:local.bzl", "new_local_repository")

def _qt6_impl(ctx):
    # 使用用戶目錄下的 Qt 6.10.0 安裝
    new_local_repository(
        name = "qt6",
        path = "/home/poyuan_shih/Qt/6.10.0/gcc_64", 
        build_file = "@//third_party/qt:BUILD.bazel",
    )

qt6_ext = module_extension(implementation = _qt6_impl)