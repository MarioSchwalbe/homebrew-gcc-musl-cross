# vim: set tabstop=2 shiftwidth=2 expandtab:

class Gcc8MuslCross < Formula
  BINUTILS_VER = "2.32".freeze
  GCC_VER      = "8.3.0".freeze
  MUSL_VER     = "1.1.24".freeze

  desc "Linux cross compilers based on GCC #{GCC_VER} and musl libc #{MUSL_VER}"
  homepage "https://github.com/richfelker/musl-cross-make"
  url "https://github.com/richfelker/musl-cross-make/archive/v0.9.8.tar.gz"
  version GCC_VER
  sha256 "886ac2169c569455862d19789a794a51d0fbb37209e6fae1bda7d6554a689aac"
  head "https://github.com/richfelker/musl-cross-make.git"

  OPTION_TARGET_MAP = {
    "x86"        => "i686-linux-musl",
    "x86_64"     => "x86_64-linux-musl",
    "x86_64x32"  => "x86_64-linux-muslx32",
    "arm"        => "arm-linux-musleabi",
    "armhf"      => "arm-linux-musleabihf",
    "aarch64"    => "aarch64-linux-musl",
    "mips"       => "mips-linux-musl",
    "mips64"     => "mips64-linux-musl",
    "powerpc"    => "powerpc-linux-musl",
    "powerpc64"  => "powerpc64-linux-musl",
    "s390x"      => "s390x-linux-musl",
    # FIXME: test application crashed
    # "sh4"        => "sh4-linux-musl",
    # FIXME: cannot execute binary file: exec format error
    # "microblaze" => "microblaze-linux-musl",
  }.freeze

  OPTION_TARGET_MAP.each do |option, target|
    if %w[armhf aarch64 x86_64].include? option
      option "without-#{option}", "Do not build cross-compilers for #{target}"
    else
      option "with-#{option}", "Build cross-compilers for #{target}"
    end
  end

  option "with-all-targets", "Build cross-compilers for all targets"

  depends_on "gmp"     => :build
  depends_on "gnu-sed" => :build
  depends_on "isl"     => :build
  depends_on "libmpc"  => :build
  depends_on "make"    => :build
  depends_on "mpfr"    => :build

  MUSL_SHA256_MAP = {
    "1.1.19" => "db59a8578226b98373f5b27e61f0dd29ad2456f4aa9cec587ba8c24508e4c1d9",
    "1.1.20" => "44be8771d0e6c6b5f82dd15662eb2957c9a3173a19a8b49966ac0542bbd40d61",
    "1.1.21" => "c742b66f6f49c9e5f52f64d8b79fecb5a0f6e0203fca176c70ca20f6be285f44",
    "1.1.22" => "8b0941a48d2f980fd7036cfbd24aa1d414f03d9a0652ecbd5ec5c7ff1bee29e3",
    "1.1.23" => "8a0feb41cef26c97dde382c014e68b9bb335c094bbc1356f6edaaf6b79bd14aa",
    "1.1.24" => "1370c9a812b2cf2a7d92802510cca0058cc37e66a7bedd70051f0a34015022a3",
  }.freeze

  resource "linux-4.4.10.tar.xz" do
    url "https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-4.4.10.tar.xz"
    sha256 "4ac22e4a619417213cfdab24714413bb9118fbaebe6012c6c89c279cdadef2ce"
  end

  resource "binutils-#{BINUTILS_VER}.tar.bz2" do
    url "https://ftp.gnu.org/gnu/binutils/binutils-#{BINUTILS_VER}.tar.bz2"
    sha256 "de38b15c902eb2725eac6af21183a5f34ea4634cb0bcef19612b50e5ed31072d"
  end

  resource "gcc-#{GCC_VER}.tar.xz" do
    url "https://ftp.gnu.org/gnu/gcc/gcc-#{GCC_VER}/gcc-#{GCC_VER}.tar.xz"
    sha256 "64baadfe6cc0f4947a84cb12d7f0dfaf45bb58b7e92461639596c21e02d97d2c"
  end

  resource "musl-#{MUSL_VER}.tar.gz" do
    url "https://www.musl-libc.org/releases/musl-#{MUSL_VER}.tar.gz"
    sha256 MUSL_SHA256_MAP[MUSL_VER]
  end

  resource "config.sub" do
    url "https://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=3d5db9ebe860"
    sha256 "75d5d255a2a273b6e651f82eecfabf6cbcd8eaeae70e86b417384c8f4a58d8d3"
  end

  def version_suffix
    version.to_s.slice(/\d/)
  end

  def install
    config_mak = buildpath/"config.mak"
    os_version = `uname -r`.chomp

    # put all (re)sources into src subdir
    (srcdir = buildpath/"src").mkpath
    resources.each do |resource|
      cp resource.fetch, srcdir/resource.name
    end

    # also change --libdir=#{lib}/gcc/#{version_suffix} to avoid conflicts with Homebrew gcc
    inreplace buildpath/"litecross"/"Makefile", "--libdir=/lib", "--libdir=/lib/gcc/#{version_suffix}-musl-cross"

    # make sure we use GNU sed for building
    ENV.prepend_path "PATH", "#{Formula["gnu-sed"].opt_libexec}/gnubin"

    # write config, build, and install for all targets
    OPTION_TARGET_MAP.each do |option, target|
      next unless build.with?(option) || build.with?("all-targets")

      # DOCS: https://gcc.gnu.org/install/configure.html
      config = <<-EOS
        SOURCES = #{srcdir}
        OUTPUT  = #{prefix}

        # Versions:
        BINUTILS_VER = #{BINUTILS_VER}
        GCC_VER  = #{GCC_VER}
        MUSL_VER = #{MUSL_VER}

        # Setup to use libs from Homebrew:
        GMP_VER  =
        MPC_VER  =
        MPFR_VER =
        ISL_VER  =
        COMMON_CONFIG += --with-gmp=#{Formula["gmp"].opt_prefix}
        COMMON_CONFIG += --with-mpc=#{Formula["libmpc"].opt_prefix}
        COMMON_CONFIG += --with-mpfr=#{Formula["mpfr"].opt_prefix}
        COMMON_CONFIG += --with-isl=#{Formula["isl"].opt_prefix}
        COMMON_CONFIG += --with-system-zlib

        # Release build options:
        COMMON_CONFIG += --build=x86_64-apple-darwin#{os_version}
        COMMON_CONFIG += --program-prefix=#{target}-
        COMMON_CONFIG += --program-suffix=-#{version_suffix}
        # FIXME: Crashes on outout via std::cerr on arm-linux-musleabihf:
        # COMMON_CONFIG += --enable-default-pie
        COMMON_CONFIG += --enable-checking=release
        COMMON_CONFIG += --with-pkgversion="Homebrew GCC #{pkg_version} musl cross"
        COMMON_CONFIG += --with-bugurl="https://github.com/MarioSchwalbe/gcc-musl-cross/issues"

        # Recommended options for faster/simpler build:
        COMMON_CONFIG += --enable-languages=c,c++
        COMMON_CONFIG += --disable-nls
        COMMON_CONFIG += --disable-libquadmath --disable-libquadmath-support
        COMMON_CONFIG += --disable-multilib

        # Recommended options for smaller build for deploying binaries:
        COMMON_CONFIG += CFLAGS="-g0 -Os" CXXFLAGS="-g0 -Os" LDFLAGS="-s"

        # Keep the local build path out of binaries and libraries:
        COMMON_CONFIG += --with-debug-prefix-map=$(CURDIR)=

        # https://llvm.org/bugs/show_bug.cgi?id=19650:
        ifeq ($(shell $(CXX) -v 2>&1 | grep -c "clang"), 1)
            TOOLCHAIN_CONFIG += CXX="$(CXX) -fbracket-depth=512"
        endif
      EOS

      # append required options for ppc targets
      if target.start_with? "powerpc"
        config += <<-EOS
          COMMON_CONFIG += --with-long-double-64
          COMMON_CONFIG += --enable-secureplt
        EOS
      end

      # write config, build, and install
      config_mak.unlink if config_mak.exist?
      config_mak.write(config)
      system Formula["make"].opt_bin/"gmake", "TARGET=#{target}", "install"

      # delete -cc link (created by musl-cross-make) and -gcc-7.2.0 (GCC default)
      "cc gcc-#{GCC_VER}".split.each do |suffix|
        prog = bin/"#{target}-#{suffix}"
        prog.unlink if prog.file? || prog.symlink?
      end
    end

    # handle conflicts between GCC formulae and avoid interference with system compilers
    [man7, info, share/"gcc-#{GCC_VER}"/"python"].each do |dir|
      dir.rmtree if dir.exist?
    end
  end

  def caveats
    <<~EOS
      When using the toolchain, the generated binaries will only run on a system with
      musl libc installed. Either musl-based distributions like Alpine Linux or
      distributions having musl libc installed as separate packages (Debian/Ubuntu).
      However, if building static binaries they should run on any system.
    EOS
  end

  test do
    (testpath/"hello.c").write <<-EOS
      #include <stdio.h>
      int main(void) {
          puts("Hello World!");
          return 0;
      }
    EOS

    (testpath/"hello.cpp").write <<-EOS
      // FIXME: error: 'pthread_mutex_timedlock' was not declared in this scope
      #define _GLIBCXX_GCC_GTHR_POSIX_H 1
      #include <iostream>
      int main(void) {
          std::cout << "Hello World!" << std::endl;
          return 0;
      }
    EOS

    TEST_OPTION_MAP = {
      "readelf" => ["-a"],
      "objdump" => ["-ldSC"],
      "strings" => [],
      "size"    => [],
      "nm"      => [],
      "strip"   => [],
    }.freeze

    OPTION_TARGET_MAP.each do |option, target|
      next unless build.with?(option) || build.with?("all-targets")

      test_prog = "hello-#{target}"
      system bin/"#{target}-gcc-#{version_suffix}", "-O2", "hello.c", "-o", test_prog
      assert_predicate testpath/test_prog, :exist?
      TEST_OPTION_MAP.each do |prog, options|
        system bin/"#{target}-#{prog}-#{version_suffix}", *options, test_prog
      end

      system bin/"#{target}-g++-#{version_suffix}", "-O2", "hello.cpp", "-o", test_prog
      assert_predicate testpath/test_prog, :exist?
      TEST_OPTION_MAP.each do |prog, options|
        system bin/"#{target}-#{prog}-#{version_suffix}", *options, test_prog
      end
    end
  end
end
