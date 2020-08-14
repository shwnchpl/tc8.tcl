# tc8.tcl

A CHIP-8 emulator written in Tcl 8.6.

## Usage

```
$ tc8.tcl path/to/chip8/rom
```

## Requirements

* A Linux system with Alsa that provides `aplay`.
* Tcl 8.6 with Tcl/TK.
* The Tcl thread extension (tcl-thread on Debian).

## Screenshots

## Credits

For information on the CHIP-8 architecture and how various instructions
should be implemented, I referred to the following resources:

* [Cowgod's Chip-8 Techincal Reference v1.0]

I also heavily consulted my [Rust CHIP-8 emulator implementation].

[Cowgod's Chip-8 Techincal Reference v1.0]: http://devernay.free.fr/hacks/chip8/C8TECH10.HTM
[Rust CHIP-8 emulator implementation]: https://github.com/shwnchpl/chip8
