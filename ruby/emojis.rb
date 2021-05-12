class Emojis
  include Common

  def initialize( index, name, dir, size)
    @title = 'Find the words in these Emoji acrostics'
    defn = YAML.load( IO.read( dir))
    @title = defn['title'] if defn['title']
    @items = select_questions( index, defn, 'acrostics', size, dir)
    @emojis = YAML.load( IO.read( File.dirname(dir) + '/letters.yaml'))['letters']
  end

  def generate( questions, output)
    generate_questions( questions, output)
    @title
  end

  def generate_acrostic( word, questions, io)
    word.chars.each do |letter|
      codes = @emojis[letter.upcase].split( /\s/)
      code = codes[ rand( codes.size)]
      io.print "&#x#{code};"
    end
  end

  def generate_header( io)
    write_header( @title, 1, @items.size, io)
    answer_width = maximum_text_width( @items.collect {|item| item['answer']})
    io.puts <<"HEADER"
<table class="emojis"><tr><th>#</th><th>Acrostic</th><th>Word</th></tr>
HEADER
  end
  
  def generate_question( index, word, questions, io)
    io.puts "<tr><td>#{index}</td><td>"
    generate_acrostic( word, questions, io)
    io.print '</td><td>'
    write_clue_answer( index, '', word, io)
    io.puts "</td></tr>"
  end
  
  def generate_questions( questions, output)
    File.open( "#{output}/#{questions}.html", 'w') do |io|
      generate_header( io)
      @items.each_index do |i|
        generate_question( i+1, @items[i]['word'], questions, io)
      end
      io.puts '</table></body></html>'
    end
  end
end
