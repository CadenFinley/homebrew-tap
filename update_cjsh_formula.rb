#!/usr/bin/env ruby

require "json"
require "net/http"
require "open-uri"
require "openssl"
require "rubygems/version"

REPO = "CadenFinley/CJsShell"
FORMULA_PATH = File.expand_path("cjsh.rb", __dir__)
USER_AGENT = "cjsh-formula-updater"
ZERO_VERSION = Gem::Version.new("0")

class GitHubError < StandardError
  attr_reader :status

  def initialize(status, body)
    super("GitHub request failed (#{status}): #{body}")
    @status = status.to_i
  end
end

def github_json(path)
  uri = URI("https://api.github.com#{path}")
  req = Net::HTTP::Get.new(uri)
  req["User-Agent"] = USER_AGENT

  Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    res = http.request(req)
    raise GitHubError.new(res.code, res.body) unless res.is_a?(Net::HTTPSuccess)

    JSON.parse(res.body)
  end
end

def latest_release
  github_json("/repos/#{REPO}/releases/latest")
rescue GitHubError => e
  raise unless e.status == 404

  nil
end

def latest_tag_name
  refs = github_json("/repos/#{REPO}/git/matching-refs/tags?per_page=100")
  raise "No tags found for #{REPO}" if refs.empty?

  tags = refs.map { |ref| ref.fetch("ref").split("/").last }
  tags.max_by { |tag| [normalized_version(tag) || ZERO_VERSION, tag] }
end

def normalized_version(tag)
  Gem::Version.new(tag.sub(/\Av/, ""))
rescue ArgumentError
  nil
end

def choose_tag(release_tag, latest_tag)
  return latest_tag unless release_tag
  return release_tag unless latest_tag

  release_version = normalized_version(release_tag)
  latest_version = normalized_version(latest_tag)

  return latest_tag unless release_version
  return release_tag unless latest_version

  release_version >= latest_version ? release_tag : latest_tag
end

def commit_sha(ref)
  github_json("/repos/#{REPO}/commits/#{ref}").fetch("sha")
end

def tarball_url(tag)
  "https://github.com/#{REPO}/archive/refs/tags/#{tag}.tar.gz"
end

def sha256_for(url)
  digest = OpenSSL::Digest::SHA256.new

  URI.open(url) do |io|
    while (chunk = io.read(1024 * 128))
      digest.update(chunk)
    end
  end

  digest.hexdigest
end

def update_formula(content, replacements)
  updated = content.dup

  replacements.each do |pattern, replacement|
    replaced = updated.sub!(pattern, replacement)
    raise "Failed to update formula for #{replacement}" unless replaced
  end

  updated
end

def run
  release = latest_release
  release_tag = release&.fetch("tag_name", nil)
  tag = choose_tag(release_tag, latest_tag_name)
  url = tarball_url(tag)
  sha256 = sha256_for(url)
  git_hash = commit_sha(tag)[0, 8]

  formula = File.read(FORMULA_PATH)
  updated_formula = update_formula(formula,
                                   /url "[^"]+"/ => %{url "#{url}"},
                                   /sha256 "[^"]+"/ => %{sha256 "#{sha256}"},
                                   /STABLE_GIT_HASH = "[^"]+"\.freeze/ => %{STABLE_GIT_HASH = "#{git_hash}".freeze})

  if updated_formula == formula
    puts "cjsh.rb already up to date (#{tag})"
  else
    File.write(FORMULA_PATH, updated_formula)
    puts "Updated cjsh.rb to #{tag}"
    puts "  url: #{url}"
    puts "  sha256: #{sha256}"
    puts "  stable git hash: #{git_hash}"
  end
end

begin
  run
rescue StandardError => e
  warn e.message
  exit 1
end
