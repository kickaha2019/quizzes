class WordSearch
  def initialize( dir)
    @words = IO.readlines( dir + '/words.txt').collect {|l| l.downcase.strip}
    @alphabet = "abcdefghijklmnopqrstuvwxyz"
  end

  def contains( word, letters)
    word = word.chars
    letters.chars.each do |ch|
      return false unless word.index( ch)
    end
    true
  end

  def count_occurrences( len)
    @words.each do |word|
      next if word.size > 7
      find_possibles_from( word.chars.uniq.sort.join(''), 0, len) do |poss|
        if @possibles[poss]
          if word.size < 5
            @possibles.delete( poss)
          else
            @possibles[poss] += 1
          end
        end
      end
    end
  end

  def exclude( *keys)
    keys.each {|key| @possibles.delete( key.downcase)}
  end

  def find_possibles( len)
    @possibles = {}
    find_possibles_from( @alphabet, 0, len) do |poss|
      @possibles[poss] = 0
    end
  end

  def find_possibles_from( string, offset, len)
    (offset..(string.size-len)).each do |i|
      if len <= 1
        yield string[i..i]
      else
        find_possibles_from( string, i+1, len-1) do |poss|
          yield (string[i..i] + poss)
        end
      end
    end
  end

  def shortest_contains( letters)
    found = []
    @words.each do |word|
      next if found[0] && (found[0].size < word.size)
      if contains( word, letters)
        if found[0] && (found[0].size == word.size)
          found << word
        else
          found = [word]
        end
      end
    end
    found
  end

  def found
    @possibles.each_pair do |k,c|
      yield k if c > 0
    end
  end
end

ws = WordSearch.new( ARGV[0])
ws.find_possibles( 3)
ws.exclude( 'BCD', 'EFG', 'FGH', 'IJK', 'JKL', 'KLM', 'LMN', 'PQR', 'TUV', 'UVW')
ws.count_occurrences( 3)

File.open( ARGV[1], 'w') do |io|
  io.puts 'letters,shortest'
  ws.found do |letters|
    io.puts "#{letters},#{ws.shortest_contains(letters).join(' ')}"
  end
end