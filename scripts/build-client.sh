#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$REPO_DIR/build"
FTEQW_DIR="$BUILD_DIR/fteqw"

VALVE_PK3_URL="https://www.frag-net.com/pkgs/package_valve.pk3"
CSTRIKE_PK3_URL="https://www.frag-net.com/pkgs/package_cstrike.pk3"
CS15_URL="https://archive.org/download/counter-strike-1.5/csv15full_cstrike.zip"

err() { echo "ERROR: $*" >&2; exit 1; }
msg() { echo "==> $*"; }

download() {
    local url="$1" dest="$2"
    if [ -f "$dest" ]; then
        msg "Already downloaded $(basename "$dest"), skipping..."
        return
    fi
    msg "Downloading $(basename "$dest")..."
    curl -fsSL "$url" -o "$dest" || err "Failed to download $url"
}

mkdir -p "$BUILD_DIR/downloads"

msg "Cloning FTEQW..."
if [ ! -d "$FTEQW_DIR" ]; then
    git clone --depth 1 https://github.com/fte-team/fteqw.git "$FTEQW_DIR"
fi

msg "Patching FTEQW..."
bash "$SCRIPT_DIR/patch-fteqw.sh" "$FTEQW_DIR"

msg "Building FTEQW static libraries..."
(cd "$FTEQW_DIR/engine" && make makelibs FTE_TARGET=win64)

msg "Building FTEQW Windows client..."
(cd "$FTEQW_DIR/engine" && make gl-rel FTE_TARGET=win64 -j"$(nproc)")
FTEQW_WIN64="$FTEQW_DIR/engine/release/fteglqw64.exe"
[ -f "$FTEQW_WIN64" ] || err "fteglqw64.exe not found after build"

msg "Building FTEQW Linux client..."
(cd "$FTEQW_DIR/engine" && make makelibs FTE_TARGET=linux64)
(cd "$FTEQW_DIR/engine" && make gl-rel FTE_TARGET=linux64 -j"$(nproc)")
FTEQW_LINUX64="$FTEQW_DIR/engine/release/fteglqw64"
[ -f "$FTEQW_LINUX64" ] || err "fteglqw64 (linux) not found after build"

msg "Downloading game data..."
DL_DIR="$BUILD_DIR/downloads"
download "$VALVE_PK3_URL" "$DL_DIR/package_valve.pk3"
download "$CSTRIKE_PK3_URL" "$DL_DIR/package_cstrike.pk3"
download "$CS15_URL" "$DL_DIR/cs15data.zip"

build_package() {
    local PLATFORM="$1" EXE_SRC="$2" EXE_NAME="$3" ZIP_NAME="$4"
    local PKG="$BUILD_DIR/pkg-$PLATFORM"
    local HLDIR="$PKG/Half-Life"

    rm -rf "$PKG"
    mkdir -p "$HLDIR/valve" "$HLDIR/cstrike"

    msg "[$PLATFORM] Copying engine..."
    cp -f "$EXE_SRC" "$HLDIR/$EXE_NAME"
    chmod +x "$HLDIR/$EXE_NAME"

    msg "[$PLATFORM] Copying game data..."
    cp -f "$DL_DIR/package_valve.pk3" "$HLDIR/valve/package_valve.pk3"
    cp -f "$DL_DIR/package_cstrike.pk3" "$HLDIR/cstrike/package_cstrike.pk3"
    cp -f "$DL_DIR/cs15data.zip" "$HLDIR/cstrike/pak0.pk3"

    cat > "$HLDIR/valve/liblist.gam" <<'LIBLIST'
game "Half-Life"
startmap "c0a0"
trainmap "t0a0"
mpentity "info_player_deathmatch"
gamedll "dlls/hl.dll"
gamedll_linux "dlls/hl.so"
type "singleplayer_only"
cldll "1"
LIBLIST

    msg "[$PLATFORM] Copying FreeCS data..."
    for item in cfg data decls fonts gfx maps particles progs resource scripts \
                progs.dat csprogs.dat hud.dat quake.rc icon.tga \
                default_aliases.cfg default_cstrike.cfg default_cvar.cfg; do
        if [ -e "$REPO_DIR/$item" ]; then
            cp -a "$REPO_DIR/$item" "$HLDIR/cstrike/"
        fi
    done

    cat > "$HLDIR/cstrike/autoexec.cfg" <<'CFG'
set net_master1 "ms.cs16.net:27950"
set com_protocolname "FTE-Quake"
CFG

    if [ "$PLATFORM" = "win64" ]; then
        cat > "$HLDIR/Play FreeCS.bat" <<'BAT'
@echo off
start "" "%~dp0fteqw64.exe" -game cstrike +sv_master1 "ms.cs16.net:27950"
BAT
        cat > "$HLDIR/Play FreeCS (Windowed).bat" <<'BAT'
@echo off
start "" "%~dp0fteqw64.exe" -game cstrike -window +sv_master1 "ms.cs16.net:27950"
BAT
    else
        cat > "$HLDIR/play-freecs.sh" <<'SH'
#!/bin/bash
cd "$(dirname "$0")"
./fteqw64 -game cstrike +sv_master1 "ms.cs16.net:27950" "$@"
SH
        chmod +x "$HLDIR/play-freecs.sh"
    fi

    msg "[$PLATFORM] Creating $ZIP_NAME..."
    (cd "$PKG" && zip -qr "$BUILD_DIR/$ZIP_NAME" Half-Life/)
    local SIZE
    SIZE=$(du -sh "$BUILD_DIR/$ZIP_NAME" | cut -f1)
    msg "[$PLATFORM] Done: $ZIP_NAME ($SIZE)"
}

build_package "win64" "$FTEQW_WIN64" "fteqw64.exe" "freecs-client-win64.zip"
build_package "linux64" "$FTEQW_LINUX64" "fteqw64" "freecs-client-linux64.zip"

msg ""
msg "Packages:"
ls -lh "$BUILD_DIR"/freecs-client-*.zip
