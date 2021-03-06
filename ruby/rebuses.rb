class Rebuses
  include Common

  def initialize( date, name, dir, size)
    @title = 'Solve the rebuses for the names of ' + name
    defn = YAML.load( IO.read( dir))
    @title = defn['title'] if defn['title']
    # @items = defn['rebuses'].shuffle[0...size]
    @items = select_questions( date, defn, 'rebuses', size, dir)
  end

  def copy_images( target_height, questions, output)
    @images.each_value do |image|
      copy_image( image, 10000, target_height, questions, image[:index], output)
    end
  end

  def generate( questions, rebus_height, output)
    prepare_images
    copy_images( rebus_height, questions, output)
    generate_questions( questions, output)
    @title
  end

  def generate_header( io)
    write_header( @title, 1, @items.size, io)
    answer_width = maximum_text_width( @items.collect {|item| item['answer']})
    io.puts <<"HEADER"
<table class="rebus"><tr><th>#</th><th>Rebus</th><th style="min-width: #{answer_width}px">Answer</th></tr>
HEADER
  end
  
  def generate_question( index, rebus, answer, questions, io)
    io.puts "<tr><td>#{index}</td><td>"
    generate_rebus( rebus, questions, io)
    io.puts "</td><td>"
    write_clue_answer( index, '', answer, io)
    io.puts "</td></tr>"
  end
  
  def generate_questions( questions, output)
    File.open( "#{output}/#{questions}.html", 'w') do |io|
      generate_header( io)
      @items.each_index do |i|
        generate_question( i+1, @items[i]['rebus'], @items[i]['answer'], questions, io)
      end
      io.puts '</table></body></html>'
    end
  end

  def generate_rebus( rebus, questions, io)
    io.puts '<div class="rebus">'
    separ = ''
    rebus.split( /\s+/).each do |word|
      io.print separ
      separ = '&nbsp;'
      if /^\+/ =~ word
        io.print "<span class=\"rebus plus\">#{word[1..-1].upcase}</span>"
      elsif /^\-/ =~ word
        #image = @images['-elide']
        #io.print "<div><span class=\"plus\">#{word[1..-1]}</span><img class=\"minus\" src=\"#{questions}-#{image[:index]}.png\"></div>"
        io.print "<div class=\"minus\"><span class=\"rebus plus\">#{word[1..-1].upcase}</span><span class=\"rebus minus\">/</span></div>"
      elsif /^\w\->$/ =~ word
        io.print "<span class=\"rebus plus\">#{word[0..0].upcase}</span>"
        image = @images['-becomes']
        io.print "<img width=\"30\" height=\"25\" src=\"#{questions}-#{image[:index]}.jpg\">"
      elsif /^\w\->\w$/ =~ word
        io.print "<span class=\"rebus plus\">#{word[0..0].upcase}</span>"
        image = @images['-becomes']
        io.print "<img width=\"30\" height=\"25\" src=\"#{questions}-#{image[:index]}.jpg\">"
        io.print "<span class=\"rebus plus\">#{word[3..3].upcase}</span>"
      else
        image = @images[word]
        io.print "<img src=\"#{questions}-#{image[:index]}.jpg\">"
      end
    end
    io.puts '<div>'
  end

  def prepare_images
    @images = {}
    @images['-elide'] = {image:'rebuses/elide.png', index:0}
    @images['-becomes'] = {image:'rebuses/becomes.jpg', index:1}

    @items.each do |item|
      item['rebus'].split( /\s+/).each do |word|
        unless (/[\-\+\>]/ =~ word) || @images[word]
          @images[word] = {:image => 'rebuses/images/' + word.capitalize + '.jpg',
                           :index => @images.size}
        end
      end
    end

    @images.each_value {|image| prepare_image( image)}
  end
end
