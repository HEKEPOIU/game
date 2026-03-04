#!/bin/bash
set -e

SDL_VERSION="3.4.2"  
SDL_URL="https://www.libsdl.org/release/SDL3-${SDL_VERSION}.zip"
OUTPUT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$OUTPUT_DIR/lib"
# ----------------------------

mkdir -p "$LIB_DIR"

ZIP_FILE="$OUTPUT_DIR/SDL3-${SDL_VERSION}.zip"
if [ ! -f "$ZIP_FILE" ]; then
    echo "Downloading SDL3 v$SDL_VERSION..."
    curl -L -o "$ZIP_FILE" "$SDL_URL"
else
    echo "SDL zip already exists: $ZIP_FILE"
fi

UNZIP_DIR="$OUTPUT_DIR/SDL3-${SDL_VERSION}"
if [ ! -d "$UNZIP_DIR" ]; then
    echo "Unzipping..."
    unzip "$ZIP_FILE" -d "$OUTPUT_DIR"
fi

cd "$UNZIP_DIR"

mkdir -p build
cd build

echo "Configuring SDL..."
cmake -S .. -B . -DCMAKE_BUILD_TYPE=Release

echo "Building SDL..."
cmake --build . --target SDL3-shared

cp libSDL3.so "$LIB_DIR"

echo "Cleaning up..."
rm -rf "$UNZIP_DIR"
rm -rf "$OUTPUT_DIR/SDL3-${SDL_VERSION}.zip"
