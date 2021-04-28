File.open( ARGV[1], 'w') do |io|
  IO.readlines( ARGV[0]).each do |line|
    line.gsub( /states\/us-\w\w\.php">([A-Za-z ]*)</) do |m|
      io.puts m.split( /[<>]/)[1]
    end
  end
end
