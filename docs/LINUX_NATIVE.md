# Native Linux baseline

This fork is establishing Linux as a first-class native target before adding
console backends.

The upstream source already supports native Linux development. This fork adds
a reproducible Linux setup workflow without Wine, Proton, PowerShell or MSYS2.

## Usage

On Debian/Ubuntu:

    ./tools-linux/setup_gt2.sh --install-deps /path/to/GT2

Later runs:

    ./tools-linux/setup_gt2.sh /path/to/GT2

The default installation is:

    /path/to/GT2/GT2Recomp-linux/

## Audit reports

Bootstrap report:

    .audit/latest-bootstrap.log

Native Linux build report:

    .audit/latest-linux-build.log

Both success and failure paths write an audit report intended to make remote
debugging reproducible.

## Milestone 1

The workflow:

1. restores and updates pinned submodules;
2. applies the GT2Recomp patch stack;
3. builds psxrecomp-game natively;
4. identifies supported user-owned GT2 disc images;
5. creates or repairs CUE metadata when needed;
6. extracts the PS-EXE;
7. recompiles PS1 MIPS code to C;
8. builds the native Linux runtime;
9. stages a runnable Linux installation outside the repository.

No game image, retail BIOS, extracted executable, generated game C or other
game-derived material is committed.

## Overlay policy

GT2 stores menu and race code in overlays.

For the initial baseline the launcher sets:

    PSX_OVERLAY_AUTOCOMPILE_OFF=1

This removes background overlay compilation from the first Linux bring-up so
boot, graphics, input, audio and filesystem behavior can be validated first.

The next milestone is:

    Linux native overlay cache
            +
    prebuilt native shards
            +
    static/AOT overlays

Static/AOT overlays are especially important for future console targets that
cannot spawn Python/GCC or dynamically load newly generated libraries.

## Portability direction

PSXRecomp and SDL remain the primary host abstraction.

GT2-specific platform code should stay small and cover only host-specific
concerns such as writable paths, lifecycle, disc relaunch, process spawning,
dynamic libraries, overlay policy and renderer capability discovery.
