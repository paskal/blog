# terrty.net blog source

This blog is proxified by the nginx configuration in [paskal/terrty](https://github.com/paskal/terrty).

## Youtube thumbnails

Youtube thumbnails with play button generated by [this service](https://addplaybuttontoimage.way4info.net). Example original thumbnails URLs:

    http://img.youtube.com/vi/SFIEA_sAPhc/maxresdefault.jpg
    http://img.youtube.com/vi/SFIEA_sAPhc/hqdefault.jpg

# Images in webp and avif

In order to make copies of images in a modern format to serve alongside with usual ones:

    find ./static/images -type f -name '*.png' -exec sh -c 'avifenc --min 10 --max 30 $1 "${1%.png}.avif"' _ {} \;
    find ./static/images -type f -name '*.jpg' -exec sh -c 'cwebp $1 -o "${1%.jpg}.webp"' _ {} \;

Easier alternative than harden-than-I-thought task of getting avifenc working is converting images to avif using https://avif.io/.