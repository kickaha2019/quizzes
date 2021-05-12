class WordSearch
  include Common

  ALPHABET = 'abcdefghijklmnopqrstuvwxyz'
  COLOURS  = ['red', 'magenta', 'green', 'cyan', 'blue', 'orange', 'purple', 'lime']

  class Cell
    attr_reader :letter, :used

    def initialize
      @letter = ' '
      @used   = [false, false, false, false]
    end

    def feasible( letter, angle)
      return false if @used[angle]
      (@letter == letter) || (@letter == ' ')
    end

    def fill
      if @letter == ' '
        @letter = ALPHABET[ rand( ALPHABET.size)]
      end
    end

    def filled?
      @letter != ' '
    end

    def set_letter( letter)
      @letter = letter
    end

    def set_used( angle)
      @used[angle] = true
    end
  end

  class Square
    attr_reader :width

    def initialize( width)
      @width   = width
      @letters = []
      (0...width).each do |i|
        @letters << row = []
        (0...width).each {row << Cell.new}
      end
    end

    def cell( i, j)
      return nil if (i < 0) || (j < 0) || (i >= @width) || (j >= @width)
      @letters[i][j]
    end

    def feasible( x, y, dx, dy, angle, word)
      (0...(word.size)).each do |i|
        if c = cell( x + dx * i, y + dy * i)
          return false unless c.feasible( word[i..i], angle)
        else
          return false
        end
      end
      true
    end

    def fill
      @letters.each do |row|
        row.each do |cell|
          cell.fill
        end
      end
    end

    def mark( i, j)
      cell( i, j).mark
    end

    def score
      nice = (@width - 2) * (@width - 2)

      (0..(@width-3)).each do |x|
        (0..(@width-3)).each do |y|
          filled = 0
          (0..2).each do |i|
            (0..2).each do |j|
              filled += 1 if cell(x+i,y+j).filled?
            end
          end
          nice -= 1 if filled > 5
        end
      end

      nice
      # total = 0
      # @letters.each do |row|
      #   row.each do |cell|
      #     total += 1 if cell.letter != ' '
      #   end
      # end
      # total
    end

    def set( x, y, dx, dy, angle, word)
      (0...(word.size)).each do |i|
        cell( x + dx * i, y + dy * i).set_letter( word[i..i])
      end
      ((-@width)..@width).each do |i|
        if c = cell( x + dx * i, y + dy * i)
          c.set_used( angle)
        end
      end
    end

    def to_grid
      @letters.collect do |row|
        row.collect {|cell| cell.letter.upcase}.join( '')
      end
    end
  end

  def initialize( index, name, dir, size)
    @title = 'Find names of ' + name
    @defn  = YAML.load( IO.read( dir))
    @title = @defn['title'] if @defn['title']
    @cell  = 75
    @size  = size

    unless @defn['grid']
      generate_grid( @defn, size)
      if /^\d+$/ =~ index
        @defn['used'] = index
      end
      File.open( dir, 'w') {|io| io.print @defn.to_yaml}
    end
  end

  def add_word( square, counts, word)
    poss       = 0
    location   = nil
    locn_count = 100
    #calls      = 0

    runs( square.width) do |x, y, dx, dy, angle|
      #calls += 1
      #puts "Call #{calls}"
      if square.feasible( x, y, dx, dy, angle, word)
        next if counts[angle] > locn_count
        if counts[angle] < locn_count
          poss = 0
          locn_count = counts[angle]
        end

        poss += 1
        if rand(poss) == 0
          location = [x, y, dx, dy, angle]
        end
      end
    end

    if location
      square.set( * location, word)
      counts[ location[-1]] += 1
      true
    else
      false
    end
  end

  def dirs
    yield 1,0,0
    yield -1,0,0
    yield 0,1,1
    yield 0,-1,1
    if @defn['diagonals'] || @defn['diagonals'].nil?
      yield 1,1,2
      yield -1,1,3
      yield 1,-1,3
      yield -1,-1,2
    end
  end

  def find_word( words, text)
    from, to = 0, words.size - 1
    while from <= to
      mid = (from + to) / 2
      return words[mid] if words[mid] == text[0...(words[mid].size)]
      if words[mid] < text
        from = mid + 1
      else
        to = mid - 1
      end
    end

    nil
  end

  def generate( questions, output)
    File.open( "#{output}/#{questions}.html", 'w') do |io|
      generate_header( io)
      io.puts '</td><td width="30"></td><td>'
      write_answers( io)
      io.puts '</td></tr></table><script>'
      write_grid_script( io)
      io.puts '</script></body></html>'
    end
    @title
  end

  def generate_grid( defn, target)
    words = defn['words']
    width = defn['width']
    best  = nil
    words = words.uniq.sort

    (0...100).each do
      s = square( words, width, target)
      next if s.nil?
      best = s if best.nil? || (best.score < s.score)
    end

    raise 'No solution' unless best
    best.fill
    defn['hidden'] = record_words( words, best)
    defn['grid']   = best.to_grid
  end

  def generate_header( io)
    write_header_base( @title, io)
    write_script( io)
    width = @defn['width']
    io.puts <<"HEADER"
</head><body>
<table class="header">
<tr><td class="left"></td>
<td class="middle"><div class="title">#{prettify(@title)}</div></td>
<td class="right" style="min-height: 67px"><button id="button" onclick="reveal()">Answers</button></td>
</table>
<table class="word_search"><tr><td>
<canvas id="grid" width="#{1 + @cell * width}" height="#{1 + @cell * width}"></canvas>
HEADER
  end

  def letters( square, x0, y0, dx, dy)
    got = []
    (0...(square.width)).each do |i|
      if cell = square.cell( x0 + i * dx, y0 + dy * i)
        got << cell.letter
      end
    end
    return got.join( '')
  end

  def record_words( words, square)
    hidden = []
    runs( square.width) do |x0, y0, dx, dy, angle|
      text = letters( square, x0, y0, dx, dy)
      if word = find_word( words, text)
        hidden << [word, x0, y0, x0 + (word.size-1) * dx, y0 + (word.size-1) * dy]
      end
    end
    hidden
  end

  def runs( width)
    (0...width).each do |x0|
      (0...width).each do |y0|
        dirs do |dx,dy,angle|
          yield x0, y0, dx, dy, angle
        end
      end
    end
  end

  def square( words, width, target)
    s = Square.new( width)
    counts = [0, 0, 0, 0]

    large, small = [], []
    words.each do |word|
      if word.size >= width / 2
        large << word
      else
        small << word
      end
    end

    added = 0
    large.shuffle.each do |word|
      if add_word( s, counts, word)
        added += 1
        return s if added >= target
      end
    end

    small.shuffle.each do |word|
      if add_word( s, counts, word)
        added += 1
        return s if added >= target
      end
    end

    nil
  end

  def write_answers( io)
    io.puts '<table class="hidden"><tr><th>Hidden names</th></tr>'
    @defn['hidden'].each_index do |i|
      row = @defn['hidden'][i]
      io.print "<TR><TD><SPAN CLASS=\"answer\" ID=\"a#{i}\" STYLE=\"color: #{COLOURS[i% COLOURS.size]}\">#{row[0]}</SPAN>&nbsp;</TD></TR>"
    end
    io.puts '</table>'
  end

  def write_grid_script( io)
    @defn['grid'].each_index do |i|
      row = @defn['grid'][i]
      row.chars.each_index do |j|
        letter = row[j]
        io.puts "draw_letter( #{i}, #{j}, '#{letter}');"
      end
    end

    width = @defn['width']
    (0..width).each do |i|
      io.puts "draw_grid( #{i}, 0, #{i}, #{width});"
      io.puts "draw_grid( 0, #{i}, #{width}, #{i});"
    end
  end

  def write_script( io)
    io.puts <<"SCRIPT1"
<script>
    function hide( eid) {
      document.getElementById( eid).style.display = 'none';
    }

    function show( eid) {
      document.getElementById( eid).style.display = 'inline';
      document.getElementById( eid).style.opacity = 1;
    }

    function coord( i) {
      return #{1 + @cell / 2} + i * #{@cell};
    }

    function draw_grid( x0, y0, x1, y1) {
      var c = document.getElementById("grid");
      var ctx = c.getContext("2d");
      ctx.beginPath();
      ctx.lineStyle = "black";
      ctx.moveTo( coord(x0) - #{@cell / 2}, coord(y0) - #{@cell / 2}); 
      ctx.lineTo( coord(x1) - #{@cell / 2}, coord(y1) - #{@cell / 2}); 
      ctx.stroke();
    }

    function draw_line( x0, y0, x1, y1, colour) {
      var c = document.getElementById("grid");
      var ctx = c.getContext("2d");
      ctx.beginPath();
      ctx.strokeStyle = colour;
      ctx.lineWidth = 4;
      ctx.moveTo( coord(x0), coord(y0)); 
      ctx.lineTo( coord(x1), coord(y1)); 
      ctx.stroke();
    }

    function draw_letter( x, y, letter) {
      var c = document.getElementById("grid");
      var ctx = c.getContext("2d");    
      ctx.beginPath();
      ctx.strokeStyle = "black";
      ctx.fillStyle = "black";
      ctx.font = "75px Arial";
      ctx.fillText( letter, coord(x) - #{@cell * 0.325}, coord(y) + #{@cell * 0.35});
    }

    function reveal() {
      hide( 'button');
SCRIPT1

    @defn['hidden'].each_index do |i|
      io.puts "setTimeout( show_#{i}, #{i * 600});"
    end
    io.puts "}"

    @defn['hidden'].each_index do |i|
      l = @defn['hidden'][i]

      io.puts <<"SCRIPT2"
function show_#{i}() {
  show( 'a#{i}');
  draw_line( #{l[1]}, #{l[2]}, #{l[3]}, #{l[4]}, '#{COLOURS[ i % COLOURS.size]}');
}
SCRIPT2
    end

    io.puts "</script>"
  end
end
