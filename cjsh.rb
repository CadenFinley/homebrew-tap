require "digest"

class Cjsh < Formula
  desc "POSIX Shell Scripting meets Modern Shell Features"
  homepage "https://github.com/CadenFinley/CJsShell"
  url "https://github.com/CadenFinley/CJsShell/archive/refs/tags/v1.4.15.tar.gz"
  sha256 "a5b001262e31335a9f81829bc8c7c3952473bc3a04d941aba0aa50437023218c"
  license "MIT"
  head "https://github.com/CadenFinley/CJsShell.git", branch: "master"

  STABLE_GIT_HASH = "770efa16".freeze

  PREBUILT_SHA256 = {
    "macos-arm64" => "ff608758f7036a5c85e74f5d958aed49a19b14869f6e99005007707b3f15ee69",
    "macos-x86_64" => "0bc9ee655a014bd196cd1a6231fc92cc95ce4da0d8d59ad28e89e388b7b14179",
    "linux-gnu-arm64" => "1ce757e8070f8e73361e159c754d27619dfe364e21fc9520e6f7bad7ec531059",
    "linux-gnu-x86_64" => "45900892c44d40c91527147708ae1f9db79ebb5e8f11a63674b5c280ff60769b",
  }.freeze

  depends_on "cmake" => :build

  conflicts_with "cjsh-dev", because: "both install `cjsh` binaries"

  def install
    unless install_prebuilt
      install_from_source
    end

    system "#{bin}/cjsh", "--version"
  end

  def install_prebuilt
    target = prebuilt_target
    return false unless target

    archive = buildpath/"cjsh-prebuilt.tar.gz"
    archive_url = "https://github.com/CadenFinley/CJsShell/releases/download/v#{version}/cjsh-v#{version}-#{target}.tar.gz"

    begin
      system "curl", "-fL", "--retry", "3", "--silent", "--show-error", archive_url, "-o", archive
    rescue StandardError => e
      opoo "Prebuilt cjsh archive unavailable (#{e.message}); building from source"
      return false
    end

    expected_sha256 = self.class::PREBUILT_SHA256.fetch(target)
    actual_sha256 = Digest::SHA256.file(archive).hexdigest
    raise "Prebuilt cjsh archive checksum mismatch: expected #{expected_sha256}, got #{actual_sha256}" unless actual_sha256 == expected_sha256

    mkdir "prebuilt"
    system "tar", "-xzf", archive, "-C", "prebuilt", "--strip-components=1"
    bin.install "prebuilt/cjsh"
    true
  end

  def prebuilt_target
    architecture = if Hardware::CPU.arm?
      "arm64"
    elsif Hardware::CPU.intel?
      "x86_64"
    end
    return unless architecture

    if OS.mac?
      "macos-#{architecture}"
    elsif OS.linux?
      "linux-gnu-#{architecture}"
    end
  end

  def install_from_source
    git_hash = begin
      if (buildpath/".git").directory?
        Utils.safe_popen_read("git", "-C", buildpath, "rev-parse", "--short", "HEAD").strip
      elsif stable?
        self.class::STABLE_GIT_HASH
      else
        version.to_s
      end
    rescue
      stable? ? self.class::STABLE_GIT_HASH : version.to_s
    end

    git_hash = "unknown" if git_hash.blank?
    ENV["CJSH_GIT_HASH_OVERRIDE"] = git_hash

    args = std_cmake_args + [
      "-DCMAKE_BUILD_TYPE=Release",
      "-DCJSH_BUILD_TESTS=OFF",
      "-DBUILD_TESTING=OFF"
    ]
    system "cmake", "-S", ".", "-B", "build", *args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  def uninstall
    (bin/"cjsh").unlink if (bin/"cjsh").exist?

    if File.exist?("/etc/shells") && File.read("/etc/shells").include?("#{bin}/cjsh")
      ohai "Removing #{bin}/cjsh from /etc/shells"
      system "sudo", "sed", "-i", "", "/#{bin.to_s.gsub("/", "\\/")}\\/cjsh/d", "/etc/shells"
    end

    ohai "Additional files that can be manually removed:"
    puts "  ~/.cache/cjsh/        (cache directory)"
    puts "  ~/.cjprofile          (profile file)"
    puts "  ~/.cjshrc             (rc file)"
    puts "  ~/.cjsh_logout        (logout file)"
    puts ""
    puts "If cjsh was set as your login shell, change it back with:"
    puts "  chsh -s /bin/bash  # or /bin/zsh"
  end

  test do
    assert_match "cjsh", shell_output("#{bin}/cjsh --version 2>&1")

    assert_match "hello", shell_output("#{bin}/cjsh -c 'echo hello'")
  end
end
