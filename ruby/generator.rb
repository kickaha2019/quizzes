#
# Generate a set of quizzes
#
# Command line:
#   Definition file
#   Output directory
#
require 'common.rb'
require 'anagrams.rb'
require 'letter_change.rb'
require 'missing_word'
require 'no_vowels.rb'
require 'pairs.rb'
require 'pictures.rb'
require 'questions.rb'
require 'rebuses.rb'
require 'reveals.rb'
require 'sequences.rb'

class Generator
  include Common

  def initialize( defn_file)
    defn = YAML.load( IO.read( defn_file))
    @subjects     = defn['puzzles']
    @size         = defn['size'].to_i
    @image_width  = defn['image_width']
    @image_height = defn['image_height']
    @rebus_height = defn['rebus_height']
    @index_html   = defn['index.html']

    @date = defn_file.split('/')[-1].split('.')[0]
    srand defn['seed'].to_i
  end

  def empty_output_area( output)
    to_delete = []
    Dir.entries( output).each do |f|
      to_delete << f if /\.(jpg|jpeg|png|html|csv)$/ =~ f
    end
    to_delete.each do |f|
      File.delete( output + '/' + f)
    end
  end

  def generate_quiz( name, dir, questions, output)
    if /^Anagrams/ =~ dir
      anagrams = Anagrams.new( @date, name, dir, @size)
      anagrams.generate( questions, output)
    elsif /^LetterChange/ =~ dir
      letter_change = LetterChange.new( @date, name, dir, @size)
      letter_change.generate( questions, output)
    elsif /^MissingWord/ =~ dir
      missing_word = MissingWord.new( @date, dir, @size)
      missing_word.generate( questions, output)
    elsif /^NoVowels/ =~ dir
      no_vowels = NoVowels.new( @date, name, dir, @size)
      no_vowels.generate( questions, output)
    elsif /^Pairs/ =~ dir
      pairs = Pairs.new( @date, name, dir, @size)
      pairs.generate( questions, output)
    elsif /^Pictures/ =~ dir
      pictures = Pictures.new( @date, name, dir, @size)
      pictures.generate( questions, @image_width, @image_height, output)
    elsif /^Questions/ =~ dir
      puzzles = Questions.new( @date, name, dir, @size)
      puzzles.generate( questions, output)
    elsif /^Rebuses/ =~ dir
      rebuses = Rebuses.new( @date, name, dir, @size)
      rebuses.generate( questions, @rebus_height, output)
    elsif /^Reveals/ =~ dir
      reveals = Reveals.new( @date, name, dir, @size)
      reveals.generate( questions, @image_width, @image_height, output)
    elsif /^Sequences/ =~ dir
      sequences = Sequences.new( @date, name, dir, @size)
      sequences.generate( questions, output)
    else
      raise "Unhandled puzzle: #{dir}"
    end
  end
  
  def generate_quizzes( output)
    @subjects.shuffle!
    empty_output_area( output)
    generate_random_numbers( @subjects.size)
    
    File.open( output + '/' + @index_html, 'w') do |io|
      io.puts <<"HEADER"
<html><head>
<title>Quiz</title>
<style>
table, th, td {border: 1px solid black; margin-left: auto; margin-right: auto; max-width: 95%}
table {border-collapse: collapse}
th, td {padding: 15px; font-size: 40px}
</style>
</head><body>
<table>
HEADER
      @subjects.each_index do |i|
        name = prettify( @subjects[i].split('/')[-1].split('.')[0]).gsub( ' ', '&nbsp;')
        io.puts "<tr><td><a href=\"#{@chaos[i]}.html\">#{name}</a></td>"
        desc = generate_quiz( name.downcase, @subjects[i], @chaos[i], output)
        io.puts "<td>#{desc}</td>"
      end
      io.puts '</table></body></html>'
    end
  end
  
  def generate_random_numbers( n)
    @chaos = []
    while @chaos.size < n
      r = rand(10000000)
      @chaos << r unless @chaos.index(r)
    end
    #p @chaos
  end
end

g = Generator.new( ARGV[0])
# puts g.get_common_prefix( "snowman", "snowball")
# puts g.get_common_postfix( "shoehorn", "Matterhorn")
# raise "Dev"
g.generate_quizzes( ARGV[1])
