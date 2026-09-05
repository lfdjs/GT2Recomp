#!/usr/bin/env bash
set -Eeuo pipefail

die() {
    echo "ERRO: $*" >&2
    exit 1
}

usage() {
    cat <<'EOF_USAGE'
GT2Recomp - Native Linux baseline

Uso:

  ./tools-linux/setup_gt2.sh [--install-deps] /pasta/com/os/discos

Exemplos:

  ./tools-linux/setup_gt2.sh --install-deps "$HOME/Games/GT2"

  ./tools-linux/setup_gt2.sh "$HOME/Games/GT2"

Opções:

  --install-deps
      Instala dependências via apt em Debian/Ubuntu.

  -h, --help
      Mostra esta ajuda.

Variáveis:

  GT2_JOBS=N

  GT2_LINUX_INSTALL_DIR=/caminho

Relatório de auditoria:

  .audit/latest-linux-build.log
EOF_USAGE
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$SRC"

mkdir -p .audit

STAMP="$(date '+%Y%m%d-%H%M%S')"

REPORT="$SRC/.audit/linux-build-$STAMP.log"
LATEST="$SRC/.audit/latest-linux-build.log"

touch "$REPORT"

ln -sfn "$(basename "$REPORT")" "$LATEST"

exec > >(tee -a "$REPORT") 2>&1

build_audit_snapshot() {

    echo
    echo "---------------- AUDITORIA BUILD LINUX ----------------"

    echo "Data: $(date --iso-8601=seconds 2>/dev/null || date)"

    echo "Repo: $SRC"

    echo "Branch: $(git branch --show-current 2>/dev/null || true)"

    echo "HEAD: $(git rev-parse HEAD 2>/dev/null || true)"

    echo "Kernel: $(uname -a)"

    echo "CMake: $(cmake --version 2>/dev/null | head -1 || true)"

    echo "Ninja: $(ninja --version 2>/dev/null || true)"

    echo "GCC: $(gcc --version 2>/dev/null | head -1 || true)"

    echo "Python: $(python3 --version 2>/dev/null || true)"

    echo
    echo "git status --short:"

    git status --short 2>/dev/null || true

    echo
    echo "Relatório:"

    echo "  $REPORT"

    echo "--------------------------------------------------------"
}

on_error() {

    rc=$?

    cmd="${BASH_COMMAND:-desconhecido}"

    trap - ERR

    echo
    echo "======================================================================"
    echo " FALHA NO BUILD LINUX"
    echo "======================================================================"

    echo "Código de saída: $rc"

    echo "Comando: $cmd"

    echo "BUILD_STATUS=FAIL"

    build_audit_snapshot

    echo
    echo "Para me enviar a auditoria:"
    echo
    echo "  cat .audit/latest-linux-build.log"
    echo

    exit "$rc"
}

trap on_error ERR

INSTALL_DEPS=0
GAME_DIR=""

while [ "$#" -gt 0 ]; do

    case "$1" in

        --install-deps)

            INSTALL_DEPS=1
            shift
            ;;

        -h|--help)

            usage
            exit 0
            ;;

        --*)

            die "opção desconhecida: $1"
            ;;

        *)

            [ -z "$GAME_DIR" ] \
                || die "informe apenas uma pasta com os discos."

            GAME_DIR="$1"

            shift
            ;;

    esac

done

[ -n "$GAME_DIR" ] || {
    usage
    exit 2
}

[ "$(uname -s)" = Linux ] \
    || die "este script é exclusivo do Linux."

# ===========================================================================
# Dependências
# ===========================================================================

if [ "$INSTALL_DEPS" = 1 ]; then

    command -v apt-get >/dev/null 2>&1 \
        || die "--install-deps requer Debian/Ubuntu nesta etapa."

    SUDO=""

    if [ "$(id -u)" -ne 0 ]; then

        command -v sudo >/dev/null 2>&1 \
            || die "sudo não encontrado."

        SUDO=sudo

    fi

    echo
    echo "== Instalando dependências =="

    $SUDO apt-get update

    $SUDO apt-get install -y \
        build-essential \
        cmake \
        ninja-build \
        git \
        python3 \
        pkg-config \
        libgl-dev \
        libx11-dev \
        libxext-dev

fi

for cmd in \
    git \
    cmake \
    ninja \
    python3 \
    gcc \
    g++ \
    stat \
    realpath \
    find \
    grep \
    sed \
    sort \
    tee
do

    command -v "$cmd" >/dev/null 2>&1 \
        || die "dependência ausente: $cmd"

done

GAME_DIR="$(realpath "$GAME_DIR")"

[ -d "$GAME_DIR" ] \
    || die "pasta inexistente: $GAME_DIR"

INSTALL_DIR="${GT2_LINUX_INSTALL_DIR:-$GAME_DIR/GT2Recomp-linux}"

mkdir -p "$INSTALL_DIR"

INSTALL_DIR="$(realpath "$INSTALL_DIR")"

JOBS="${GT2_JOBS:-$(nproc)}"

echo
echo "======================================================================"
echo " GT2Recomp - Native Linux build"
echo "======================================================================"
echo
echo "Source : $SRC"
echo "Games  : $GAME_DIR"
echo "Install: $INSTALL_DIR"
echo "Jobs   : $JOBS"
echo "Log    : $REPORT"
echo

if ! command -v glslc >/dev/null 2>&1; then

    echo "INFO: glslc não encontrado."
    echo "      OpenGL será usado como baseline."

fi

# ===========================================================================
# 1/7 - Submódulos e patches
# ===========================================================================

echo
echo "== 1/7 Submódulos e patch stack =="

for sm in psxrecomp recomp-ui; do

    if [ -e "$SRC/$sm/.git" ]; then

        git -C "$SRC/$sm" reset --hard -q

        git -C "$SRC/$sm" clean -fdq

    fi

done

git submodule update \
    --init \
    --recursive \
    --force \
    --depth 1 \
|| \
git submodule update \
    --init \
    --recursive \
    --force

apply_patch_file() {

    repo="$1"
    patch="$2"

    if git -C "$repo" apply --check "$patch" 2>/dev/null; then

        git -C "$repo" apply "$patch"

        echo "  + $(basename "$patch")"

    elif git -C "$repo" apply \
        --reverse \
        --check \
        "$patch" \
        2>/dev/null
    then

        echo "  = $(basename "$patch") (já aplicado)"

    else

        die "patch não aplica: $patch"

    fi
}

mapfile -t PSX_PATCHES < <(

    {

        find \
            "$SRC/patches/upstream" \
            -maxdepth 1 \
            -type f \
            -name '*.patch' \
            -print \
            2>/dev/null

        find \
            "$SRC/patches" \
            -maxdepth 1 \
            -type f \
            -name 'psxrecomp-*.patch' \
            -print \
            2>/dev/null

    } | LC_ALL=C sort

)

[ "${#PSX_PATCHES[@]}" -gt 0 ] \
    || die "nenhum patch psxrecomp encontrado."

echo
echo "-- psxrecomp --"

for patch in "${PSX_PATCHES[@]}"; do

    apply_patch_file \
        "$SRC/psxrecomp" \
        "$patch"

done

mapfile -t UI_PATCHES < <(

    find \
        "$SRC/patches/recomp-ui" \
        -maxdepth 1 \
        -type f \
        -name '*.patch' \
        -print \
        2>/dev/null \
    | LC_ALL=C sort

)

[ "${#UI_PATCHES[@]}" -gt 0 ] \
    || die "nenhum patch recomp-ui encontrado."

echo
echo "-- recomp-ui --"

for patch in "${UI_PATCHES[@]}"; do

    apply_patch_file \
        "$SRC/recomp-ui" \
        "$patch"

done

# ===========================================================================
# 2/7 - Recompiler
# ===========================================================================

echo
echo "== 2/7 Compilando psxrecomp-game =="

RECOMPILER_BUILD="$SRC/psxrecomp/recompiler/build-linux"

cmake \
    -S "$SRC/psxrecomp/recompiler" \
    -B "$RECOMPILER_BUILD" \
    -G Ninja \
    -DCMAKE_BUILD_TYPE=Release

cmake \
    --build "$RECOMPILER_BUILD" \
    --target psxrecomp-game \
    -j "$JOBS"

RECOMPILER="$RECOMPILER_BUILD/psxrecomp-game"

[ -x "$RECOMPILER" ] \
    || die "psxrecomp-game não foi gerado."

PY=python3

PROBE="$SRC/psxrecomp/tools/new_project_layout/probe_disc.py"

[ -f "$PROBE" ] \
    || die "probe_disc.py não encontrado."

# ===========================================================================
# 3/7 - Detectar discos
# ===========================================================================

echo
echo "== 3/7 Detectando discos =="

declare -A DISC_BIN
declare -A DISC_CUE

cue_for_bin() {

    bin="$1"

    cue="${bin%.*}.cue"

    bname="$(basename "$bin")"

    if [ ! -f "$cue" ] \
        || ! grep -qF "$bname" "$cue" 2>/dev/null
    then

        if [ -f "$cue" ]; then

            cp -f \
                "$cue" \
                "$cue.bak"

            echo \
                "  corrigindo $(basename "$cue")" \
                >&2

        else

            echo \
                "  criando $(basename "$cue")" \
                >&2

        fi

        printf \
            'FILE "%s" BINARY\r\n  TRACK 01 MODE2/2352\r\n    INDEX 01 00:00:00\r\n' \
            "$bname" \
            > "$cue"

    fi

    printf '%s' "$cue"
}

while IFS= read -r -d '' bin; do

    size="$(stat -c '%s' "$bin")"

    [ "$size" -gt 400000000 ] \
        || continue

    cue="$(cue_for_bin "$bin")"

    identity_json="$(mktemp)"

    if ! "$PY" \
        "$PROBE" \
        --identity-only \
        --json-out "$identity_json" \
        "$cue" \
        >/dev/null 2>&1
    then

        echo \
            "  ignorando $(basename "$bin"): imagem PS1 não reconhecida"

        rm -f "$identity_json"

        continue

    fi

    serial="$(
        "$PY" - "$identity_json" <<'PY_SERIAL'
import json
import sys

try:
    with open(sys.argv[1], "r", encoding="utf-8") as f:
        data = json.load(f)

    print(data.get("serial") or "")

except Exception:
    print("")
PY_SERIAL
    )"

    rm -f "$identity_json"

    title=""

    case "$serial" in

        SCUS-94455)

            title=arcade
            ;;

        SCUS-94488)

            if [ "$size" -ge 1000000000 ]; then

                title=combined

            else

                title=simulation

            fi
            ;;

        *)

            echo \
                "  ignorando $(basename "$bin"): serial '${serial:-desconhecido}'"
            ;;

    esac

    [ -n "$title" ] \
        || continue

    if [ -n "${DISC_BIN[$title]:-}" ]; then

        echo \
            "  $title já detectado; mantendo $(basename "${DISC_BIN[$title]}")"

        continue

    fi

    DISC_BIN[$title]="$bin"

    DISC_CUE[$title]="$cue"

    echo \
        "  $(basename "$bin") -> $title ($serial)"

done < <(

    find \
        "$GAME_DIR" \
        -maxdepth 1 \
        -type f \
        -iname '*.bin' \
        -print0

)

TITLES=()

for title in arcade simulation combined; do

    [ -n "${DISC_BIN[$title]:-}" ] \
        && TITLES+=("$title")

done

[ "${#TITLES[@]}" -gt 0 ] \
    || die "nenhum disco GT2 compatível encontrado em $GAME_DIR"

echo
echo "Títulos encontrados:"

printf '  - %s\n' "${TITLES[@]}"

# ===========================================================================
# 4/7 - BIOS
# ===========================================================================

echo
echo "== 4/7 Preparando BIOS =="

for bios in \
    "$GAME_DIR/scph1001.bin" \
    "$GAME_DIR/SCPH1001.BIN" \
    "$GAME_DIR/bios/scph1001.bin" \
    "$GAME_DIR/bios/SCPH1001.BIN"
do

    if [ -f "$bios" ]; then

        cp -f \
            "$bios" \
            "$SRC/psxrecomp/bios/SCPH1001.BIN"

        echo \
            "BIOS retail encontrada: $bios"

        break

    fi

done

(

    cd "$SRC/psxrecomp"

    bash \
        tools/regen_bios.sh \
        --config bios/OpenBIOS.toml

    if [ -f bios/SCPH1001.BIN ]; then

        bash \
            tools/regen_bios.sh \
            --config bios/SCPH1001.toml

    fi

)

# ===========================================================================
# 5/7 - Recompilar e compilar
# ===========================================================================

echo
echo "== 5/7 Recompilando títulos =="

mkdir -p \
    "$INSTALL_DIR/titles" \
    "$INSTALL_DIR/saves" \
    "$INSTALL_DIR/mods"

for title in "${TITLES[@]}"; do

    TDIR="$SRC/titles/$title"

    BDIR="$TDIR/build-linux"

    case "$title" in

        arcade)
            label=Arcade
            ;;

        simulation)
            label=Simulation
            ;;

        combined)
            label=Combined
            ;;

    esac

    echo
    echo "------------------------------------------------------------"
    echo " $label"
    echo "------------------------------------------------------------"

    mkdir -p \
        "$TDIR/disc" \
        "$TDIR/bios"

    canon_bin="$(
        grep -m1 '^bin_name' "$TDIR/game.toml" \
        | sed 's/.*= *"\(.*\)"/\1/'
    )"

    canon_cue="$(
        grep -m1 '^cue_name' "$TDIR/game.toml" \
        | sed 's/.*= *"\(.*\)"/\1/'
    )"

    [ -n "$canon_bin" ] \
        || die "bin_name ausente em $TDIR/game.toml"

    [ -n "$canon_cue" ] \
        || die "cue_name ausente em $TDIR/game.toml"

    rm -f \
        "$TDIR/disc/$canon_bin"

    if ! ln \
        "${DISC_BIN[$title]}" \
        "$TDIR/disc/$canon_bin" \
        2>/dev/null
    then

        ln -s \
            "$(realpath "${DISC_BIN[$title]}")" \
            "$TDIR/disc/$canon_bin"

    fi

    printf \
        'FILE "%s" BINARY\r\n  TRACK 01 MODE2/2352\r\n    INDEX 01 00:00:00\r\n' \
        "$canon_bin" \
        > "$TDIR/disc/$canon_cue"

    cp -f \
        "$SRC/psxrecomp/bios/SCPH1001.toml" \
        "$SRC/psxrecomp/bios/OpenBIOS.toml" \
        "$TDIR/bios/"

    echo
    echo "  extraindo PS-EXE..."

    "$PY" \
        "$PROBE" \
        --identity-only \
        --write-boot-exe "$TDIR/disc" \
        "${DISC_CUE[$title]}" \
        >/dev/null

    exe_rel="$(
        grep -m1 '^exe' "$TDIR/game.toml" \
        | sed 's/.*= *"\(.*\)"/\1/'
    )"

    [ -n "$exe_rel" ] \
        || die "exe ausente em $TDIR/game.toml"

    [ -f "$TDIR/$exe_rel" ] \
        || die "PS-EXE não foi extraído: $TDIR/$exe_rel"

    exe_base="$(basename "$exe_rel")"

    dispatch="$TDIR/generated/${exe_base}_dispatch.c"

    if [ -f "$dispatch" ] \
        && [ "$dispatch" -nt "$TDIR/$exe_rel" ] \
        && [ "$dispatch" -nt "$TDIR/seeds/ghidra_funcs.txt" ] \
        && [ "$dispatch" -nt "$RECOMPILER" ]
    then

        echo \
            "  generated/ já está atualizado"

    else

        echo
        echo "  convertendo MIPS -> C..."
        echo

        (

            cd "$TDIR"

            "$RECOMPILER" \
                --config game.toml \
                2>&1 \
            | tee generate.log

        )

    fi

    echo
    echo "  configurando CMake..."

    cmake \
        -S "$TDIR" \
        -B "$BDIR" \
        -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DPSXRECOMP_ROOT="$SRC/psxrecomp" \
        -DPSX_RECOMP_UI=ON \
        -DRECOMP_UI_ROOT="$SRC/recomp-ui" \
        -DPSX_PGXP_VARIANT=ON \
        -DPSX_DEBUG_TOOLS=ON \
        -DPSX_EXPANDED_RAM=ON

    echo
    echo "  compilando runtime..."

    cmake \
        --build "$BDIR" \
        --target psx-runtime-pgxp \
        -j "$JOBS"

    built=""

    for candidate in "$BDIR/"*_pgxp; do

        if [ -f "$candidate" ] \
            && [ -x "$candidate" ]
        then

            built="$candidate"

            break

        fi

    done

    [ -n "$built" ] \
        || die "runtime Linux não encontrado em $BDIR"

    D="$INSTALL_DIR/titles/$title"

    mkdir -p \
        "$D/bios" \
        "$D/extracted" \
        "$D/seeds"

    runtime_name="$(basename "$built")"

    cp -f \
        "$built" \
        "$D/$runtime_name"

    chmod +x \
        "$D/$runtime_name"

    install_bin_name="gt2-${title}.bin"

    install_cue_name="gt2-${title}.cue"

    rm -f \
        "$INSTALL_DIR/$install_bin_name"

    if ! ln \
        "${DISC_BIN[$title]}" \
        "$INSTALL_DIR/$install_bin_name" \
        2>/dev/null
    then

        ln -s \
            "$(realpath "${DISC_BIN[$title]}")" \
            "$INSTALL_DIR/$install_bin_name"

    fi

    printf \
        'FILE "%s" BINARY\r\n  TRACK 01 MODE2/2352\r\n    INDEX 01 00:00:00\r\n' \
        "$install_bin_name" \
        > "$INSTALL_DIR/$install_cue_name"

    sed \
        "s|__DISC_CUE__|$install_cue_name|g" \
        "$TDIR/game.runtime.toml" \
        > "$D/game.toml"

    cp -f \
        "$TDIR/seeds/ghidra_funcs.txt" \
        "$D/seeds/ghidra_funcs.txt"

    cp -f \
        "$TDIR/$exe_rel" \
        "$D/extracted/$(basename "$exe_rel")"

    cp -f \
        "$SRC/psxrecomp/bios/openbios.bin" \
        "$SRC/psxrecomp/bios/OpenBIOS.LICENSE" \
        "$SRC/psxrecomp/bios/SCPH1001.toml" \
        "$SRC/psxrecomp/bios/OpenBIOS.toml" \
        "$D/bios/"

    if [ -f "$SRC/psxrecomp/bios/SCPH1001.BIN" ]; then

        cp -f \
            "$SRC/psxrecomp/bios/SCPH1001.BIN" \
            "$D/bios/SCPH1001.BIN"

    fi

    if [ -d "$BDIR/assets" ]; then

        rm -rf \
            "$D/assets"

        cp -a \
            "$BDIR/assets" \
            "$D/"

    fi

    if [ -d "$BDIR/mods" ]; then

        cp -a \
            "$BDIR/mods/." \
            "$INSTALL_DIR/mods/"

    fi

    # -----------------------------------------------------------------------
    # Artwork extraído somente do disco local do usuário.
    # -----------------------------------------------------------------------

    if [ -d "$D/assets/img" ]; then

        "$PY" \
            "$SRC/tools/rip_gt2_title_art.py" \
            "${DISC_BIN[$title]}" \
            "$D/assets/img/boxart.tga" \
            >/dev/null 2>&1 \
            || true

        "$PY" \
            "$SRC/tools/rip_gt2_launcher_art.py" \
            "${DISC_BIN[$title]}" \
            "$D/assets/img/gt2" \
            --quiet \
            >/dev/null 2>&1 \
            || true

    fi

    RUNNER="$INSTALL_DIR/run-${title}.sh"

    cat > "$RUNNER" <<EOF_RUNNER
#!/usr/bin/env bash
set -Eeuo pipefail

HERE="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"

cd "\$HERE/titles/$title"

# Milestone 1:
# desativa temporariamente a compilação dinâmica de overlays.
export PSX_OVERLAY_AUTOCOMPILE_OFF="\${PSX_OVERLAY_AUTOCOMPILE_OFF:-1}"

exec "./$runtime_name" "\$@"
EOF_RUNNER

    chmod +x \
        "$RUNNER"

    echo
    echo "  launcher:"
    echo "    $RUNNER"

done

# ===========================================================================
# 6/7 - Resumo da instalação
# ===========================================================================

echo
echo "== 6/7 Gerando resumo da instalação =="

{

    echo "GT2Recomp - Native Linux baseline"

    echo

    echo "Source:"
    echo "  $SRC"

    echo

    echo "Install:"
    echo "  $INSTALL_DIR"

    echo

    echo "Títulos:"

    for title in "${TITLES[@]}"; do

        echo "  - $title"

    done

    echo

    echo "Executar:"

    for title in "${TITLES[@]}"; do

        echo "  ./run-${title}.sh"

    done

    echo

    echo "Overlay auto-compile: desativado neste baseline."

    echo

    echo "Próximo marco:"

    echo "  native overlay cache + static/AOT overlays"

} > "$INSTALL_DIR/README-LINUX.txt"

# ===========================================================================
# 7/7 - Auditoria
# ===========================================================================

echo
echo "== 7/7 Auditoria final =="

for title in "${TITLES[@]}"; do

    [ -x "$INSTALL_DIR/run-${title}.sh" ] \
        || die "launcher não foi criado: run-${title}.sh"

done

echo
echo "BUILD_STATUS=SUCCESS"

echo
echo "Instalação criada em:"
echo
echo "  $INSTALL_DIR"

build_audit_snapshot

trap - ERR

echo
echo "======================================================================"
echo " BUILD LINUX CONCLUÍDO"
echo "======================================================================"
echo
echo "Para me enviar o relatório:"
echo
echo "  cat .audit/latest-linux-build.log"
echo

