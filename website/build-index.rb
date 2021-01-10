#!/usr/bin/env ruby
require 'erb'

files = []
Dir.glob("*.bin") do |filename|
  files << {
    :filename => filename,
    :size => File.size(filename),  
    :sha256 => File.read(filename+'.sha256').split.first
  }
end

erb = ERB.new(DATA.read)
puts erb.result()



__END__
<!DOCTYPE html>
<html>
<head>
  <title>Sonoff OTA Open Source Firmware</title>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="stylesheet" href="picnic.min.css" />
</head>
<body>
  <h1>Sonoff OTA Open Source Firmware</h1>

  <p>
    This server was setup to provide firmware images for the <a href="https://github.com/njh/sonoff-ota-flash-cli">sonoff-ota-flash-cli</a> script.
  
    A seperate server was setup because:
    <ul>
      <li>There is a bug in the Sonoff 3.5.0 firmware that means the <code>Host</code> header is always set to <code>dl.itead.cn</code></li>
      <li>It provides SHA256 checksum calculations for each of the firmware files (append .sha256 to the URL)</li>
      <li>Only includes firmware less than 508kB (the maximum allowed by Sonoff OTA flashing)</li>
    </ul>
    
    The binaries are the same as on the main <a href="http://ota.tasmota.com/tasmota/">Tasmota OTA server</a>.
  </p>

  <table>
    <thead>
      <tr>
        <th>Filename</th>
        <th>File Size</th>
        <th>SHA256</th>
      </tr>
    </thead>

    <tbody>
      <% files.each do |file| %>
        <tr>
          <td><a href="http://sonoff-ota.aelius.com/<%= file[:filename] %>"><%= file[:filename] %></a></td>
          <td><%= file[:size] / 1000 %>k</td>
          <td><code><%= file[:sha256] %></code></td>
        </tr>
      <% end %>
    </tbody>
  </table>

  <footer>
    <p>
      Tasmota is Copyright (C) 2020 Theo Arends and released under the GNU General Public License.
      See the <a href="https://tasmota.github.io/docs/">Tasmota website</a> for more information.
    </p>
  </footer>

</body>
</html>
