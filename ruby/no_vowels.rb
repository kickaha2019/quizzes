class NoVowels
  include Common

  def initialize( index, name, dir, size)
    @title = 'Add the missing vowels to the names of ' + name
    defn = YAML.load( IO.read( dir))
    @title = defn['title'] if defn['title']
    # @items = defn['phrases'].shuffle[0...size]
    @items = select_questions( index, defn, 'phrases', size, dir)
    raise "Not enough questions for #{dir}" unless @items.size >= size
  end

  def generate( questions, output)
    File.open( "#{output}/#{questions}.html", 'w') do |io|
      generate_header( io)

      @items.each_index do |i|
        write_item( i+1, @items[i]['phrase'].upcase.gsub(/[AEIOU\W]/, ''), '', @items[i]['phrase'], io)
      end

      io.puts '</table></body></html>'
    end
    @title
  end

  def generate_header( io)
    write_header( @title, 1, @items.size, io)
    answer_width = maximum_text_width( @items.collect {|item| item['phrase']})
    io.puts <<"HEADER"
<table>
<tr><th>#</th><th>Clue</th><th style="min-width: #{answer_width}px">Answer</th></tr>
HEADER
  end
end
