class Sequences
  include Common

  def initialize( date, name, dir, size)
    @dir  = dir
    @meta = YAML.load( IO.read( dir + '/script.yaml'))
    @meta['pictures'] = [] unless @meta['pictures']
    @title = @meta['title'] ? @meta['title'] : (name + ' puzzle')

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
  end

  def copy_images( questions, output)
    @meta['images'].each_index do |i|
      item = @meta['images'][i]
      width = item['width'] ? item['width'] : @meta['width']
      height = item['height'] ? item['height'] : @meta['height']
      copy_image( item, width, height, questions, i, output)
    end
  end

  def generate( questions, output)
    prepare_images
    copy_images( questions, output)
    generate_page( questions, output)
    @title
  end

  def generate_page( questions, output)
    File.open( "#{output}/#{questions}.html", 'w') do |io|
      write_header( io)
      write_actions( io)
      io.puts '</div><script>action0();</script></body></html>'
    end
  end

  def prepare_images
    @meta['images'].each do |item|
      item[:image] = @dir + '/' + item['image']
      prepare_image( item)
    end
  end

  def write_actions( io)
    @meta['actions'].each_index do |i|
      action = @meta['actions'][i]
      io.puts "function action#{i}() {"
      if action['button']
        io.puts "  show( 'button#{i}');"
      end
      if action['delay']
        io.puts "setTimeout( action#{i+1}, #{action['delay'] * 1000});"
      end
      if (i > 0) && @meta['actions'][i-1]['button']
        io.puts "  hide( 'button#{i-1}');"
      end
      if action['hide']
        action['hide'].split( ' ').each do |element|
          io.puts "  hide( '#{element}');"
        end
      end
      if action['show']
        action['show'].split( ' ').each do |element|
          io.puts "  show( '#{element}');"
        end
      end
      io.puts '}'
    end

    io.puts <<"HEADER2"
</script>
</head><body>
<div class="header">
<div class="title">#{prettify(@title)}</div>
<div class="buttons" style="min-height: 67px">
HEADER2

    @meta['actions'].each_index do |i|
      action = @meta['actions'][i]
      if action['button']
        style = "display: #{(i == 0) ? 'inline' : 'none'}"
        io.puts "<button id=\"button#{i}\" onclick=\"action#{i+1}()\" style=\"#{style}\">#{action['button']}</button>"
      end
    end

    io.puts "</div></div><div class=\"frame\">"
    @meta['images'].each do |image|
      io.puts "<div class=\"image #{image['class']}\" id=\"#{image['name']}\">"
      io.puts "<image src=\"#{image[:output]}\">"
      io.puts "</div>"
    end
  end

  def write_header( io)
    io.puts <<"HEADER1"
<html><head>
<title>#{prettify(@title)}</title>
<style>
div.header {width: 90%; display: flex; justify-content: space-between;
            margin-left: auto; margin-right: auto}
div.frame {width: #{@meta['width']}; height: #{@meta['height']}; overflow: hidden;
           margin-left: auto; margin-right: auto; display: block; position: relative}
div.title {width: 100%; text-align: left; font-size: 30px; text-decoration: none; margin-bottom: 15px; font-weight: bold}
button {text-align: right; font-size: 25px; text-decoration: none; margin-bottom: 17px; font-weight: bold; background-color: cyan;
        border-radius: 5px; border-color: cyan}
div.image {position: absolute; left: 0px; top: 0px; display: none}

@keyframes slide_in_from_left {
  from {left: -1024px;}
  to {left: 0px;}
}

.slide_in_from_left {
  animation-name: slide_in_from_left;
  animation-duration: 3s;
}

@keyframes slide_off_to_right {
  0% {left: 0px;}
  50% {left: 1024px;}
  100% {left: 1024px;}
}

.slide_off_to_right {
  animation-name: slide_off_to_right;
  animation-duration: 6s;
}

@keyframes fade_in {
  from {opacity: 0}
  to {opacity: 1}
}

.fade_in {
  animation-name: fade_in;
  animation-duration: 3s;
}

</style>
<script>
    function hide( eid) {
      document.getElementById( eid).style.display = 'none';
    }

    function show( eid) {
      document.getElementById( eid).style.display = 'block';
    }
HEADER1
  end
end
