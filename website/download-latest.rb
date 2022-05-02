#!/usr/bin/env ruby
require 'net/https'
require 'json'
require 'uri'
require 'fileutils'

# Maxium size of firmware allowed by Sonoff OTA flashing
MAX_SIZE = 520192

def find_asset(release, name)
  asset = release['assets'].find {|a| a['name'] == name}
  raise "Unable to find #{name} for release #{release['name']}" if asset.nil?
  return asset
end

def download(release, name, output_filename)
  if File.exist?(output_filename)
    puts "=> already exists: #{output_filename}"
  else
    asset = find_asset(release, name)
    url = asset['browser_download_url']
    puts "=> downloading: #{output_filename}"
    system(
      'curl',
      '--silent',
      '--fail',
      '--location',
      '--show-error',
      '--output', output_filename, url
    ) or raise "Failed to download: #{url}"
  end
end


uri = URI('https://api.github.com/repos/arendst/tasmota/releases')
response = Net::HTTP.get_response(uri)
data = JSON.parse(response.body)
latest = data.first

version = latest['tag_name'].sub(/^v/,'')
puts "Latest release is: #{version}"

download(latest, 'tasmota-minimal.bin', "tasmota-#{version}-minimal.bin")
download(latest, 'tasmota-lite.bin', "tasmota-#{version}-lite.bin")

# Copy the latest version of lite to 'latest'
FileUtils.cp("tasmota-#{version}-lite.bin", 'tasmota-latest-lite.bin')

# Force the SHA-256 to be recalculated
File.delete('tasmota-latest-lite.bin.sha256') if File.exist?('tasmota-latest-lite.bin.sha256')
