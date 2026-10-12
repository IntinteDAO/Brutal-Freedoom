#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIST="$DIR/dist"
mkdir -p "$DIST"

build_mod() {
    local mod="$1"
    local target="$DIR/$mod"
    if [ ! -d "$target" ]; then
        echo "Error: Mod directory '$mod' not found!"
        return 1
    fi
    local output="$DIST/${mod}.pk3"
    rm -f "$output"
    echo "Building $mod -> $output..."
    (cd "$target" && zip -r "$output" * -x "*.git*" "*.DS_Store*")
    echo "Successfully built: $output"
}

if [ -n "$1" ] && [ "$1" != "all" ]; then
    build_mod "$1"
else
    for d in "$DIR"/*/; do
        name="$(basename "$d")"
        if [ "$name" != "dist" ] && [ -f "$d/zscript.zs" -o -f "$d/KEYCONF" -o -f "$d/mapinfo.txt" ]; then
            build_mod "$name"
        fi
    done
fi
