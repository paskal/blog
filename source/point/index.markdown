---
title: "My blog feed from Point.im"
layout: feed_aggregator

# maximum number of entries from each feed url to display (defaults to 5)
# use '0' for 'no limit'
post_limit: 30

# limit on total posts for feed (defaults to 100)
# use 0 for 'no limit'
post_total_limit: 50

# maximum post age to include: <N> { seconds | minutes | hours | days | weeks | months | years }
# abbreviations and plurals are supported, e.g.  w, week, weeks
# defaults to '1 year'
# use '0 <any-unit>' for 'no limit'
post_age_limit: 0 months

# only render full content for the first <N> posts
# (default is 'full content for all posts')
# use a limit of 0 to use all summaries
# full_post_limit: 10

# use summaries for all posts older than this
# (default is 'no maximum age')
# works like post_age_limit
# full_post_age_limit: 3 month

# generate a 'meta-feed' atom file, with the given name 'atom.xml' (meta feeds are optional)
# (with no directory, generates in same directory as the feed aggregator page)
# meta_feed: atom.xml

# list all urls to aggregate here
# You can either specify a single feed url, or explicitly specify 'url', 'author'
# and/or 'author_url' params for the feed aggregator to use.
# feed_aggregator does its best to supply these values automatically otherwise.
feed_list:
  - http://paskal.point.im/rss
---
