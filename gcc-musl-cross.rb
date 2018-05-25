class GccMuslCross < Formula
  desc "Linux cross compilers based on GCC 7.2 and musl libc"
  homepage "https://github.com/richfelker/musl-cross-make"
  url "https://github.com/richfelker/musl-cross-make/archive/v0.9.7.tar.gz"
  sha256 "876173e2411b5f50516723c63075655a9aac55ee3804f91adfb61f0a85af8f38"
  head "https://github.com/richfelker/musl-cross-make.git"

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
    "sh4"        => "sh4-linux-musl",
    "s390x"      => "s390x-linux-musl",
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

  resource "musl-1.1.19.tar.gz" do
    url "https://www.musl-libc.org/releases/musl-1.1.19.tar.gz"
    sha256 "db59a8578226b98373f5b27e61f0dd29ad2456f4aa9cec587ba8c24508e4c1d9"
  end

  resource "gcc-7.2.0.tar.xz" do
    url "https://ftp.gnu.org/gnu/gcc/gcc-7.2.0/gcc-7.2.0.tar.xz"
    sha256 "1cf7adf8ff4b5aa49041c8734bbcf1ad18cc4c94d0029aae0f4e48841088479a"
  end

  resource "config.sub" do
    url "https://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=3d5db9ebe860"
    sha256 "75d5d255a2a273b6e651f82eecfabf6cbcd8eaeae70e86b417384c8f4a58d8d3"
  end

  def install
    (buildpath/"src").mkpath
    resources.each do |resource|
      cp resource.fetch, buildpath/"src"/resource.name
    end

    (buildpath/"config.mak").write <<-EOS
      SOURCES = #{buildpath/"src"}
      OUTPUT  = #{libexec}

      # Versions:
      GCC_VER  = 7.2.0
      MUSL_VER = 1.1.19
      # Use Homebrew provided versions
      GMP_VER  =
      MPC_VER  =
      MPFR_VER =

      # Recommended options for faster/simpler build:
      COMMON_CONFIG += --disable-nls
      GCC_CONFIG    += --enable-languages=c,c++
      GCC_CONFIG    += --disable-libquadmath --disable-decimal-float
      GCC_CONFIG    += --disable-multilib

      # Recommended options for smaller build for deploying binaries:
      COMMON_CONFIG += CFLAGS="-g0 -Os" CXXFLAGS="-g0 -Os" LDFLAGS="-s"

      # Keep the local build path out of binaries and libraries:
      COMMON_CONFIG += --with-debug-prefix-map=$(CURDIR)=

      # https://llvm.org/bugs/show_bug.cgi?id=19650
      ifeq ($(shell $(CXX) -v 2>&1 | grep -c "clang"), 1)
          TOOLCHAIN_CONFIG += CXX="$(CXX) -fbracket-depth=512"
      endif
    EOS

    ENV.prepend_path "PATH", "#{Formula["gnu-sed"].opt_libexec}/gnubin"
    ENV.deparallelize

    OPTION_TO_TARGET_MAP.each do |option, target|
      next unless (build.with? option) || (build.with? "all-targets")
      system Formula["make"].opt_bin/"gmake", "TARGET=#{target}", "install"
    end

    bin.install_symlink Dir["#{libexec}/bin/*"]
  end

  def caveats
    <<~EOS
      When using the toolchain, the generated binaries will only run on a system with
      the musl libc installed. Either musl-based distributions like Alpine Linux or
      distributions having the libc installed as separate packages (Debian/Ubuntu).
      However, if building static binaries they should run on any system.
    EOS
  end

  test do
    (testpath/"hello.c").write <<-EOS.undent
      #include <stdio.h>

      int main(void)
      {
          printf("Hello World!\n");
          return 0;
      }
    EOS

    OPTION_TO_TARGET_MAP.each do |option, target|
      next unless (build.with? option) || (build.with? "all-targets")
      system (bin/"#{target}-cc"), (testpath/"hello.c")
    end
  end
end
