#!/bin/csh
cd $0:h

set QUIZ=2021-05-09
ruby -I ruby ruby/generator.rb Definitions/${QUIZ}.yaml /Users/peter/Sites/quizzes/${QUIZ}
