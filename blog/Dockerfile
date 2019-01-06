FROM alpine

ADD https://github.com/gohugoio/hugo/releases/download/v0.53/hugo_0.53_Linux-64bit.tar.gz /tmp

RUN tar xzf /tmp/hugo*.tar.gz -C /bin/ && rm /tmp/hugo*.tar.gz

WORKDIR /srv/hugo
ENTRYPOINT ["/bin/hugo"]
