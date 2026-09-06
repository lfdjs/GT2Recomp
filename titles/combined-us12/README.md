# Gran Turismo 2 Combined — NTSC-U 1.2 base

Experimental native Linux baseline for a Combined Disc derived from the
NTSC-U 1.2 Simulation executable.

The existing GT2 enhancement sources in this repository were validated
against NTSC-U 1.1 and remain intentionally disabled for this profile.

## Current Linux status

The NTSC-U 1.2 Combined profile is now confirmed playable on native
Linux x86-64.

Validated:

- OpenBIOS boot
- GT2 title sequence
- Arcade Mode menus
- road-race gameplay
- rally gameplay
- replay rendering
- DualSense gameplay input
- CD/XA streaming
- repeated gameplay transitions
- multi-minute runtime stability
- clean process exit

The current baseline remains intentionally vanilla. GT2 enhancement
patches verified only for NTSC-U 1.1 remain disabled.

Still pending before the Linux vanilla baseline is considered broadly
validated:

- Simulation Mode
- memory-card save/write/reload: confirmed
- audio validation
- longer soak testing

Performance optimization is a separate later milestone. Gameplay is
functional, but visible stutter and high resident-memory usage have been
recorded for profiling after functional validation is complete.

See `docs/LINUX_US12_BRINGUP.md` for the engineering checkpoint.

## Save persistence

The native Linux baseline now supports persistent PS1 memory-card data.

A controlled two-process test confirmed:

- existing card loading
- card-image modification after an in-game session
- increased occupied-block count
- identical post-save card hash after a complete runtime restart
- clean runtime exit in both sessions

Memory-card persistence is therefore considered operational for the current
Linux baseline.

Remaining functional validation focuses primarily on Simulation Mode,
audio, and longer soak testing.

## Source-disc policy

User-owned BIN/CUE files are immutable inputs.

Linux tooling must never repair or overwrite the original dump files.
