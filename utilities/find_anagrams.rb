#
# Arguments:
#   Word list
#   Length of words
#
# ----------------------------------------------------------------------------
#

def load_words( path, len)
  words = Hash.new {|h,k| h[k] = []}
  count = 0

  IO.readlines( path).each do |word|
    word = word.strip.downcase
    if (/^[a-z]*$/ =~ word) && (word.size == len)
      count += 1
      letters = word.chars.sort.join('')
      words[ letters] << word
    end
  end

  puts "... #{count} words loaded from #{path}"
  puts "... #{words.size} patterns"
  return words
end

def list_anagrams( words, limit)
  words.each_pair do |letters, list|
    if list.size== limit
      puts "*** #{list.join( ' ')}"
    end
  end
end

words = load_words( ARGV[0], ARGV[1].to_i)
list_anagrams( words, ARGV[2].to_i)
