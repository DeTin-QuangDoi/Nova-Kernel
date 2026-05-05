#!/bin/env bash

export DEBIAN_FRONTEND=noninteractive
set -e
set -o pipefail

# Only support a73xq
DEVICE="a73xq"
VARIANT="a73xq"
echo "--- Building kernel for $DEVICE ---"

# Setup toolchains
export ARCH=arm64
export SUBARCH=arm64
export PROJECT_NAME=a73xq

# GCC
export GCC_PATH="$(pwd)/toolchain/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin"
mkdir -p "$GCC_PATH"
cd "$GCC_PATH"
for tool in gcc g++ cpp ld ar as nm objcopy objdump strip readelf; do
  if [ -f "$(which aarch64-linux-gnu-${tool} 2>/dev/null)" ]; then
    ln -sf "$(which aarch64-linux-gnu-${tool})" "aarch64-linux-android-${tool}" 2>/dev/null || true
  fi
done
cd ../../../../../../../
export CROSS_COMPILE="$GCC_PATH/aarch64-linux-android-"

# Clang
export CLANG_PATH="$(pwd)/toolchain/llvm-arm-toolchain-ship/10.0/bin"
export REAL_CC="$CLANG_PATH/clang"
export CLANG_TRIPLE="aarch64-linux-gnu-"
export LD_LIBRARY_PATH="$CLANG_PATH/lib:$LD_LIBRARY_PATH"

# Build env
export DTC_EXT="$(pwd)/tools/dtc"
export CONFIG_BUILD_ARM64_DT_OVERLAY=y
export CONFIG_SECTION_MISMATCH_WARN_ONLY=y

echo "--- Kernel Configuration ---"
make -j$(nproc) -C $(pwd) O=$(pwd)/out \
  ARCH=arm64 \
  CROSS_COMPILE="$CROSS_COMPILE" \
  REAL_CC="$REAL_CC" \
  CLANG_TRIPLE="$CLANG_TRIPLE" \
  vendor/a73xq_eur_open_defconfig

echo "--- Building Image ---"
make -j$(nproc) -C $(pwd) O=$(pwd)/out \
  ARCH=arm64 \
  CROSS_COMPILE="$CROSS_COMPILE" \
  REAL_CC="$REAL_CC" \
  CLANG_TRIPLE="$CLANG_TRIPLE" \
  Image

echo "--- Build completed ---"
ls -lh out/arch/arm64/boot/Image
