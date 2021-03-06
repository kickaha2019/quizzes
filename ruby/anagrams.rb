class Anagrams
  include Common

  def initialize( date, name, dir, size)
    @title = 'Solve anagrams for the names of ' + name
    defn = YAML.load( IO.read( dir))
    @title = defn['title'] if defn['title']
    # @items = defn['anagrams'].shuffle[0...size]
    @items = select_questions( date, defn, 'anagrams', size, dir)
    raise "Not enough questions for #{dir}" unless @items.size >= size

    defn['anagrams'].each do |item|
      if letters( item['anagram']) != letters(item['solution'])
        raise "[#{item['anagram']}] not an anagram of [#{item['solution']}] for #{dir}"
      end
    end
  end

  def generate( questions, output)
    File.open( "#{output}/#{questions}.html", 'w') do |io|
      generate_header( io)

      @items.each_index do |i|
        generate_item( i+1, @items[i]['anagram'], pattern( @items[i]), @items[i]['solution'], io)
      end

      io.puts '</table></body></html>'
    end
    @title
  end

  def generate_header( io)
    write_header( @title, 1, @items.size, io)
    io.puts <<"HEADER"
<table>
<tr><th>#</th><th>Anagram</th><th>&nbsp;&nbsp;&nbsp;Solution&nbsp;&nbsp;&nbsp;</th></tr>
HEADER
  end
  
  def generate_item( index, anagram, clue, answer, io)
    write_item( index, anagram, clue, answer, io)
  end
  
  def letters( phrase)
    phrase = phrase.gsub( /\W/, '').downcase
    phrase.chars.sort.join('')
  end

  def pattern( item)
    item['solution'].gsub( /\w/, '-')
  end
end
