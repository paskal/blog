#!/bin/sh

hugo --minify && rsync -azi --delete public/ terrty-oracle:~/blog/public/
