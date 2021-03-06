class Reveals
  include Common

  def initialize( date, name, dir, size)
    @meta = File.exist?( dir + '/meta.yaml') ? YAML.load( IO.read( dir + '/meta.yaml')) : {}
    @meta['pictures'] = [] unless @meta['pictures']
    @title = @meta['title'] ? @meta['title'] : ('From an image guess the ' + name)

    known_images = {}
    @meta['pictures'].each do |known|
      known_images[known['picture'].gsub( ' ', '_')] = true
    end

    Dir.entries( dir).each do |f|
      if m = /^(.*)_answer\.(jpg|png|jpeg|gif)$/i.match( f)
        name = m[1].gsub( ' ', '_')
        unless known_images[name]
          @meta['pictures'] << {'picture' => name}
        end
      end
    end

    chosen = select_questions( date, @meta, 'pictures', size, dir + '/meta.yaml')
    chosen_names = {}
    chosen.each {|entry| chosen_names[entry['picture'].gsub( ' ', '_')] = true}

    items = []
    Dir.entries( dir).each do |f|
      if m = /^(.*)_answer\.(jpg|png|jpeg|gif)$/i.match( f)
        name = m[1]
        if chosen_names[name.gsub( ' ', '_')]
          items << {:title => prettify(name),
                    :image => dir + '/' + f}
        end
      end
    end

    @answers = items.shuffle[0...size]
    @clues   = @answers.collect {|a| {:image => a[:image].gsub( '_answer.', '_clue.')}}
  end

  def copy_images( target_width, target_height, questions, output)
    @answers.each_index do |i|
      copy_image( @answers[i], target_width, target_height, questions, i, output)
    end
    @clues.each_index do |i|
      copy_image( @clues[i], target_width, target_height, questions, @answers.size + i, output)
    end
  end

  def generate( questions, image_width, image_height, output)
    prepare_images
    copy_images( image_width, image_height, questions, output)
    generate_questions( image_width, image_height, questions, output)
    @title
  end

  def generate_header( io)
    write_header( @title, 1, 2 * @answers.size, io)
    io.puts <<"HEADER"
<div class="items">
HEADER
  end
  
  def generate_item( index, image_width, image_height, questions, io)
    m = /^.*\/(.*)_answer\.(.*)$/.match( @answers[index][:image])
    name, ext = m[1], m[2]
    io.puts "<div class=\"item\"><div class=\"number\">"
    io.puts "<span id=\"c#{2*index+1}\" class=\"clue\">##{index+1}:</span>"
    io.puts "<span id=\"a#{2*index+1}\" class=\"answer\">##{index+1}: #{prettify(name)}</span>"
    io.puts "</div><div style=\"min-width: #{image_width}px; min-height: #{image_height}px\">"
    io.puts "<img id=\"c#{2*index+2}\" class=\"clue\" src=\"#{questions}-#{index+@answers.size}.#{ext}\">"
    io.puts "<img id=\"a#{2*index+2}\" class=\"answer\" src=\"#{questions}-#{index}.#{ext}\">"
    io.puts "</div></div>"
  end
  
  def generate_questions( image_width, image_height, questions, output)
    File.open( "#{output}/#{questions}.html", 'w') do |io|
      generate_header( io)

      @answers.each_index do |i|
        generate_item( i, image_width, image_height, questions, io)
      end
      
      io.puts '</div></body></html>'
    end
  end

  def prepare_images
    @answers.each {|item| prepare_image( item)}
    @clues.each {|item| prepare_image( item)}
  end
end
