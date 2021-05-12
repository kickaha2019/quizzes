class Questions
  include Common

  def initialize( index, name, dir, size)
    @title = 'Answer some questions about ' + name
    @dir   = dir
    defn   = YAML.load( IO.read( dir))
    @title = defn['title'] if defn['title']

    # @items = defn['questions'].shuffle[0...size]
    @items = select_questions( index, defn, 'questions', size, dir)
  end

  def generate( questions, output)
    File.open( "#{output}/#{questions}.html", 'w') do |io|
      generate_header( io)

      @items.each_index do |i|
        write_item( i+1,
                    @items[i]['question'],
                    @items[i]['prompt'] ? @items[i]['prompt'] : '',
                    @items[i]['answer'].to_s,
                    io)
      end

      io.puts '</table></body></html>'
    end

    @title
  end

  def generate_header( io)
    write_header( @title, 1, @items.size, io)
    answer_width = maximum_text_width( @items.collect{ |item| item['answer']})
    io.puts <<"HEADER"
<table>
<tr><th>#</th><th>Question</th><th style="min-width: #{answer_width}px">Answer</th></tr>
HEADER
  end
end
