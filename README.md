# Android-aapt2

从 AOSP 源码构建**静态 aapt2（arm64 / bionic）**，给 [Lucky](https://github.com/) 的 `apkbuilder` 用。

## 为什么

手机上要编 APK，需要一个能在 Android 上直接跑的 `aapt2`。官方只发 x86_64 主机版，
所以这里用 NDK 从 AOSP 源码交叉编译成 **静态链接的 arm64 可执行文件**（无运行时依赖）。

## 用法

1. Actions → **aapt2** → Run workflow（可改 `tools_tag`，默认 `35.0.2`）
2. 跑完下载 artifact `aapt2-aarch64`，内含：
   - `aapt2`（静态二进制）
   - `aapt2.sha256`
3. 校验：

```bash
sha256sum -c aapt2.sha256
```

4. 放进 Lucky 工具包：

```bash
adb push aapt2 /data/local/tmp/aapt2
adb shell su -c 'cp /data/local/tmp/aapt2 /data/local/toolchains/apkbuilder/bin/aapt2 && chmod 755 /data/local/toolchains/apkbuilder/bin/aapt2'
adb shell su -c '/data/local/toolchains/apkbuilder/bin/aapt2 version'
```

## 参数

| 项 | 值 |
|---|---|
| 目标架构 | `aarch64`（arm64-v8a） |
| 链接方式 | `static`（bionic，无 .so 依赖） |
| API level | 30 |
| NDK | r27c |
| 构建脚手架 | [lzhiyong/android-sdk-tools](https://github.com/lzhiyong/android-sdk-tools) `35.0.2` |

## 许可

- aapt2 / AOSP 源码：Apache-2.0
- 本仓库脚本：Apache-2.0
