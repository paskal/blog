#!/bin/sh

hugo --minify --cleanDestinationDir && rsync -azi --exclude cv/ --delete public/ terrty:~/blog/public/ | grep -v "f..t...." | grep -v ".d..t...."
