class JoiningWords
  include Common

  def initialize( index, dir, size)
    @title = 'Find words which join two other words'
    defn = YAML.load( IO.read( @dir = dir))
    @title = defn['title'] if defn['title']

    @items = select_questions( index, defn, 'links', size, dir)
    raise "Not enough questions for #{dir}" unless @items.size >= size
  end

  def generate( questions, output)
    File.open( "#{output}/#{questions}.html", 'w') do |io|
      generate_header( io)

      @items.each_index do |i|
        left, join, right = * @items[i]['words']
        generate_item( i+1, left, join, right, io)
      end

      io.puts '</table></body></html>'
    end
    @title
  end

  def generate_header( io)
    write_header( @title, 0, @items.size, io)
    io.puts <<TABLE1
<table><tr><th>#</th><th align="right">Left</th><th align="center">Join</th><th>Right</th></tr>
TABLE1
    io.puts '</th></tr>'
  end
  
  def generate_item( index, left, join, right, io)
    io.puts <<ITEM1
<tr><td>#{index}</td><td align="right">#{left}</td><td align="center">
ITEM1
    write_clue_answer( index-1, '-' * join.size, join, io)
    io.puts <<ITEM2
</td><td>#{right}</td></tr>
ITEM2
  end
end
