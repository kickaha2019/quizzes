class Pictures
  include Common

  def initialize( index, name, dir, size)
    @meta = File.exist?( dir + '/meta.yaml') ? YAML.load( IO.read( dir + '/meta.yaml')) : {}
    @meta['pictures'] = [] unless @meta['pictures']
    @multiple_choice = @meta['multiple_choice']
    @title = @meta['title'] ? @meta['title'] : ('Match the name to the picture for some ' + name)

    known_images = {}
    @meta['pictures'].each do |known|
      known_images[known['picture'].gsub( ' ', '_')] = true
    end

    name2images = {}
    Dir.entries( dir).each do |f|
      if /\.(jpg|png|jpeg|gif)$/i =~ f
        name = f.split('.')[0].gsub( ' ', '_')
        name2images[name] = f
        unless known_images[name]
          @meta['pictures'] << {'picture' => name}
        end
      end
    end

    @all_titles = @meta['pictures'].collect {|pic| title(pic)}

    chosen = select_questions( index, @meta, 'pictures', size, dir + '/meta.yaml')
    items = []
    chosen.each do |entry|
      name = entry['picture'].split('.')[0]
      items << {:title  => title(entry),
                :image  => dir + '/' + name2images[entry['picture']],
                :options => entry['options']}
    end

    @items = items.shuffle[0...size]
    @items.each_index {|i| @items[i][:index] = i}

    if @multiple_choice
      @options = @items.collect do |item|
        t = item[:title]
        alts = item[:options] ? item[:options].split('|') : (@all_titles - [t])
        ([t] + alts.shuffle[0..(@multiple_choice-2)]).shuffle
      end
    end
  end

  def copy_images( target_width, target_height, questions, output)
    @items.each_index do |i|
      copy_image( @items[i], target_width, target_height, questions, i, output)
    end
  end

  def generate( questions, image_width, image_height, output)
    prepare_images
    if @meta['large']
      image_width  = (image_width * 3).to_i
      image_height = (image_height * 3).to_i
    elsif @multiple_choice
      image_width  = (image_width * 3).to_i
      image_height = (image_height * 3).to_i
    elsif @meta['table']
      image_width  = (image_width * 0.66).to_i
      image_height = (image_height * 0.66).to_i
    end
    copy_images( image_width, image_height, questions, output)
    generate_questions( questions, output)
    @title
  end

  def generate_answer( index, answer)
    if @multiple_choice
      key = ''
      @options[index].each_index do |i|
        key = "ABCDEF"[i..i] if @options[index][i] == answer
      end
      key + ': ' + answer
    else
      answer
    end
  end

  def generate_clue( index, clue)
    return '' if @meta['hide_answers']
    if @multiple_choice
      text = []
      @options[index].each_index do |i|
        text << ("ABCDEF"[i..i] + ': ' + @options[index][i])
      end
      text.join( '<BR>')
    else
      (clue[:title] + '?')
    end
  end

  def generate_header( io)
    write_header( @title, 1, @items.size, io)
    if @meta['table']
      io.puts <<"HEADER"
<table><tr><th>#</th><th>#{@meta['clue_name']}</th><th>#{@meta['answer_name']}</th></tr>
HEADER
    else
      io.puts '<div class="items">'
    end
  end
  
  def generate_item( item, index, clue, questions, io)
    if @meta['table']
      io.puts "<tr><td>#{index+1}</td><td>"
      if @meta['invert']
        io.puts item[:title]
      else
        write_image( item, "i#{index+1}", '', questions, io)
      end
      io.puts "</td><td>"
      if @meta['invert']
        write_image( item,  "a#{index+1}", 'answer', questions, io)
        write_image( clue,  "c#{index+1}", 'clue', questions, io)
      else
        write_clue_answer( index+1,
                           generate_clue( index, clue),
                           generate_answer( index, item[:title]),
                           io)
      end
      io.puts "</td></tr>"
    else
      io.puts "<div class=\"item\"><div class=\"number\">##{index+1} "
      unless @multiple_choice
        write_clue_answer( index+1,
                           generate_clue( index, clue),
                           generate_answer( index, item[:title]),
                           io)
      end
      io.puts "</div>"
      io.puts "<img src=\"#{questions}-#{index}.#{item[:image].split('.')[-1]}\">"
      if @multiple_choice
        io.puts "<div class=\"number\">"
        write_clue_answer( index+1,
                           generate_clue( index, clue),
                           generate_answer( index, item[:title]),
                           io)
        io.puts "</div>"
      end
      io.puts "</div>"
    end
  end
  
  def generate_questions( questions, output)
    File.open( "#{output}/#{questions}.html", 'w') do |io|
      generate_header( io)

      clues = shuffle_answers( @items)

      @items.each_index do |i|
        generate_item( @items[i], i, clues[i], questions, io)
      end

      io.puts( @meta['table'] ? '</table>' : '</div>')
      io.puts '</div></body></html>'
    end
  end

  def prepare_images
    @items.each {|item| prepare_image( item)}
  end

  def title( entry)
    entry['title'] ? entry['title'] : prettify( entry['picture'])
  end

  def write_image( item, id, clazz, questions, io)
    io.puts "<img id=\"#{id}\" class=\"#{clazz}\" src=\"#{questions}-#{item[:index]}.#{item[:image].split('.')[-1]}\">"
  end
end
