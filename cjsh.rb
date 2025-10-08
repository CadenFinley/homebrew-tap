class Cjsh < Formula
  desc "CJ's Shell (cjsh) is a lightweight shell with out of the box power and speed."
  homepage "https://github.com/CadenFinley/CJsShell"
  license "MIT"
  url "https://github.com/CadenFinley/CJsShell.git",
      tag:      "3.9.0",
      revision: "8d5efb293e358737e9dc87c4bbded33ef9afea30"
  head "https://github.com/CadenFinley/CJsShell.git", branch: "master"

  def install
    git_hash = begin
      if (buildpath/".git").directory?
        Utils.safe_popen_read("git", "-C", buildpath, "rev-parse", "--short", "HEAD").strip
      elsif stable? && stable.specs[:revision]
        stable.specs[:revision][0, 7]
      else
        version.to_s
      end
    rescue
      stable? && stable.specs[:revision] ? stable.specs[:revision][0, 7] : version.to_s
    end

    git_hash = "unknown" if git_hash.nil? || git_hash.empty?
    ENV["CJSH_GIT_HASH_OVERRIDE"] = git_hash

    # Build using the nob build system
    cd "toolchain/nob" do
      puts "Building cjsh using nob..."
      puts "This can take a second."
      system "cc", "-o", "nob", "nob.c"
      system "./nob"
    end

    # Install the binary
    bin.install "build/cjsh"
    
    # Verify installation
    system "#{bin}/cjsh", "--version"
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
    puts "  ~/.cache/cjsh/        (cache directory)"
    puts "  ~/.cjprofile          (profile file)"
    puts "  ~/.cjshrc             (rc file)"
    puts "  ~/.cjsh_logout        (logout file)"
    puts ""
    puts "If cjsh was set as your login shell, change it back with:"
    puts "  chsh -s /bin/bash  # or /bin/zsh"
  end

  test do
    # Test that the binary runs and shows version
    assert_match "cjsh", shell_output("#{bin}/cjsh --version 2>&1")
    
    # Test basic command execution
    assert_match "hello", shell_output("#{bin}/cjsh -c 'echo hello'")
  end
end
