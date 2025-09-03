class Cjsh < Formula
  desc "CJ's Shell - Modern, interactive shell with AI assistance"
  homepage "https://github.com/CadenFinley/CJsShell"
  license "MIT"
  url "https://github.com/CadenFinley/CJsShell.git",
      tag:      "2.3.5",
      revision: "e2bc53165b82b21cd04c6bc678032bba045cacee"
  head "https://github.com/CadenFinley/CJsShell.git", branch: "master"

  depends_on "cmake"      => :build
  depends_on "pkgconf"    => :build
  depends_on "googletest" => :test
  depends_on "curl"
  depends_on "nlohmann-json"
  depends_on "openssl@3"
  depends_on "zlib"

  def install
    ohai "Configuring CJ's Shell with CMake..."
    args = std_cmake_args + %W[
      -DCMAKE_PREFIX_PATH=#{Formula["openssl@3"].opt_prefix}
      -DCMAKE_FIND_FRAMEWORK=LAST
      -DBUILD_TESTS=OFF
    ]
    mkdir "build" unless Dir.exist?("build")
    system "cmake", "-S", ".", "-B", "build", *args
    ohai "Building CJ's Shell..."
    system "cmake", "--build", "build", "--config", "Release", "-j#{ENV.make_jobs}"
    ohai "Installing CJ's Shell..."
    system "cmake", "--install", "build"
    ohai "Installing man pages..."
    man1.install "man/cjsh.1"
    (prefix/"plugins").mkpath
    pkgshare.mkpath
    cp Dir["themes/*.json"], pkgshare
    ohai "Setting up environment..."
    (var/"cjsh").mkpath
    original_file = var/"cjsh"/"original_shell"
    original_file.write ENV["SHELL"] unless original_file.exist?
    ohai "Installation complete!"
  end

  def caveats
    version_info = "development version"
    version_info = "v#{version}" if build.stable?
    <<~EOS
      CJ's Shell (#{version_info})

      Warning: cjsh is not a POSIX compliant shell. Similar to FISH, misuse of cjsh or
      incorrectly setting it as your login shell can have adverse effects and there
      is NO warranty.

      To add CJsShell to the list of allowed shells run:
        sudo sh -c "echo #{opt_bin}/cjsh >> /etc/shells"
      To set as your default shell run:
        chsh -s #{opt_bin}/cjsh
      To see the help menu run:
        cjsh --help
      Themes are installed at:
        #{pkgshare}
      Plugins can be installed at:
        #{prefix}/plugins/
      For more information, visit:
        #{homepage}
    EOS
  end

  def post_upgrade
    if build.stable?
      ohai "CJ's Shell has been upgraded to v#{version}!"
      ohai "Changes from this version:"
      ohai "- Check #{homepage}/releases/tag/#{version} for release notes"
    else
      ohai "CJ's Shell has been upgraded to the latest development version!"
      ohai "- Check #{homepage}/commits/master for recent changes"
    end
    ohai "Please restart your terminal session for the changes to take effect."
  end

  def post_uninstall
    original_shell_file = var/"cjsh"/"original_shell"
    if original_shell_file.exist?
      original_shell = original_shell_file.read.strip
      if !original_shell.empty? && File.executable?(original_shell)
        system "chsh", "-s", original_shell
        ohai "Your shell has been restored to: #{original_shell}"
        ohai "Please restart your terminal for the changes to take effect."
        original_shell_file.unlink
      else
        opoo "Could not restore original shell: Invalid shell path found in #{original_shell_file}"
      end
    else
      opoo "Could not restore original shell: No record of original shell found"
    end
    rm_rf var/"cjsh"
  end

  test do
    assert_match "v", shell_output(bin/"cjsh --version")
    system bin/"cjsh", "-c", "echo hello"
    assert_equal "hello", shell_output("#{bin}/cjsh -c 'echo hello'").strip
  end
end
