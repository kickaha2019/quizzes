require 'fileutils'

class Sounds
  include Common

  def initialize( index, name, dir, size)
    @meta = File.exist?( dir + '/meta.yaml') ? YAML.load( IO.read( dir + '/meta.yaml')) : {}
    @meta['sounds'] = [] unless @meta['sounds']
    @multiple_choice = @meta['multiple_choice']
    @title = @meta['title'] ? @meta['title'] : ('Match the name to the sound for some ' + name)
    @product = @meta['product'] ? @meta['product'] : name

    known_audios = {}
    @meta['sounds'].each do |known|
      known_audios[known['sound'].gsub( ' ', '_')] = true
    end

    name2audios = {}
    Dir.entries( dir).each do |f|
      if m = /^(.*)_snippet\.mp3/i.match(f)
        name = m[1].gsub( ' ', '_')
        name2audios[name] = f
        unless known_audios[name]
          @meta['sounds'] << {'sound' => name}
        end
      end
    end

    @all_titles = @meta['sounds'].collect {|pic| title(pic)}

    chosen = select_questions( index, @meta, 'sounds', size, dir + '/meta.yaml')
    items = []
    chosen.each do |entry|
      items << {:title   => title(entry),
                :audio   => dir + '/' + name2audios[entry['sound']],
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

  def copy_audios( questions, output)
    @items.each_index do |index|
      item = @items[index]
      item[:output] = "#{questions}-#{index}.#{item[:audio].split('.')[-1]}"
      FileUtils.cp( item[:audio], output + '/' + item[:output])
    end
  end

  def generate( questions, output)
    copy_audios( questions, output)
    generate_questions( questions, output)
    @title
  end

  def generate_header( io)
    write_header( @title, 1, @items.size, io)
    io.puts <<"HEADER"
<table><tr><th>#</th><th>#{@product}</th><th>Theme</th></tr>
HEADER
  end
  
  def generate_item( item, index, clue, questions, io)
    io.puts "<tr><td>#{index+1}</td><td>"
    write_clue_answer( index+1,
                       "???",
                       item[:title],
                       io)
    io.puts "</td><td>"
    write_audio( item, io)
    io.puts "</td></tr>"
  end
  
  def generate_questions( questions, output)
    File.open( "#{output}/#{questions}.html", 'w') do |io|
      generate_header( io)

      clues = shuffle_answers( @items)

      @items.each_index do |i|
        generate_item( @items[i], i, clues[i], questions, io)
      end

      io.puts( '</table>')
      io.puts '</div></body></html>'
    end
  end

  def title( entry)
    entry['title'] ? entry['title'] : prettify( entry['sound'])
  end

  def write_audio( item, io)
    io.puts <<"AUDIO_BUTTON"
<button class="audio" onclick="play_sound( '#{item[:output]}')">
Play
</button>
AUDIO_BUTTON
  end
end
