#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$REPO_DIR/build"
FTEQW_DIR="$BUILD_DIR/fteqw"
NUCLIDE_DIR="$BUILD_DIR/nuclide"
DL_DIR="$BUILD_DIR/downloads"

VALVE_PK3_URL="https://www.frag-net.com/pkgs/package_valve.pk3"
CSTRIKE_PK3_URL="https://www.frag-net.com/pkgs/package_cstrike.pk3"
CS15_URL="https://archive.org/download/counter-strike-1.5/csv15full_cstrike.zip"
GOLDSRC_URL="https://mega.nz/file/sVwBhZKK#4WfFaQUi3gSFfK0ltdqgzT36gPbUtou3tb3GUWUSSio"

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

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Build FreeCS client packages (mirrors the GitHub Actions workflow locally).

Options:
  --qc-only     Only compile QuakeC progs (skip FTEQW build, downloads, packaging)
  --no-package   Build everything but skip packaging into zips
  --help         Show this help

Environment:
  FTEQCC         Path to fteqcc binary (auto-built from FTEQW if not set)

The build/ directory caches cloned repos and downloads between runs.
EOF
    exit 0
}

QC_ONLY=0
NO_PACKAGE=0

for arg in "$@"; do
    case "$arg" in
        --qc-only)    QC_ONLY=1 ;;
        --no-package) NO_PACKAGE=1 ;;
        --help|-h)    usage ;;
        *) err "Unknown option: $arg" ;;
    esac
done

mkdir -p "$BUILD_DIR" "$DL_DIR"

# =============================================================================
# 1. Clone and patch FTEQW
# =============================================================================
if [ ! -d "$FTEQW_DIR" ]; then
    msg "Cloning FTEQW..."
    git clone --depth 1 https://github.com/fte-team/fteqw.git "$FTEQW_DIR"
fi

msg "Patching FTEQW..."
bash "$SCRIPT_DIR/patch-fteqw.sh" "$FTEQW_DIR"

# =============================================================================
# 2. Build FTEQCC
# =============================================================================
msg "Building FTEQCC..."
(cd "$FTEQW_DIR/engine" && CFLAGS="-Wno-format-truncation -Wno-stringop-truncation" make qcc-rel -j"$(nproc)")
FTEQCC="${FTEQCC:-$(find "$FTEQW_DIR/engine/release" -name 'fteqcc*' -type f -executable ! -name '*.db' 2>/dev/null | head -1)}"
[ -n "$FTEQCC" ] || err "fteqcc not found after build"
FTEQCC="$(readlink -f "$FTEQCC")"
msg "FTEQCC: $FTEQCC"

# =============================================================================
# 3. Clone pinned Nuclide + Valve
# =============================================================================
if [ ! -d "$NUCLIDE_DIR/src" ]; then
    msg "Cloning Nuclide (pinned: $NUCLIDE_COMMIT)..."
    git clone https://code.idtech.space/vera/nuclide.git "$NUCLIDE_DIR"
    (cd "$NUCLIDE_DIR" && git checkout "$NUCLIDE_COMMIT")
    msg "Cloning Valve (pinned: $VALVE_COMMIT)..."
    git clone https://code.idtech.space/fn/valve.git "$NUCLIDE_DIR/valve"
    (cd "$NUCLIDE_DIR/valve" && git checkout "$VALVE_COMMIT")
fi

msg "Patching Nuclide menu (replace frag-net with our master)..."
sed -i 's|"master.frag-net.com"|"ms.cs16.net"|' "$NUCLIDE_DIR/src/platform/master.h"
sed -i 's|tcp://irc.frag-net.com:6667|//disabled|' "$NUCLIDE_DIR/src/menu-fn/m_chatrooms.qc"
sed -i 's|http://www.frag-net.com/mods/_list.txt||' "$NUCLIDE_DIR/src/platform/modserver.qc"
sed -i 's|http://www.frag-net.com/mods/%s.fmf||' "$NUCLIDE_DIR/src/platform/modserver.qc"
sed -i 's|http://www.frag-net.com/dl/packages_%s||' "$NUCLIDE_DIR/src/platform/updates.qc"
sed -i 's|http://www.frag-net.com/dl/img/%s.jpg||' "$NUCLIDE_DIR/src/platform/updates.qc"
sed -i 's|http://www.frag-net.com/dl/%s_packages||' "$NUCLIDE_DIR/src/menu-fn/entry.qc"

# =============================================================================
# 4. Compile FreeCS QuakeC
# =============================================================================
msg "Compiling FreeCS QuakeC..."
mkdir -p "$NUCLIDE_DIR/cstrike"
if command -v rsync &>/dev/null; then
    rsync -a --delete --exclude=build/ --exclude=.git/ "$REPO_DIR/" "$NUCLIDE_DIR/cstrike/"
else
    rm -rf "$NUCLIDE_DIR/cstrike"
    mkdir -p "$NUCLIDE_DIR/cstrike"
    tar -C "$REPO_DIR" --exclude=build --exclude=.git -cf - . | tar -C "$NUCLIDE_DIR/cstrike" -xf -
fi
(cd "$NUCLIDE_DIR/cstrike/src/server" && "$FTEQCC" -I../../../src/xr/ progs.src)
(cd "$NUCLIDE_DIR/cstrike/src/client" && "$FTEQCC" -I../../../src/xr/ progs.src)
cp -f "$NUCLIDE_DIR/cstrike/progs.dat" "$NUCLIDE_DIR/cstrike/csprogs.dat" "$REPO_DIR/" 2>/dev/null || true

msg "Compiling patched menu.dat..."
mkdir -p "$NUCLIDE_DIR/platform"
(cd "$NUCLIDE_DIR/src/menu-fn" && "$FTEQCC" -I../../src/xr/ progs.src)
MENU_DAT="$NUCLIDE_DIR/platform/menu.dat"
[ -f "$MENU_DAT" ] || err "menu.dat compilation failed"

if [ "$QC_ONLY" -eq 1 ]; then
    msg "QuakeC compile complete (--qc-only)."
    ls -lh "$REPO_DIR/progs.dat" "$REPO_DIR/csprogs.dat" 2>/dev/null
    exit 0
fi

# =============================================================================
# 5. Build FTEQW client (win64 + linux64)
# =============================================================================
msg "Building FTEQW static libraries (win64)..."
(cd "$FTEQW_DIR/engine" && make makelibs FTE_TARGET=win64)
msg "Building FTEQW client (win64)..."
(cd "$FTEQW_DIR/engine" && make gl-rel FTE_TARGET=win64 -j"$(nproc)")

msg "Building FTEQW static libraries (linux64)..."
(cd "$FTEQW_DIR/engine" && make makelibs FTE_TARGET=linux64)
msg "Building FTEQW client (linux64)..."
(cd "$FTEQW_DIR/engine" && make gl-rel FTE_TARGET=linux64 -j"$(nproc)")

# =============================================================================
# 6. Download game data
# =============================================================================
download "$VALVE_PK3_URL" "$DL_DIR/package_valve.pk3"
msg "Removing upstream menu.dat from valve pk3 (replaced by our patched build)..."
zip -qd "$DL_DIR/package_valve.pk3" menu.dat 2>/dev/null || true
download "$CSTRIKE_PK3_URL" "$DL_DIR/package_cstrike.pk3"
download "$CS15_URL" "$DL_DIR/cs15data.zip"

if [ ! -f "$DL_DIR/valve-data.pk3" ]; then
    GSRC_7Z=$(find "$DL_DIR" -name "GoldSrc*" -print -quit)
    if [ -z "$GSRC_7Z" ]; then
        msg "Downloading HL1 valve data (GoldSrc Package)..."
        megadl "$GOLDSRC_URL" --path "$DL_DIR/"
        GSRC_7Z=$(find "$DL_DIR" -name "GoldSrc*" -print -quit)
        [ -n "$GSRC_7Z" ] || err "GoldSrc download failed"
    else
        msg "GoldSrc 7z already present, extracting..."
    fi
    7z x -o"$BUILD_DIR/tmp/goldsrc" "$GSRC_7Z" \
        "Half-Life WON/valve/models/" "Half-Life WON/valve/sound/" \
        "Half-Life WON/valve/sprites/" "Half-Life WON/valve/*.wad" -y
    (cd "$BUILD_DIR/tmp/goldsrc/Half-Life WON/valve" && \
        zip -qr "$DL_DIR/valve-data.pk3" models/ sound/ sprites/ *.wad)
    rm -rf "$BUILD_DIR/tmp/goldsrc"
fi

if [ "$NO_PACKAGE" -eq 1 ]; then
    msg "Build complete (--no-package)."
    exit 0
fi

# =============================================================================
# 7. Package
# =============================================================================
build_package() {
    local PLATFORM="$1" EXE_SRC="$2" EXE_NAME="$3"
    local PKG="$BUILD_DIR/pkg-$PLATFORM/Half-Life"

    rm -rf "$BUILD_DIR/pkg-$PLATFORM"
    mkdir -p "$PKG/valve" "$PKG/cstrike"

    cp -f "$EXE_SRC" "$PKG/$EXE_NAME"
    chmod +x "$PKG/$EXE_NAME"

    cp -f "$DL_DIR/package_valve.pk3" "$PKG/valve/"
    cp -f "$DL_DIR/valve-data.pk3" "$PKG/valve/" 2>/dev/null || true
    cp -f "$NUCLIDE_DIR/platform/menu.dat" "$PKG/valve/menu.dat"
    cp -f "$DL_DIR/package_cstrike.pk3" "$PKG/cstrike/"
    cp -f "$DL_DIR/cs15data.zip" "$PKG/cstrike/pak0.pk3"

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

    for item in cfg data decls fonts gfx maps particles progs resource scripts \
                progs.dat csprogs.dat hud.dat quake.rc icon.tga \
                default_aliases.cfg default_cstrike.cfg default_cvar.cfg; do
        [ -e "$REPO_DIR/$item" ] && cp -a "$REPO_DIR/$item" "$PKG/cstrike/"
    done

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

    (cd "$BUILD_DIR/pkg-$PLATFORM" && zip -qr "$BUILD_DIR/freecs-client-$PLATFORM.zip" Half-Life/)
    msg "Built freecs-client-$PLATFORM.zip ($(du -sh "$BUILD_DIR/freecs-client-$PLATFORM.zip" | cut -f1))"
}

WIN_EXE="$(find "$FTEQW_DIR/engine/release" -maxdepth 1 -name "*.exe" ! -name "*.db" ! -name "*sv*" 2>/dev/null | head -1)"
LIN_EXE="$(find "$FTEQW_DIR/engine/release" -maxdepth 1 -type f -executable ! -name "*.exe" ! -name "*.db" ! -name "*sv*" ! -name "*.o" 2>/dev/null | head -1)"

[ -n "$WIN_EXE" ] && build_package "win64" "$WIN_EXE" "fteqw64.exe"
[ -n "$LIN_EXE" ] && build_package "linux64" "$LIN_EXE" "fteqw64"

msg ""
msg "Done! Packages:"
ls -lh "$BUILD_DIR"/freecs-client-*.zip 2>/dev/null
