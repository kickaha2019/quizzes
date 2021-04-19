require 'yaml'

File.open( ARGV[1], 'w') do |io|
  io.puts <<HEADER
<html><body><table><tr><th>Letter></th><Emojis</th></tr>
HEADER
  YAML.load( IO.read( ARGV[0]))['letters'].each_pair do |letter, emojis|
    io.puts "<tr><td>#{letter}</td><td>"
    io.puts emojis.split( ' ').collect {|e| "&#x#{e};"}.join( ' ')
    io.puts "</td></tr>"
  end
  io.puts '</table></body></html>'
end
