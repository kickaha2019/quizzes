#
# Useful methods
#
require 'yaml'

module Common
  def copy_image( item, target_width, target_height, questions, index, output)
    image_width   = item[:width]
    image_height  = item[:height]
    item[:output] = "#{questions}-#{index}.#{item[:image].split('.')[-1]}"

    if (target_width * 1.0) / image_width < (target_height * 1.0) / image_height
      w = target_width
      h = image_height * (target_width * 1.0) / image_width
    else
      h = target_height
      w = image_width * (target_height * 1.0) / image_height
    end
    if ! system( "/bin/csh scale.csh #{item[:image]} #{output}/#{item[:output]} #{w.to_i} #{h.to_i}")
      raise "Error scaling #{item[:image]}"
    end
  end

  def get_common_prefix( s1, s2)
    i = 0
    s1, s2 = s1.downcase, s2.downcase
    while (i < s1.size) && (i < s2.size)
      if (s1[i] == s2[i])
        i += 1
      else
        break
      end
    end
    (i > 0) ? s1[0...i] : ''
  end

  def get_common_postfix( s1, s2)
    get_common_prefix( s1.reverse, s2.reverse).reverse
  end

  def maximum_text_width( texts)
    w = 20 * texts.inject(0) {|v,i| (v < i.to_s.size) ? i.to_s.size : v}
    (w < 700) ? w : 700
  end

  def prepare_image( item)
    if not system( "sips -g pixelHeight -g pixelWidth -g orientation " + item[:image] + " >/tmp/sips.log")
      raise "Error running sips on: " + item[:image]
    end
    
    h,w = 0,0
    IO.readlines( "/tmp/sips.log").each do |line|
      if m = /pixelHeight: (\d*)$/.match( line.chomp)
        h = m[1].to_i
      end
      if m = /pixelWidth: (\d*)$/.match( line.chomp)
        w = m[1].to_i
      end
    end
    
    raise "Bad image file: #{item[:image]}" unless w * h > 0
    item[:width]  = w
    item[:height] = h
  end
  
  def prettify( text)
    text.gsub( /[_\-\+]/, ' ')
  end

  def select_questions( index, defn, key, size, path)
    raise "Not enough questions for #{path}" unless defn[key].size >= size
    return shuffle( defn, defn[key], size) unless /^\d+$/ =~ index

    items = defn[key].select {|item| item['used'].to_s.split( ' ').include?( index.to_s)}
    return shuffle( defn, items, size) if items.size >= size

    items = defn[key].select {|item| item['used'].nil?}
    if items.size >= size
      chosen = shuffle( defn, items, size)
    else
      items = defn[key].sort_by do |item|
        if item['used']
          item['used'].to_s.split( ' ')[-1].to_i
        else
          0
        end
      end

      if items.size > 2 * size
        chosen = shuffle( defn, items[0...(items.size/2)], size)
      elsif items.size < size
        raise "Not enough questions for #{path}"
      else
        chosen = shuffle( defn, items, size)
      end
    end

    chosen.each do |item|
      if item['used']
        item['used'] = item['used'].to_s + " #{index}" unless item['used'].to_s.split(' ').include?( index.to_s)
      else
        item['used'] = index
      end
    end
    File.open( path, 'w') {|io| io.puts( defn.to_yaml)}
    chosen
  end

  def shuffle( defn, items, size)
    return items.shuffle[0...size] unless defn['shuffle'] === false
    items = items.collect {|i| i}
    while items.size > size
      items.delete_at( rand( items.size))
    end
    items
  end

  def shuffle_answers( answers)
    best = nil
    diff = -1
    (0..9).each do
      titles = answers.shuffle
      d = 0
      (0...answers.size).each do |i|
        d += 1 unless titles[i] == answers[i]
      end
      if d > diff
        best = titles
        diff = d
      end
    end
    best
  end

  def write_clue_answer( index, clue, answer, io)
    io.print <<"ITEM"
<span id="c#{index}" class=\"clue\">#{clue}</span><span id="a#{index}" class=\"answer\">#{answer}</span>
ITEM
  end

  def write_header( title, from, to, io)
    write_header_base( title, io)
    io.puts <<"HEADER1"
<script>
    let item = #{from};

    function hide( eid) {
      document.getElementById( eid).style.display = 'none';
    }

    function fade_clue() {
      document.getElementById( "c" + item).style.opacity = 0;
    }

    function show_answer() {
      hide( "c" + item);
      document.getElementById( "a" + item).style.display = 'inline';
      document.getElementById( "a" + item).style.opacity = 1;
      item = item + 1;
    }

    function reveal() {
      hide( 'button');
HEADER1

    (from..to).each do |i|
      io.puts "setTimeout( fade_clue, #{i * 600 - 300});"
      io.puts "setTimeout( show_answer, #{i * 600});"
    end

    io.puts <<"HEADER2"
    }
</script>
</head><body>
<table class="header">
<tr><td class="left"></td>
<td class="middle"><div class="title">#{prettify(title)}</div></td>
<td class="right" style="min-height: 67px"><button id="button" onclick="reveal()">Answers</button></td>
</table>
HEADER2
  end

  def write_header_base( title, io)
    io.puts <<"HEADER3"
<html><head>
<title>#{prettify(title)}</title>
<style>
@keyframes overlaid {
  0% {opacity: 0}
  10% {opacity: 1}
  90% {opacity: 1}
  100% {opacity: 0}
}
div.number {font-weight: bold; font-size: 24px; padding-bottom: 5px;}
div.item {border: solid 1px black; margin: 10px; padding: 10px; display: inline-block;}
div.overlaid {position: absolute; top: -20px; left: -20px; 
              margin: 10px; padding: 10px; 
}
div.overlaid span {color: black; background: white; font-size: 30px;
                   border: solid 1px black;}
div.dummy {
              animation-name: overlaid; animation-duration: 2s; 
              animation-iteration-count: infinite;
              animation-timing-function: linear
}
div.items {display: flex; flex-direction: row; flex-wrap: wrap;
           align-items: flex-start}
table.header {width: 100%}
table.header td {border-width: 0px}
td.left, td.right {width: 10%}
div.title {width: 100%; text-align: center; font-size: 30px; text-decoration: none; margin-bottom: 15px; font-weight: bold}
div.answers {width: 100%; text-align: center; font-size: 30px; text-decoration: none; margin-bottom: 15px}
button {text-align: right; font-size: 25px; text-decoration: none; margin-bottom: 17px; font-weight: bold; background-color: cyan;
        border-radius: 5px; border-color: cyan}
table {border-spacing: 0px; border-collapse: collapse; margin-left: auto; margin-right: auto}
th {font-weight: bold}
td, th {padding: 5px; border-style: solid; font-size: 40px;
        border-width: 1px; border-color: black}
table.rebus td, table.rebus th {font-size: 60px}
table.emojis td, table.emojis th {font-size: 40px}
span.rebus {font-size: 120px; font-family: Courier, monospace}
span.minus {position: relative; left: -72px; color: red; font-weight: normal}
div.rebus {border: solid 1px black; margin: 10px; padding: 10px; 
           display: flex; flex-direction: row; position: relative; 
           align-items: center; justify-content: middle}
div.minus {display: inline-block; width: 72px}
td:first-child {text-align: center}
.answer {display: none; opacity: 0}
span.box {font-size: 30px; text-decoration: none; font-weight: bold; background-color: blue;
          border-radius: 5px; border-color: blue; color: yellow; padding: 5px}
td.box {padding-bottom: 10px}
span.box b {color: white; text-decoration: underline}
table.word_search td {border-width: 0px; vertical-align: top}
table.grid td {border-width: 1px; text-align: center}
table.hidden td {border-width: 1px; text-align: left}
div.notes {margin-left: auto; margin-right: auto; font-size: 30px; padding-top: 20px;
           max-width: 80%}
</style>
HEADER3
  end

  def write_item( index, prompt, clue, answer, io)
    io.puts <<"ITEM"
<tr>
  <td>#{index}</td>
  <td>#{prompt}</td><td>
ITEM
    write_clue_answer( index, clue, answer, io)
    io.puts '</td></tr>'
  end
end
