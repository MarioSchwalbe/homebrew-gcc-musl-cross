# vim: set tabstop=2 shiftwidth=2 expandtab:

class GccMuslCross < Formula
  desc "Linux cross compilers based on GCC 7.2 and musl libc"
  homepage "https://github.com/richfelker/musl-cross-make"
  url "https://github.com/richfelker/musl-cross-make/archive/v0.9.7.tar.gz"
  version "7.2.0"
  sha256 "876173e2411b5f50516723c63075655a9aac55ee3804f91adfb61f0a85af8f38"
  # head "https://github.com/richfelker/musl-cross-make.git"

  OPTION_TO_TARGET_MAP = {
    "i686"       => "i686-linux-musl",
    "x86_64"     => "x86_64-linux-musl",
    "x86_64x32"  => "x86_64-linux-muslx32",
    "arm"        => "arm-linux-musleabi",
    "armhf"      => "arm-linux-musleabihf",
    "aarch64"    => "aarch64-linux-musl",
    "mips"       => "mips-linux-musl",
    "mips64"     => "mips64-linux-musl",
    "powerpc"    => "powerpc-linux-musl",
    "powerpc64"  => "powerpc64-linux-musl",
    "microblaze" => "microblaze-linux-musl",
  }.freeze

  OPTION_TO_TARGET_MAP.each do |option, target|
    if %w[armhf x86_64].include? option
      option "without-#{option}", "Do not build cross-compilers for #{target}"
    else
      option "with-#{option}", "Build cross-compilers for #{target}"
    end
  end

  option "with-all-targets", "Build cross-compilers for all targets"

  depends_on "gnu-sed" => :build
  depends_on "make" => :build
  depends_on "libmpc" => :build
  depends_on "gmp" => :build
  depends_on "mpfr" => :build

  resource "linux-4.4.10.tar.xz" do
    url "https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-4.4.10.tar.xz"
    sha256 "4ac22e4a619417213cfdab24714413bb9118fbaebe6012c6c89c279cdadef2ce"
  end

  resource "binutils-2.27.tar.bz2" do
    url "https://ftp.gnu.org/gnu/binutils/binutils-2.27.tar.bz2"
    sha256 "369737ce51587f92466041a97ab7d2358c6d9e1b6490b3940eb09fb0a9a6ac88"
  end

  resource "gcc-7.2.0.tar.xz" do
    url "https://ftp.gnu.org/gnu/gcc/gcc-7.2.0/gcc-7.2.0.tar.xz"
    sha256 "1cf7adf8ff4b5aa49041c8734bbcf1ad18cc4c94d0029aae0f4e48841088479a"
  end

  resource "musl-1.1.19.tar.gz" do
    url "https://www.musl-libc.org/releases/musl-1.1.19.tar.gz"
    sha256 "db59a8578226b98373f5b27e61f0dd29ad2456f4aa9cec587ba8c24508e4c1d9"
  end

  resource "config.sub" do
    url "https://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=3d5db9ebe860"
    sha256 "75d5d255a2a273b6e651f82eecfabf6cbcd8eaeae70e86b417384c8f4a58d8d3"
  end

  # Fix parallel build on APFS filesystems (remove for GCC 7.4.0 and later)
  # https://gcc.gnu.org/bugzilla/show_bug.cgi?id=81797
  resource "apfs.patch" do
    url "https://raw.githubusercontent.com/Homebrew/formula-patches/df0465c02a/gcc/apfs.patch"
    sha256 "f7772a6ba73f44a6b378e4fe3548e0284f48ae2d02c701df1be93780c1607074"
  end

  def install
    cp resource("apfs.patch").fetch, buildpath/"patches"/"gcc-7.2.0"/"0099-apfs.diff"

    (buildpath/"src").mkpath
    resources.each do |resource|
      cp resource.fetch, buildpath/"src"/resource.name
    end

    # also pass --libdir=#{lib}/gcc/#{version_suffix} to avoid conflicts with gcc@7
    inreplace buildpath/"litecross"/"Makefile", "--libdir=/lib", "--libdir=/lib/gcc/7-musl-cross"

    # FIXME: append version suffix to binaries
    (buildpath/"config.mak").write <<-EOS
      SOURCES = #{buildpath/"src"}
      OUTPUT  = #{prefix}

      # Versions:
      GCC_VER  = 7.2.0
      MUSL_VER = 1.1.19
      # Do not attempt to download packages (isl is disabled by default)
      GMP_VER  =
      MPC_VER  =
      MPFR_VER =

      # Setup libs from Homebrew:
      GCC_CONFIG += --with-gmp=#{Formula["gmp"].opt_prefix}
      GCC_CONFIG += --with-mpc=#{Formula["libmpc"].opt_prefix}
      GCC_CONFIG += --with-mpfr=#{Formula["mpfr"].opt_prefix}
      GCC_CONFIG += --with-isl=#{Formula["isl"].opt_prefix}
      GCC_CONFIG += --with-system-zlib

      # Recommended options for faster/simpler build:
      GCC_CONFIG += --enable-languages=c,c++
      GCC_CONFIG += --disable-nls
      GCC_CONFIG += --disable-libquadmath --disable-libquadmath-support
      # GCC_CONFIG += --disable-multilib

      # Release build options:
      GCC_CONFIG += --enable-default-pie
      GCC_CONFIG += --enable-checking=release
      GCC_CONFIG += --with-pkgversion="Homebrew GCC #{pkg_version} musl cross"
      GCC_CONFIG += --with-bugurl="https://github.com/MarioSchwalbe/gcc-musl-cross/issues"

      # Recommended options for smaller build for deploying binaries:
      COMMON_CONFIG += CFLAGS="-g0 -Os" CXXFLAGS="-g0 -Os" LDFLAGS="-s"

      # Keep the local build path out of binaries and libraries:
      COMMON_CONFIG += --with-debug-prefix-map=$(CURDIR)=

      # https://llvm.org/bugs/show_bug.cgi?id=19650:
      ifeq ($(shell $(CXX) -v 2>&1 | grep -c "clang"), 1)
          TOOLCHAIN_CONFIG += CXX="$(CXX) -fbracket-depth=512"
      endif
    EOS

    ENV.prepend_path "PATH", "#{Formula["gnu-sed"].opt_libexec}/gnubin"

    OPTION_TO_TARGET_MAP.each do |option, target|
      next unless build.with?(option) || build.with?("all-targets")
      system Formula["make"].opt_bin/"gmake", "TARGET=#{target}", "install"
    end

    # Handle conflicts between GCC formulae and avoid interfering with system compilers.
    man7.rmtree
  end

  def caveats
    <<~EOS
      When using the toolchain, the generated binaries will only run on a system with
      musl libc installed. Either musl-based distributions like Alpine Linux or
      distributions having the libc installed as separate packages (Debian/Ubuntu).
      However, if building static binaries they should run on any system including
      bare docker containers (x86_64/armhf only).
    EOS
  end

  test do
    (testpath/"hello.c").write <<-EOS
      #include <stdio.h>
      int main(void)
      {
          puts("Hello, world!");
          return 0;
      }
    EOS

    (testpath/"hello.cpp").write <<-EOS
      #include <iostream>
      int main(void)
      {
          std::cout << "Hello, world!" << std::endl;
          return 0;
      }
    EOS

    OPTION_TO_TARGET_MAP.each do |option, target|
      next unless build.with?(option) || build.with?("all-targets")
      system bin/"#{target}-gcc", testpath/"hello.c"
      system bin/"#{target}-g++", testpath/"hello.cpp"
    end
  end
end
