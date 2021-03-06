class LetterChange
  include Common

  def initialize( date, name, dir, size)
    @title = 'Change a letter and change the meaning'
    defn = YAML.load( IO.read( dir))
    @title = defn['title'] if defn['title']
    # @items = defn['phrases'].shuffle[0...size]
    @items = select_questions( date, defn, 'words', size, dir)
    raise "Not enough questions for #{dir}" unless @items.size >= size
  end

  def generate( questions, output)
    File.open( "#{output}/#{questions}.html", 'w') do |io|
      generate_header( io)

      @items.each_index do |i|
        io.puts "<tr><td>#{i+1}</td><td>#{@items[i]['before']}</td><td>"
        write_clue_answer( i+1, @items[i]['after'].gsub( /./, '.'), @items[i]['after'], io)
        io.puts "</td><td>#{@items[i]['clue']}</td></tr>"
      end

      io.puts '</table></body></html>'
    end
    @title
  end

  def generate_header( io)
    write_header( @title, 1, @items.size, io)
    answer_width = maximum_text_width( @items.collect {|item| item['after']})
    io.puts <<"HEADER"
<table>
<tr><th>#</th><th>Before</th><th style="min-width: #{answer_width}px">Answer</th><th>Clue</th></tr>
HEADER
  end
end
