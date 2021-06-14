class MissingWord
  include Common

  def initialize( index, dir, size)
    @title = 'Find words which can go before or after to form other words or phrases'
    defn = YAML.load( IO.read( @dir = dir))
    @title = defn['title'] if defn['title']

    @items = select_questions( index, defn, 'groups', size, dir)
    #@items = defn['groups'].shuffle[0...size]
    raise "Not enough questions for #{dir}" unless @items.size >= size
  end

  def box_list( texts, prefix=0, postfix=0)
    texts.collect do |t|
      t = "<b>#{t[0...prefix]}</b>#{t[prefix..-1]}"      if prefix > 0
      t = "#{t[0...-postfix]}<b>#{t[-postfix..-1]}</b>" if postfix > 0
      "<span class=\"box\">#{t}</span>"
    end.join( '&nbsp;')
  end

  def generate( questions, output)
    File.open( "#{output}/#{questions}.html", 'w') do |io|
      generate_header( io)

      @items.each_index do |i|
        phrases = @items[i]['phrases']

        start = finish = phrases[0]
        phrases.each do |phrase|
          start = get_common_prefix( start, phrase)
          finish = get_common_postfix( finish, phrase)
        end

        if start.size >= finish.size
          finish = ''
        else
          start = ''
        end

        clues = phrases.collect {|phrase| phrase[(start.size)..(-1-finish.size)].strip.downcase}
        generate_item( i+1, box_list( clues), box_list( @items[i]['phrases'], start.size, finish.size), io)
      end

      io.puts '</table></body></html>'
    end
    @title
  end

  def generate_header( io)
    write_header( @title, 0, @items.size, io)
    answer_width = maximum_text_width( @items.collect{ |item| item['phrases'].join( ' ')})
    io.puts "<table><tr><th>#</th><th style=\"min-width: #{answer_width}px\">"
    write_clue_answer( 0, 'Part phrases / words', 'Complete phrases / words', io)
    io.puts '</th></tr>'
  end
  
  def generate_item( index, clues, answers, io)
    io.puts "<tr><td>#{index}</td><td class=\"box\">"
    write_clue_answer( index, clues, answers, io)
    io.puts "</td></tr>"
  end
end
