class Pictures
  include Common

  def initialize( index, name, dir, size)
    @meta = File.exist?( dir + '/meta.yaml') ? YAML.load( IO.read( dir + '/meta.yaml')) : {}
    @meta['pictures'] = [] unless @meta['pictures']
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

    chosen = select_questions( index, @meta, 'pictures', size, dir + '/meta.yaml')
    items = []
    chosen.each do |entry|
      name = entry['picture'].split('.')[0]
      items << {:title => entry['title'] ? entry['title'] : prettify( entry['picture']),
                :image => dir + '/' + name2images[entry['picture']]}
    end

    @items = items.shuffle[0...size]
    @items.each_index {|i| @items[i][:index] = i}
  end

  def copy_images( target_width, target_height, questions, output)
    @items.each_index do |i|
      copy_image( @items[i], target_width, target_height, questions, i, output)
    end
  end

  def generate( questions, image_width, image_height, output)
    prepare_images
    if @meta['table']
      image_width  = (image_width * 0.66).to_i
      image_height = (image_height * 0.66).to_i
    end
    copy_images( image_width, image_height, questions, output)
    generate_questions( questions, output)
    @title
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
                           @meta['hide_answers'] ? (clue[:title] + '?') : '',
                           item[:title],
                           io)
      end
      io.puts "</td></tr>"
    else
      io.puts "<div class=\"item\"><div class=\"number\">##{index+1} "
      write_clue_answer( index+1,
                         @meta['hide_answers'] ? '' : (clue[:title] + '?'),
                         item[:title],
                         io)
      io.puts "</div>"
      io.puts "<img src=\"#{questions}-#{index}.#{item[:image].split('.')[-1]}\"></div>"
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

  def write_image( item, id, clazz, questions, io)
    io.puts "<img id=\"#{id}\" class=\"#{clazz}\" src=\"#{questions}-#{item[:index]}.#{item[:image].split('.')[-1]}\">"
  end
end
