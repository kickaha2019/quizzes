#
# Arguments:
#   First list
#   Second list
#   Merged list
#
# ----------------------------------------------------------------------------
#

def load_list( path)
  list = {}
  IO.readlines( path).each do |word|
    word = word.strip.downcase
    list[word] = true if /^[a-z]*$/ =~ word
  end
  puts "... #{list.size} words loaded from #{path}"
  list
end

def report_missing( title1, list1, title2, list2)
  missing = 0
  list1.each_key do |word|
    unless list2[word]
      puts "*** #{word}" if missing < 10
      missing += 1
    end
  end
  puts "... #{missing} words in #{title1} not in #{title2}"
end

def write_merged( list1, list2, path)
  merged = (list1.keys + list2.keys).uniq.sort
  File.open( path, 'w') do |io|
    merged.each {|word| io.puts word}
  end
  puts "... #{merged.size} words written to merged list"
end

first  = load_list( ARGV[0])
second = load_list( ARGV[1])
report_missing( ARGV[0], first, ARGV[1], second)
report_missing( ARGV[1], second, ARGV[0], first)
write_merged( first, second, ARGV[2])