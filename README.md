gcc-musl-cross
==============

[Homebrew](https://brew.sh/) package manager formula to install cross-compiler toolchains targeting
Linux boxes.

The default installation contains toolchains for x86 64-bit Linux (`x86_64-linux-musl`) and ARM
32-bit Linux (`arm-linux-musleabihf`) as used on Raspberry Pi and similar devices. Others can be
installed with package options (see `brew info`).

Note, when using the toolchain, the generated binaries will only run on a system with `musl` libc
installed. Either musl-based distributions like Alpine Linux or distributions having the libc
installed as separate packages (e.g., Debian/Ubuntu).

Binaries statically linked with `musl` libc (link with `--static`) have no external dependencies,
even for features like DNS lookups or character set conversions that are implemented with dynamic
loading on glibc. The application can be deployed as a single binary file and run on any machine
with the appropriate ISA and Linux kernel or Linux syscall ABI emulation layer including bare docker
containers (x86_64/armhf only).

**Tool Versions:**
- [GCC](https://gcc.gnu.org/) 7.2.0
- [binutils](https://www.gnu.org/software/binutils/) 2.27
- [musl libc](https://www.musl-libc.org/) 1.1.19

**Based upon:**
- [musl-cross-make](https://github.com/richfelker/musl-cross-make) by Rich Felker
- [homebrew-musl-cross](https://github.com/FiloSottile/homebrew-musl-cross) by Filippo Valsorda


Usage
-----

1. Install with Homebrew:
    ```sh
    $ brew install MarioSchwalbe/gcc-musl-cross/gcc-musl-cross
    ```
    or
    ```sh
    $ brew tap MarioSchwalbe/gcc-musl-cross
    $ brew install gcc-musl-cross
    ```

1. For dynamically linked applications install the Debian/Ubuntu packages on the target:
    ```sh
    $ sudo apt-get install musl:i386=1.1.19-1 musl:amd64=1.1.19-1
    ```
    Make sure to install the correct version. As of this writing Ubuntu 18.04 (Bionic) ships `musl`
    libc `1.1.19` also used to build the toolchain.

1. Compile with `<TARGET>-gcc` e.g., `x86_64-linux-musl-gcc`, deploy, and run.


Supported Targets
-----------------

1. `i686-linux-musl`
1. `x86_64-linux-musl`
1. `x86_64-linux-muslx32`
1. `arm-linux-musleabi`
1. `arm-linux-musleabihf`
1. `aarch64-linux-musl`
1. `mips-linux-musl`
1. `mips64-linux-musl`
1. `powerpc-linux-musl`
1. `powerpc64-linux-musl`
1. `microblaze-linux-musl`

Other targets or variants can be added easily by extending the hash `OPTION_TO_TARGET_MAP` in the
formula as long as `musl-cross-make` and `musl` libc also support them.
