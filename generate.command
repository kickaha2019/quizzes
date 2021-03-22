#!/bin/csh
cd $0:h

set QUIZ=2021-04-01
ruby -I ruby ruby/generator.rb Definitions/${QUIZ}.yaml /Users/peter/Sites/quizzes/${QUIZ}
