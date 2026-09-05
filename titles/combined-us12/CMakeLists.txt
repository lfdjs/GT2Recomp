cmake_minimum_required(VERSION 3.20)

set(
    PSXRECOMP_ROOT
    "${CMAKE_CURRENT_SOURCE_DIR}/../../psxrecomp"
    CACHE PATH
    "Path to psxrecomp"
)

if(NOT EXISTS "${PSXRECOMP_ROOT}/runtime/runtime.cmake")

    message(
        FATAL_ERROR
        "PSXRecomp runtime missing: ${PSXRECOMP_ROOT}/runtime/runtime.cmake"
    )

endif()

project(
    GT2CombinedUS12Recomp
    LANGUAGES C CXX
)

# GT2_US12_OPENBIOS_ONLY
#
# This experimental baseline intentionally links only the redistributable
# OpenBIOS backend. The game's codegen uses the same BIOS address model.
set(
    PSXRECOMP_BIOS_STEMS
    "OpenBIOS"
    CACHE STRING
    "BIOS backends linked by Combined US 1.2 baseline"
    FORCE
)

include(
    "${PSXRECOMP_ROOT}/runtime/runtime.cmake"
)

# Experimental clean baseline for Combined Disc based on NTSC-U 1.2.
#
# Deliberadamente NÃO inclui:
#
#   mods_gt2_silent.c
#   mods_gt2_recomp.c
#   gt2_career.c
#   gameshark_vm.c
#
# Esses componentes continuam validados contra NTSC-U 1.1.

psxrecomp_add_game_runtime(
    psx-runtime

    WINDOW_TITLE
        "Gran Turismo 2 Combined US 1.2 Recompiled"

    DEFAULT_GAME_CONFIG_PATH
        "game.toml"

    MAX_PLAYERS
        2

    GEN_MARKER
        "generated/SCUS_944.88_dispatch.c"

    GEN_FULL_GLOB
        "generated/SCUS_944.88_full_*.c"

    CODEGEN_SETUP_SOURCES
        codegen_setup.c

    CODEGEN_SETUP_INCLUDE_DIR
        "${CMAKE_CURRENT_SOURCE_DIR}"
)

foreach(_rt psx-runtime psx-runtime-pgxp)

    if(TARGET ${_rt})

        add_custom_command(
            TARGET ${_rt}
            POST_BUILD

            COMMAND
                ${CMAKE_COMMAND}
                -E
                copy_if_different
                "${CMAKE_CURRENT_SOURCE_DIR}/game.toml"
                "$<TARGET_FILE_DIR:${_rt}>/game.toml"

            VERBATIM
        )

    endif()

endforeach()
