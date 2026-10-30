#!/usr/bin/env bash
#
# 从 AOSP 源码构建静态 aapt2（arm64 / bionic），供 Lucky 的 apkbuilder 使用。
# 步骤参照 lzhiyong/android-sdk-tools 自己的 CI（ubuntu-24.04 + NDK r27c）。
#
# 环境变量：
#   TOOLS_TAG        构建脚手架版本（默认 35.0.2）
#   ANDROID_NDK_HOME NDK 路径（CI 由 setup-ndk 提供）
#   OUT              产物目录（默认 ./out）

set -euxo pipefail
exec > >(tee -a "${LOG:-build.log}") 2>&1

TOOLS_COMMIT="${TOOLS_COMMIT:-fe637bf075f1b734b4b01d281f9f58899245ed92}"
AOSP_TAG="${AOSP_TAG:-platform-tools-35.0.2}"
WORK="${WORK:-$PWD/.work}"
OUT="${OUT:-$PWD/out}"
REPO="https://github.com/lzhiyong/android-sdk-tools.git"

echo "NDK=${ANDROID_NDK_HOME:-<unset>}"
: "${ANDROID_NDK_HOME:?ANDROID_NDK_HOME 未设置}"

python3 --version
cmake --version | head -1
ninja --version
go version || true

rm -rf "$WORK"
mkdir -p "$WORK"
echo "==> clone $REPO @ $TOOLS_COMMIT"
git init -q "$WORK/src"
cd "$WORK/src"
git remote add origin "$REPO"
git fetch --depth 1 origin "$TOOLS_COMMIT"
git checkout -q FETCH_HEAD

cd "$WORK/src"
echo "==> 拉 AOSP 源码"
python3 get_source.py --tags "$AOSP_TAG"

echo "==> 编译 host protoc"
python3 build.py --protoc-only --protoc-output "$WORK/protoc"

echo "==> 构建 aapt2"
python3 build.py \
  --toolchain ndk \
  --arch aarch64 \
  --link static \
  --protoc "$WORK/protoc" \
  --target aapt2 \
  --output-dir "$OUT/dist"

ZIP="$OUT/dist/android-sdk-tools-static-aarch64.zip"
[ -f "$ZIP" ] || { echo "产物缺失：$ZIP"; ls -R "$OUT" || true; exit 1; }

rm -rf "$OUT/extract"
mkdir -p "$OUT/extract"
unzip -o -q "$ZIP" -d "$OUT/extract"

BIN=$(find "$OUT/extract" -type f -name aapt2 | head -1)
[ -n "$BIN" ] || { echo "zip 里没找到 aapt2"; unzip -l "$ZIP" | head -20; exit 1; }
echo "aapt2: $BIN"

mkdir -p "$OUT/artifact"
cp "$BIN" "$OUT/artifact/aapt2"
chmod +x "$OUT/artifact/aapt2"
sha256sum "$OUT/artifact/aapt2" > "$OUT/artifact/aapt2.sha256"

echo "==> 完成"
file "$OUT/artifact/aapt2" || true
cat "$OUT/artifact/aapt2.sha256"
ls -lh "$OUT/artifact/aapt2"
