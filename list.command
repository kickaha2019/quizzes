#!/bin/csh
cd $0:h
ruby ruby/list.rb . list.csv
open list.csv
