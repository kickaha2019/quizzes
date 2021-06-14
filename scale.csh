#!/bin/csh
#
# Scale image
#   Input filename
#   Output filename
#   Output width
#   Output height
#
echo \.\.\. Scaling $1 to $2
#set IM=/ImageMagick-6.4.0/bin
set IM=/opt/homebrew/bin
$IM/convert -thumbnail "${3}x${4}!" $1 -depth 8 -quality 65 $2
if ($status != 0) exit 1
