# Gran Turismo 2 Combined — NTSC-U 1.2 base

Experimental native Linux baseline for a Combined Disc derived from the
NTSC-U 1.2 Simulation executable.

The existing GT2 enhancement sources in this repository were validated
against NTSC-U 1.1 and remain intentionally disabled for this profile.

## Current Linux status

Confirmed:

- native Linux x86-64 runtime builds
- OpenBIOS boots
- SDL/OpenGL initialize
- DualSense is detected
- disc and memory cards initialize
- execution reaches GT2 program address space

The live diagnostic reached approximately frame 735 with:

    COP0 EPC = 0x8007C558
    RA       = 0x8007AB3C
    SP       = 0x801FFE58

No heap-corruption error was observed during the controlled live run.

Still pending:

- visible title screen confirmation
- main menu confirmation
- reliable menu navigation
- first race
- race video/audio/input validation

See `docs/LINUX_US12_BRINGUP.md` for the complete resumable checkpoint.

## Source-disc policy

User-owned BIN/CUE files are immutable inputs.

Linux tooling must never repair or overwrite the original dump files.
