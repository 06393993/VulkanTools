#!/bin/bash

# Copyright 2017 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

if [ -z "${ANDROID_SDK_HOME}" ];
then echo "Please set ANDROID_SDK_HOME, exiting"; exit 1;
else echo "ANDROID_SDK_HOME is ${ANDROID_SDK_HOME}";
fi

if [ -z "${ANDROID_NDK_HOME}" ];
then echo "Please set ANDROID_NDK_HOME, exiting"; exit 1;
else echo "ANDROID_NDK_HOME is ${ANDROID_NDK_HOME}";
fi

if [[ $(uname) == "Linux" ]]; then
    cores=$(nproc) || echo 4
elif [[ $(uname) == "Darwin" ]]; then
    cores=$(sysctl -n hw.ncpu) || echo 4
fi
use_cores=${VT_BUILD_CORES:-$cores}

function findtool() {
    if [[ ! $(type -t $1) ]]; then
        echo Command $1 not found, see ../BUILD.md;
        exit 1;
    fi
}

# Check for dependencies
findtool aapt
findtool zipalign
findtool apksigner

set -ev

LAYER_BUILD_DIR=$PWD
CUBE_BUILD_DIR=$PWD/third_party/Vulkan-Tools/cube/android
echo LAYER_BUILD_DIR="${LAYER_BUILD_DIR}"
echo CUBE_BUILD_DIR="${CUBE_BUILD_DIR}"

function create_APK() {
    aapt package -f -M AndroidManifest.xml -I "$ANDROID_SDK_HOME/platforms/android-26/android.jar" -S res -F bin/$1-unaligned.apk bin/libs
    # update this logic to detect if key is already there.  If so, use it, otherwise create it.
    zipalign -f 4 bin/$1-unaligned.apk bin/$1.apk
    apksigner sign --verbose --ks ~/.android/debug.keystore --ks-pass pass:android bin/$1.apk
}

#
# Init base submodules
#
(pushd ..; git submodule update --init --recursive; popd)

#
# build layers
#
./update_external_sources_android.sh --no-build
./android-generate.sh
ndk-build -j $use_cores -l $use_cores

#
# build VulkanLayerValidationTests APK
#
mkdir -p bin/libs/lib
cp -r $LAYER_BUILD_DIR/libs/* $LAYER_BUILD_DIR/bin/libs/lib/
create_APK VulkanLayerValidationTests

#
# build vkcube APKs (with and without layers)
#
(
pushd $CUBE_BUILD_DIR
ndk-build -j $cores
# Package one APK without validation layers
mkdir -p $CUBE_BUILD_DIR/cube/bin/libs/lib
cp -r $CUBE_BUILD_DIR/libs/* $CUBE_BUILD_DIR/cube/bin/libs/lib/
cd $CUBE_BUILD_DIR/cube
create_APK vkcube
# And one with validation layers
mkdir -p $CUBE_BUILD_DIR/cube-with-layers/bin/libs/lib
cp -r $CUBE_BUILD_DIR/libs/* $CUBE_BUILD_DIR/cube-with-layers/bin/libs/lib/
cp -r $LAYER_BUILD_DIR/libs/* $CUBE_BUILD_DIR/cube-with-layers/bin/libs/lib/
cd $CUBE_BUILD_DIR/cube-with-layers
create_APK vkcube-with-layers
popd
)

#
# build Smoke with layers
#
# TODO

echo Builds succeeded
exit 0
