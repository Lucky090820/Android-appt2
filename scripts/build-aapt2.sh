#!/usr/bin/env bash
#
# 从 AOSP 源码构建静态 aapt2（arm64 / bionic），供 Lucky 的 apkbuilder 使用。
#
# 依赖：cmake ninja bison flex go python3 git patch + Android NDK r27c
# 产物：out/aapt2（静态链接，可直接在 Android arm64 上执行）
#
# 环境变量：
#   TOOLS_TAG  构建脚手架版本（默认 35.0.2）
#   ANDROID_NDK_HOME  NDK 路径（CI 里由 setup-ndk 提供）
#   OUT        产物目录（默认 ./out）

set -euo pipefail

TAG="${TOOLS_TAG:-35.0.2}"
WORK="${WORK:-$PWD/.work}"
OUT="${OUT:-$PWD/out}"
REPO="https://github.com/lzhiyong/android-sdk-tools.git"

echo "==> NDK: ${ANDROID_NDK_HOME:-<unset>}"
if [ -z "${ANDROID_NDK_HOME:-}" ] && [ -z "${ANDROID_NDK_ROOT:-}" ]; then
  echo "ANDROID_NDK_HOME 未设置" >&2
  exit 1
fi

rm -rf "$WORK"
mkdir -p "$WORK"
echo "==> clone $REPO @ $TAG"
git clone --depth 1 --branch "$TAG" "$REPO" "$WORK/src" 2>/dev/null \
  || git clone --depth 1 "$REPO" "$WORK/src"

cd "$WORK/src"

echo "==> 拉取 AOSP 源码（aapt2 + 依赖）"
python3 get_source.py

echo "==> 构建 aapt2（static / aarch64 / api 30）"
python3 build.py \
  --arch aarch64 \
  --toolchain ndk \
  --link static \
  --api 30 \
  --target aapt2 \
  --clean

BIN="$WORK/src/build/ndk-static-aarch64/bin/build-tools/aapt2"
if [ ! -f "$BIN" ]; then
  echo "找不到产物：$BIN" >&2
  exit 1
fi

mkdir -p "$OUT"
cp "$BIN" "$OUT/aapt2"
chmod +x "$OUT/aapt2"
sha256sum "$OUT/aapt2" > "$OUT/aapt2.sha256"

echo "==> 产物"
file "$OUT/aapt2" || true
cat "$OUT/aapt2.sha256"
ls -lh "$OUT/aapt2"
