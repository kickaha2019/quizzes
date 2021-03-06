#
# Arguments:
#   Word list
#   Length of words
#
# ----------------------------------------------------------------------------
#

def generate_mask( chars, pos)
  mask = []
  (0...(chars.size)).each do |i|
    mask << ((i == pos) ? '?' : chars[i])
  end
  mask.join('')
end

def load_words_masks( path, len)
  masks = Hash.new {|h,k| h[k] = []}
  words = Hash.new {|h,k| h[k] = []}

  IO.readlines( path).each do |word|
    word = word.strip.downcase
    if (/^[a-z]*$/ =~ word) && (word.size == len)
      (0..(len-3)).each do |i|
        mask = generate_mask( word.chars, i)
        masks[ mask] << word
        words[ word] << mask
      end
    end
  end

  puts "... #{words.size} words loaded from #{path}"
  puts "... #{masks.size} masks generated"
  return words, masks
end

def list_neighbours( words, masks, limit)
  words.each_pair do |word, list|
    neighbours = []
    list.each {|m| neighbours += masks[m]}
    neighbours = neighbours.select {|n| n > word}.uniq.sort
    if (neighbours.size > 0) && (neighbours.size <= limit)
      puts "*** #{word}"
      puts( '    ' + (neighbours.uniq - [word]).sort.join( ' '))
    end
  end
end

words, masks = load_words_masks( ARGV[0], ARGV[1].to_i)
list_neighbours( words, masks, ARGV[2].to_i)
