class Cjsh < Formula
  desc "CJ's Shell (cjsh) is a lightweight shell with out of the box power and speed."
  homepage "https://github.com/CadenFinley/CJsShell"
  license "MIT"
  url "https://github.com/CadenFinley/CJsShell.git",
      tag:      "3.5.4",
      revision: "bbd95ace677d8833ce7074a5cc3b8256f26cd069"
  head "https://github.com/CadenFinley/CJsShell.git", branch: "master"

  def install
    # Build using the nob build system
    cd "build_tools" do
      system "cc", "-o", "nob", "nob.c"
      system "./nob"
    end

    # Install the binary
    bin.install "build/cjsh"
  end

  def uninstall
    # Remove the binary
    (bin/"cjsh").unlink if (bin/"cjsh").exist?
    
    # Remove from /etc/shells if it exists there
    if File.exist?("/etc/shells") && File.read("/etc/shells").include?("#{bin}/cjsh")
      ohai "Removing #{bin}/cjsh from /etc/shells"
      system "sudo", "sed", "-i", "", "/#{bin.to_s.gsub("/", "\\/")}\\/cjsh/d", "/etc/shells"
    end
    
    # Inform user about additional files
    ohai "Additional files that can be manually removed:"
    puts "  ~/.config/cjsh/          (configuration directory)"
    puts "  ~/.cache/cjsh/        (cache directory)"
    puts "  ~/.cjprofile          (profile file)"
    puts "  ~/.cjshrc             (rc file)"
    puts ""
    puts "If cjsh was set as your login shell, change it back with:"
    puts "  chsh -s /bin/bash  # or /bin/zsh"
  end

  def caveats
    <<~EOS
      To use cjsh as your login shell:
      1. Add #{bin}/cjsh to /etc/shells:
         echo "#{bin}/cjsh" | sudo tee -a /etc/shells

      2. Change your shell:
         chsh -s #{bin}/cjsh

      Configuration files will be created in ~/.config/cjsh/ on first run.
      To uninstall cjsh configuration, run: cjsh -c "cjsh_uninstall"
    EOS
  end

  test do
    # Test that the binary runs and shows version
    assert_match "cjsh", shell_output("#{bin}/cjsh --version 2>&1")
    
    # Test basic command execution
    assert_match "hello", shell_output("#{bin}/cjsh -c 'echo hello'")
  end
end
