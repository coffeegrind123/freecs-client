#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$REPO_DIR/build"
FTEQW_DIR="$BUILD_DIR/fteqw"

VALVE_PK3_URL="https://www.frag-net.com/pkgs/package_valve.pk3"
CSTRIKE_PK3_URL="https://www.frag-net.com/pkgs/package_cstrike.pk3"
CS15_URL="https://archive.org/download/counter-strike-1.5/csv15full_cstrike.zip"
GOLDSRC_URL="https://mega.nz/file/sVwBhZKK#4WfFaQUi3gSFfK0ltdqgzT36gPbUtou3tb3GUWUSSio"

# Pinned versions matching the working pre-compiled pk3 (March 2024)
NUCLIDE_COMMIT="a9ededfd"
VALVE_COMMIT="9272244"

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

# --- 1. Clone and patch FTEQW ---
if [ ! -d "$FTEQW_DIR" ]; then
    msg "Cloning FTEQW..."
    git clone --depth 1 https://github.com/fte-team/fteqw.git "$FTEQW_DIR"
fi

msg "Patching FTEQW..."
bash "$SCRIPT_DIR/patch-fteqw.sh" "$FTEQW_DIR"

# --- 2. Build FTEQCC ---
msg "Building FTEQCC..."
(cd "$FTEQW_DIR/engine" && CFLAGS="-Wno-format-truncation -Wno-stringop-truncation" make qcc-rel -j"$(nproc)")
FTEQCC="$(find "$FTEQW_DIR/engine/release" -name 'fteqcc*' -type f -executable ! -name '*.db' | head -1)"
[ -n "$FTEQCC" ] || err "fteqcc not found after build"
FTEQCC="$(readlink -f "$FTEQCC")"
msg "FTEQCC: $FTEQCC"

# --- 3. Build FTEQW client (win64 + linux64) ---
msg "Building FTEQW static libraries (win64)..."
(cd "$FTEQW_DIR/engine" && make makelibs FTE_TARGET=win64)
msg "Building FTEQW client (win64)..."
(cd "$FTEQW_DIR/engine" && make gl-rel FTE_TARGET=win64 -j"$(nproc)")

msg "Building FTEQW static libraries (linux64)..."
(cd "$FTEQW_DIR/engine" && make makelibs FTE_TARGET=linux64)
msg "Building FTEQW client (linux64)..."
(cd "$FTEQW_DIR/engine" && make gl-rel FTE_TARGET=linux64 -j"$(nproc)")

# --- 4. Clone pinned Nuclide + Valve ---
NUCLIDE_DIR="$BUILD_DIR/nuclide"
if [ ! -d "$NUCLIDE_DIR/src" ]; then
    msg "Cloning Nuclide (pinned: $NUCLIDE_COMMIT)..."
    git clone https://code.idtech.space/vera/nuclide.git "$NUCLIDE_DIR"
    (cd "$NUCLIDE_DIR" && git checkout "$NUCLIDE_COMMIT")
    msg "Cloning Valve (pinned: $VALVE_COMMIT)..."
    git clone https://code.idtech.space/fn/valve.git "$NUCLIDE_DIR/valve"
    (cd "$NUCLIDE_DIR/valve" && git checkout "$VALVE_COMMIT")
fi

# --- 5. Compile FreeCS QuakeC ---
msg "Compiling FreeCS QuakeC..."
mkdir -p "$NUCLIDE_DIR/cstrike"
rsync -a --exclude=build/ --exclude=.git/ "$REPO_DIR/" "$NUCLIDE_DIR/cstrike/"
(cd "$NUCLIDE_DIR/cstrike/src/server" && "$FTEQCC" -I../../../src/xr/ progs.src)
(cd "$NUCLIDE_DIR/cstrike/src/client" && "$FTEQCC" -I../../../src/xr/ progs.src)

# --- 6. Download game data ---
DL_DIR="$BUILD_DIR/downloads"
download "$VALVE_PK3_URL" "$DL_DIR/package_valve.pk3"
download "$CSTRIKE_PK3_URL" "$DL_DIR/package_cstrike.pk3"
download "$CS15_URL" "$DL_DIR/cs15data.zip"

if [ ! -f "$DL_DIR/valve-data.pk3" ]; then
    msg "Downloading HL1 valve data (GoldSrc Package)..."
    megadl "$GOLDSRC_URL" --path "$DL_DIR/"
    GSRC_7Z=$(find "$DL_DIR" -name "GoldSrc*" -print -quit)
    [ -n "$GSRC_7Z" ] || err "GoldSrc download failed"
    7z x -o"$BUILD_DIR/tmp/goldsrc" "$GSRC_7Z" "Half-Life WON/valve/models/" "Half-Life WON/valve/sound/" "Half-Life WON/valve/sprites/" "Half-Life WON/valve/*.wad" -y
    (cd "$BUILD_DIR/tmp/goldsrc/Half-Life WON/valve" && zip -qr "$DL_DIR/valve-data.pk3" models/ sound/ sprites/ *.wad)
    rm -rf "$BUILD_DIR/tmp/goldsrc" "$GSRC_7Z"
fi

# --- 7. Package ---
build_package() {
    local PLATFORM="$1" EXE_SRC="$2" EXE_NAME="$3" ZIP_NAME="$4"
    local PKG="$BUILD_DIR/pkg-$PLATFORM/Half-Life"

    rm -rf "$BUILD_DIR/pkg-$PLATFORM"
    mkdir -p "$PKG/valve" "$PKG/cstrike"

    cp -f "$EXE_SRC" "$PKG/$EXE_NAME"
    chmod +x "$PKG/$EXE_NAME"

    cp -f "$DL_DIR/package_valve.pk3" "$PKG/valve/"
    cp -f "$DL_DIR/valve-data.pk3" "$PKG/valve/" 2>/dev/null || true
    cp -f "$DL_DIR/package_cstrike.pk3" "$PKG/cstrike/"
    cp -f "$DL_DIR/cs15data.zip" "$PKG/cstrike/pak0.pk3"

    # Compiled progs
    cp -f "$NUCLIDE_DIR/cstrike/progs.dat" "$PKG/cstrike/" 2>/dev/null || true
    cp -f "$NUCLIDE_DIR/cstrike/csprogs.dat" "$PKG/cstrike/" 2>/dev/null || true

    cat > "$PKG/valve/liblist.gam" <<'LIBLIST'
game "Half-Life"
startmap "c0a0"
mpentity "info_player_deathmatch"
gamedll_linux "dlls/hl.so"
gamedll "dlls/hl.dll"
cldll "1"
LIBLIST

    # FreeCS repo data
    for item in cfg data decls fonts gfx maps particles progs resource scripts \
                progs.dat csprogs.dat hud.dat quake.rc icon.tga \
                default_aliases.cfg default_cstrike.cfg default_cvar.cfg; do
        [ -e "$REPO_DIR/$item" ] && cp -a "$REPO_DIR/$item" "$PKG/cstrike/"
    done

    # Nuclide configs (fallback to valve/default.cfg for old Nuclide)
    cp -f "$NUCLIDE_DIR/base/default_controls.cfg" "$PKG/cstrike/" 2>/dev/null || true
    cp -f "$NUCLIDE_DIR/base/default_video.cfg" "$PKG/cstrike/" 2>/dev/null || true
    cp -f "$NUCLIDE_DIR/valve/default_valve.cfg" "$PKG/cstrike/" 2>/dev/null || true
    cp -f "$NUCLIDE_DIR/valve/default.cfg" "$PKG/cstrike/default_controls.cfg" 2>/dev/null || true

    cat > "$PKG/cstrike/autoexec.cfg" <<'CFG'
set net_master1 "ms.cs16.net:27950"
set com_protocolname "FTE-Quake"
CFG

    if [ "$PLATFORM" = "win64" ]; then
        printf '@echo off\r\nstart "" "%%~dp0fteqw64.exe" -game cstrike +sv_master1 "ms.cs16.net:27950"\r\n' > "$PKG/Play FreeCS.bat"
        printf '@echo off\r\nstart "" "%%~dp0fteqw64.exe" -game cstrike -window +sv_master1 "ms.cs16.net:27950"\r\n' > "$PKG/Play FreeCS (Windowed).bat"
    else
        printf '#!/bin/bash\ncd "$(dirname "$0")"\n./fteqw64 -game cstrike +sv_master1 "ms.cs16.net:27950" "$@"\n' > "$PKG/play-freecs.sh"
        chmod +x "$PKG/play-freecs.sh"
    fi

    (cd "$BUILD_DIR/pkg-$PLATFORM" && zip -qr "$REPO_DIR/freecs-client-$PLATFORM.zip" Half-Life/)
    msg "Built freecs-client-$PLATFORM.zip ($(du -sh "$REPO_DIR/freecs-client-$PLATFORM.zip" | cut -f1))"
}

WIN_EXE="$(find "$FTEQW_DIR/engine/release" -name "fteglqw64.exe" -o -name "fteqw64.exe" 2>/dev/null | head -1)"
LIN_EXE="$(find "$FTEQW_DIR/engine/release" -maxdepth 1 -type f -executable ! -name "*.exe" ! -name "*.db" ! -name "*sv*" ! -name "*.o" 2>/dev/null | head -1)"

[ -n "$WIN_EXE" ] && build_package "win64" "$WIN_EXE" "fteqw64.exe" "freecs-client-win64.zip"
[ -n "$LIN_EXE" ] && build_package "linux64" "$LIN_EXE" "fteqw64" "freecs-client-linux64.zip"

msg ""
msg "Done! Packages:"
ls -lh "$REPO_DIR"/freecs-client-*.zip 2>/dev/null
