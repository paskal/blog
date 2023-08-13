#!/bin/sh

hugo --minify && rsync -azi --exclude cv/ --delete public/ terrty-oracle:~/blog/public/ | grep -v "f..t...."
