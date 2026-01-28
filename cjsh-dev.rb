class CjshDev < Formula
  desc "POSIX Shell Scripting meets Modern Shell Features."
  homepage "https://github.com/CadenFinley/CJsShell"
  license "MIT"

  head_branch = ENV["CJSH_DEV_BRANCH"]
  head_branch = "master" if head_branch.nil? || head_branch.empty?
  head "https://github.com/CadenFinley/CJsShell.git", branch: head_branch

  version "HEAD"

  depends_on "cmake" => :build

  conflicts_with "cjsh", because: "both install `cjsh` binaries"

  def install
    head_branch = ENV["CJSH_DEV_BRANCH"]
    head_branch = "master" if head_branch.nil? || head_branch.empty?
    branch_tag = head_branch.tr("/", "-")

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
    ENV["CJSH_GIT_HASH_OVERRIDE"] = "#{git_hash}-#{branch_tag}-DEV"

    args = std_cmake_args + ["-DCMAKE_BUILD_TYPE=Release"]
    system "cmake", "-S", ".", "-B", "build", *args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"

    system "#{bin}/cjsh", "--version"
  end

  def caveats
    <<~EOS
      Any non-tagged releases or commits do not have the promise of not containing non-breaking changes or working builds.
      For maximum build safety and usability, stick to tagged releases or through package manager installs of released builds.
      To build from a different branch HEAD, set CJSH_DEV_BRANCH before installing, e.g.:
        CJSH_DEV_BRANCH=feature-x brew install cadenfinley/homebrew-tap/cjsh-dev
    EOS
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
