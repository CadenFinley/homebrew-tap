class Cjsh < Formula
  desc "CJ's Shell"
  homepage "https://github.com/CadenFinley/CJsShell"
  url "https://github.com/CadenFinley/CJsShell.git",
      tag:      "2.0.2.8",
      revision: "c57226cae9146e483c5fec0d963431798b2f1c4b"

  license "MIT"

  depends_on "cmake"      => :build
  depends_on "pkgconf"    => :build
  depends_on "curl"
  depends_on "nlohmann-json"
  depends_on "openssl@3"

  def install
    system "cmake", "-S", ".", "-B", "build",
           "-DCMAKE_PREFIX_PATH=#{Formula["openssl@3"].opt_prefix}",
           *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  def post_install
    original_shell = ENV["SHELL"]
    (var/"cjsh").mkpath
    (var/"cjsh"/"original_shell.txt").write original_shell
  end

  def caveats
    <<~EOS
      CJ's Shell
      To set as your default shell run 'cjsh --set-as-shell'
       or run 'chsh -s #{opt_bin}/cjsh'
      To see the help menu run 'cjsh --help'
    EOS
  end

  def post_uninstall
    original_shell_file = var/"cjsh"/"original_shell.txt"
    if original_shell_file.exist?
      original_shell = original_shell_file.read.strip
      if original_shell.present? && File.executable?(original_shell)
        system "chsh", "-s", original_shell
        ohai "Your shell has been restored to: #{original_shell}"
        ohai "Please restart your terminal for the changes to take effect."
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
