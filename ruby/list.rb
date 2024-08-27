require 'yaml'

def used_count( items)
  used = used_in( items)
  return 0 if used == ''
  used.split( ' ').size
end

def used_in( items)
#  return items['used'].to_s if items['used']
  used = ''
  items.select do |item|
    if item['used']
      used = used + ' ' + item['used'].to_s
    end
  end

  used.split( ' ').collect {|n| n.to_i}.uniq.sort.collect {|j| j.to_s}.join( ' ')
end

def last_used( items)
  indexes = used_in( items).split( ' ')
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
          'Rebuses'     => 'rebuses',
          'Sequences'   => 'sequences',
          'Sounds'      => 'sounds'
}

data = Hash.new {|h,k| h[k] = {}}

types.each_pair do |type, set|
  Dir.entries( ARGV[0] + '/' + type).sort.each do |f|
    next unless /\.yaml$/ =~ f
    path = ARGV[0] + '/' + type + '/' + f
    begin
      items = YAML.load( IO.read( path))[ set]
      used = used_in( items)
      data[type][f.split('.')[0]] = {count:items.size, used:used, times:used_count(items)}
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
    used  = used_in( items)
    times = used_count( items)
  end

  count = 0
  Dir.entries( dir).sort.each do |f1|
    count += 1 if /\.(jpg|jpeg|png)$/ =~ f1
  end
  data['Pictures'][f] = {count:count, used:used, times:times}
end

File.open( ARGV[1], 'w') do |io|
  io.puts "Type,Quiz,Count,Used in,Used count"
  data.keys.sort.each do |type|
    data[type].each_pair do |quiz, record|
      io.puts "#{type},#{quiz},#{record[:count]},#{record[:used]},#{record[:times]}"
    end
  end
end