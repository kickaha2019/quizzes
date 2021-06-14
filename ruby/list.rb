require 'yaml'

def used( items)
#  return items['used'].to_s if items['used']
  used = ''
  items.select do |item|
    if item['used']
      used = used + ' ' + item['used'].to_s
    end
  end
  used
end

def last_used( items)
  indexes = used( items).split( ' ')
  return nil if indexes.empty?

  indexes.inject( 0) do |r,i|
    (r < i.to_i) ? i.to_i : r
  end
end

types =  {'Anagrams'    => 'anagrams',
          'MissingWord' => 'groups',
          'NoVowels'    => 'phrases',
          'Pairs'       => 'pairs',
          'Questions'   => 'questions',
          'Rebuses'     => 'rebuses'
}

data = Hash.new {|h,k| h[k] = {}}

types.each_pair do |type, set|
  Dir.entries( ARGV[0] + '/' + type).sort.each do |f|
    next unless /\.yaml$/ =~ f
    path = ARGV[0] + '/' + type + '/' + f
    begin
      items = YAML.load( IO.read( path))[ set]
      used = last_used( items)
      data[type][f.split('.')[0]] = {count:items.size, used:used}
    rescue Exception => bang
      puts '*** ' + path
      raise
    end
  end
end

Dir.entries( ARGV[0] + '/Pictures').sort.each do |f|
  next if /^\./ =~ f
  used = ''
  dir = ARGV[0] + '/Pictures/' + f

  if File.exist?( dir + '/meta.yaml')
    items = YAML.load( IO.read( dir + '/meta.yaml'))[ 'pictures']
    used = last_used( items)
  end

  count = 0
  Dir.entries( dir).sort.each do |f1|
    count += 1 if /\.(jpg|jpeg|png)$/ =~ f1
  end
  data['Pictures'][f] = {count:count, used:used}
end

File.open( ARGV[1], 'w') do |io|
  io.puts "Type,Quiz,Count,Used"
  data.keys.sort.each do |type|
    data[type].each_pair do |quiz, record|
      io.puts "#{type},#{quiz},#{record[:count]},#{record[:used]}"
    end
  end
end