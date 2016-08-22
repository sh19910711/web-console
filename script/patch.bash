#!/bin/bash

commits() {
  git log --oneline --author="Hiroyuki Sano" --since="2016-01-01" | cat | awk '{print $1}'
}

cnt=0
for c in $(commits); do
  echo $c: $(printf %04d $cnt)
  git format-patch --start-number $cnt -o tmp $c~..$c
  cnt=$(expr $cnt + 1)
done
