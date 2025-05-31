class Cjsh < Formula
  desc "CJ's Shell"
  homepage "https://github.com/CadenFinley/CJsShell"
  url "https://github.com/CadenFinley/CJsShell.git",
      tag:      "2.2.5",
      revision: "de9b39a52c7ab3ed0a0d8616a970ed1cdbe595d3"

  license "MIT"

  depends_on "cmake"      => :build
  depends_on "pkgconf"    => :build
  depends_on "curl"
  depends_on "nlohmann-json"
  depends_on "openssl@3"

  def install
    ohai "Configuring CJ's Shell with CMake..."
    system "cmake", "-S", ".", "-B", "build",
           "-DCMAKE_PREFIX_PATH=#{Formula["openssl@3"].opt_prefix}",
           *std_cmake_args
    
    ohai "Building CJ's Shell..."
    system "cmake", "--build", "build", "--verbose"
    
    ohai "Installing CJ's Shell..."
    system "cmake", "--install", "build"

    ohai "Installing man pages..."
    man1.install "man/cjsh.1"
    
    ohai "Setting up environment..."
    (var/"cjsh").mkpath
    original_file = var/"cjsh"/"original_shell"
    unless original_file.exist?
      original_file.write ENV["SHELL"]
    end
    
    ohai "Installation complete!"
  end

  def caveats
    <<~EOS
      CJ's Shell

      Warning: cjsh is not a POSIX compliant shell. Similar to FISH, misuse of cjsh or
      incorrectly setting it as your login shell can have adverse effects and there
      is no warranty.

      To add CJsShell to the list of allowed shells run
       'sudo sh -c "echo #{opt_bin}/cjsh >> /etc/shells"'
      To set as your default shell run
       'chsh -s #{opt_bin}/cjsh'
      To see the help menu run 'cjsh --help'
    EOS
  end

  def post_upgrade
    ohai "CJ's Shell has been upgraded!"
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
  end

  test do
    assert_match "v#{version}", shell_output("#{bin}/cjsh --version")
  end
end
