#
# Generate quiz round for Mystery Manor Quiz forum
#
# Command line arguments:
#   File / directory for quiz round
#   Quiz instance index
#   Target image width
#   Target image height
#   MM quiz number
#   Output folder
#

require 'yaml'

class MysteryManorQuiz
  def load_round( dir, index)
    if File.directory?( dir)
      @title = prettify( dir.split('/')[-1])
      defn = YAML.load( IO.read( dir + '/meta.yaml'))
      @title = defn['title'] if defn['title']

      if defn['pictures']
        @answers = []
        @items = defn['pictures'].select {|pic| was_used( pic, index)}.collect do |pic|
          @answers << prettify( pic['picture'])
          {'picture' => (dir + '/' + pic['picture'])}
        end
        @hints = @answers.sort
      else
        raise "Don't know how to load #{dir}/meta.yaml"
      end
    else
      raise "Don't know how to load #{dir}"
    end

    raise "No items found for #{dir} / #{index}" if @items.empty?
    @items.shuffle!
#    p @items
  end

  def output_answers( io)
    io.puts "index\tanswer\tgot"
    @answers.each_index do |index|
      io.puts "#{index+1}\t#{@answers[index]}\t"
    end
  end

  def output_hints( io)
    return unless defined?( @hints)
    io.puts "\nHINTS\n"
    io.puts '[list]'
    @hints.each do |hint|
      io.puts "[*]#{hint}"
    end
    io.puts '[/list]'
  end

  def output_prompt( io)
    prompt = <<PROMPT
Please put your answers in this thread, and please limit the answers to be one answer per person each day
to allow everyone to join in. Any questions either put in this thread or PM me.
PROMPT
    io.puts prompt.gsub( "\n", ' ')
    io.puts
  end

  def output_questions( mm_quiz, io)
    io.puts "QUESTIONS\n"
    pictures = @items.first['picture']
    io.puts '[list=1]' unless pictures
    @items.each_index do |index|
      item = @items[index]
      if item['picture']
        io.puts "\n[size=200]##{index+1}:[/size]"
        io.puts "[img]https://mysterymanor.net/Kickaha/#{item['scaled']}[/img]"
      else
        raise "Don't know how to output question for #{dir}"
      end
    end
    io.puts '[/list]' unless pictures
  end

  def output_title( io)
    io.puts @title
    io.puts
  end

  def prettify( text)
    text.gsub( /[_\-]/, ' ')
  end

  def scale_images( target_width, target_height, mm_index, output)
    @items.each_index do |index|
      item = @items[index]
      if item['picture']
        ext = '.jpg'
        ext = '.jpeg' unless File.exist?( item['picture'] + ext)
        item['scaled'] = "Quiz#{mm_index}#{"ABCDEFGHIJKL"[index..index]}#{ext}"

        if not system( "sips -g pixelHeight -g pixelWidth -g orientation " + item['picture'] + ext + " >/tmp/sips.log")
          raise "Error running sips on: " + item[:image]
        end

        image_height,image_width = 0,0
        IO.readlines( "/tmp/sips.log").each do |line|
          if m = /pixelHeight: (\d*)$/.match( line.chomp)
            image_height = m[1].to_i
          end
          if m = /pixelWidth: (\d*)$/.match( line.chomp)
            image_width = m[1].to_i
          end
        end

        raise "Bad image file: #{item['picture']}" unless image_width * image_height > 0

        if (target_width * 1.0) / image_width < (target_height * 1.0) / image_height
          w = target_width
          h = image_height * (target_width * 1.0) / image_width
        else
          h = target_height
          w = image_width * (target_height * 1.0) / image_height
        end

        if ! system( "/bin/csh scale.csh #{item['picture']}#{ext} #{output}/#{item['scaled']} #{w.to_i} #{h.to_i}")
          raise "Error scaling #{item['picture']}"
        end

        item['ext'] = ext
      end
    end
  end

  def was_used( item, index)
    return false unless item['used']
    used = item['used'].to_s.split( ' ')
    used.include?( index.to_s)
  end
end

srand 1037
bbc = MysteryManorQuiz.new
bbc.load_round( ARGV[0], ARGV[1])
bbc.scale_images( ARGV[2].to_i, ARGV[3].to_i, ARGV[4].to_i, ARGV[5])

File.open( ARGV[5] + "/Quiz#{ARGV[4]}.txt", 'w') do |io|
  bbc.output_title( io)
  bbc.output_prompt( io)
  bbc.output_questions( ARGV[4].to_i, io)
  bbc.output_hints( io)
end

File.open( ARGV[5] + "/Quiz#{ARGV[4]}.csv", 'w') do |io|
  bbc.output_answers( io)
end