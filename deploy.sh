#!/bin/sh

hugo --minify --cleanDestinationDir && rsync -azi --exclude cv/ --delete public/ terrty-oracle:~/blog/public/ | grep -v "f..t...." | grep -v ".d..t...."
