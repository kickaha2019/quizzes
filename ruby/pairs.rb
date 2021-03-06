class Pairs
  include Common

  def initialize( date, name, dir, size)
    @dir = dir
    defn = YAML.load( IO.read( dir))

    # chosen = defn['pairs'].shuffle[0...size]
    chosen = select_questions( date, defn, 'pairs', size, dir)

    if defn['shuffle'] === false
      @items = []
      key    = chosen[0].keys[0]
      chosen = chosen.collect {|item| item[key]}
      defn['pairs'].each do |item|
        @items << item if chosen.include?( item[key])
      end
    else
      @items = chosen
    end
    raise "Not enough questions for #{dir}" unless @items.size >= size

    q_key, a_key = get_keys
    @title = "Work out the #{a_key} from a #{q_key} for some " + name
    @title = defn['title'] if defn['title']
  end

  def generate( questions, output)
    q_key, a_key = get_keys
    prompts = generate_prompts

    File.open( "#{output}/#{questions}.html", 'w') do |io|
      generate_header( '<th></th>', io)

      @items.each_index do |i|
        answer = @items[i][a_key].to_s.sub( '#', '-')
        if /\|/ =~ answer
          #p answer.split('|').select {|a| /^\*/ =~ a}[0]
          answer = answer.split('|').select {|a| /^\*/ =~ a}[0][1..-1]
        end
        generate_item( i+1, @items[i][q_key], prompts[i], answer, io)
      end

      io.puts '</table></body></html>'
    end

    @title
  end

  def generate_header( inject, io)
    write_header( @title, 1, @items.size, io)

    q_key, a_key = get_keys
    answer_width = maximum_text_width( @items.collect{ |item| item[a_key] + '?'})
    io.puts <<"HEADER"
<table>
<tr><th>#</th><th>#{prettify(q_key.capitalize)}</th><th style="min-width: #{answer_width}px">#{prettify(a_key.capitalize)}</th></tr>
HEADER
  end
  
  def generate_item( index, prompt, clue, answer, io)
    write_item( index, prompt, clue, answer, io)
  end

  def generate_prompts
    q_key, a_key = get_keys

    prompts = shuffle_answers( @items.collect {|item| item[a_key]}).collect {|answer| answer.split('#')[0].strip + '?'}

    @items.each_index do |index|
      item = @items[index]

      if /\|/ =~ item[a_key]
        prompts[index] = item[a_key].split('|').collect {|poss| poss.gsub('*','') + '?'}.join('&nbsp;&nbsp;')
      end
    end

    prompts
  end

  def get_keys
    q_key = a_key = nil
    @items.each do |item|
      if q_key.nil?
        q_key = item.keys[0]
      elsif q_key != item.keys[0]
        raise "Inconsistent keys for #{@dir}"
      end
      if a_key.nil?
        a_key = item.keys[1]
      elsif a_key != item.keys[1]
        raise "Inconsistent keys for #{@dir}"
      end
    end
    return q_key, a_key
  end
end
