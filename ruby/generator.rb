#
# Generate a set of quizzes
#
# Command line:
#   Definition file
#   Output directory
#
require 'common.rb'
require 'anagrams.rb'
require 'emojis.rb'
require 'letter_change.rb'
require 'missing_word'
require 'no_vowels.rb'
require 'pairs.rb'
require 'pictures.rb'
require 'questions.rb'
require 'rebuses.rb'
require 'reveals.rb'
require 'sequences.rb'
require 'sounds.rb'
require 'word_search'

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

    @index = defn_file.split('/')[-1].split('.')[0]
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
      anagrams = Anagrams.new( @index, name, dir, @size)
      anagrams.generate( questions, output)
    elsif /^Emojis/ =~ dir
      emojis = Emojis.new( @index, name, dir, @size)
      emojis.generate( questions, output)
    elsif /^LetterChange/ =~ dir
      letter_change = LetterChange.new( @index, name, dir, @size)
      letter_change.generate( questions, output)
    elsif /^MissingWord/ =~ dir
      missing_word = MissingWord.new( @index, dir, @size)
      missing_word.generate( questions, output)
    elsif /^NoVowels/ =~ dir
      no_vowels = NoVowels.new( @index, name, dir, @size)
      no_vowels.generate( questions, output)
    elsif /^Pairs/ =~ dir
      pairs = Pairs.new( @index, name, dir, @size)
      pairs.generate( questions, output)
    elsif /^Pictures/ =~ dir
      pictures = Pictures.new( @index, name, dir, @size)
      pictures.generate( questions, @image_width, @image_height, output)
    elsif /^Questions/ =~ dir
      puzzles = Questions.new( @index, name, dir, @size)
      puzzles.generate( questions, output)
    elsif /^Rebuses/ =~ dir
      rebuses = Rebuses.new( @index, name, dir, @size)
      rebuses.generate( questions, @rebus_height, output)
    elsif /^Reveals/ =~ dir
      reveals = Reveals.new( @index, name, dir, @size)
      reveals.generate( questions, @image_width, @image_height, output)
    elsif /^Sequences/ =~ dir
      sequences = Sequences.new( @index, name, dir, @size)
      sequences.generate( questions, output)
    elsif /^Sounds/ =~ dir
      sounds = Sounds.new( @index, name, dir, @size)
      sounds.generate( questions, output)
    elsif /^WordSearch/ =~ dir
      word_search = WordSearch.new( @index, name, dir, @size)
      word_search.generate( questions, output)
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
        name = subject_name( @subjects[i])
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

  def subject_name( subject)
    if /\.yaml$/ =~ subject
      defn = YAML.load( IO.read( subject))
      return defn['name'] if defn['name']
    end
    prettify( subject.split('/')[-1].split('.')[0]).gsub( ' ', '&nbsp;')
  end
end

g = Generator.new( ARGV[0])
# puts g.get_common_prefix( "snowman", "snowball")
# puts g.get_common_postfix( "shoehorn", "Matterhorn")
# raise "Dev"
g.generate_quizzes( ARGV[1])
