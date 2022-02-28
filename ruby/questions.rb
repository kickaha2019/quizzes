class Questions
  include Common

  def initialize( index, name, dir, size)
    @title = 'Answer some questions about ' + name
    @dir   = dir
    defn   = YAML.load( IO.read( dir))
    @title = defn['title'] if defn['title']

    @multiple_choice = defn['multiple_choice']
    # @items = defn['questions'].shuffle[0...size]
    @items = select_questions( index, defn, 'questions', size, dir)
  end

  def generate( questions, output)
    File.open( "#{output}/#{questions}.html", 'w') do |io|
      generate_header( io)

      @items.each_index do |i|
        if @multiple_choice
          wrong_answers = @items[i]['prompt'].split('|')
          answer_index  = rand( 1 + wrong_answers.size)
          answer        = "ABC"[answer_index..answer_index] + ': ' + @items[i]['answer'].to_s
          prompt        = nil
          (0...answer_index).each do |i|
            prompt = (prompt.nil? ? '' : (prompt + '<BR>')) + "ABC"[i..i] + ': ' + wrong_answers[i]
          end
          prompt = (prompt.nil? ? '' : (prompt + '<BR>')) + answer
          (answer_index...(wrong_answers.size)).each do |i|
            prompt = prompt + '<BR>' + "ABC"[(i+1)..(i+1)] + ': ' + wrong_answers[i]
          end
        else
          answer = @items[i]['answer'].to_s
          prompt = @items[i]['prompt'] ? @items[i]['prompt'] : ''
        end
        write_item( i+1,
                    @items[i]['question'],
                    prompt,
                    answer,
                    io)
      end

      io.puts '</table></body></html>'
    end

    @title
  end

  def generate_header( io)
    write_header( @title, 1, @items.size, io)
    possibles = @items.collect{ |item| item['answer']}
    if @multiple_choice
      @items.each do |item|
        possibles += item['prompt'].split('|')
      end
    end
    answer_width = maximum_text_width( possibles)
    io.puts <<"HEADER"
<table>
<tr><th>#</th><th>Question</th><th style="min-width: #{answer_width}px">Answer</th></tr>
HEADER
  end
end
