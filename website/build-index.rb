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

</body>
</html>
