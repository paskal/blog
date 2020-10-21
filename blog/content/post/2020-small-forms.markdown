---
draft: true
tags:
- english
- thoughts
- software
- sre
date: 2020-10-22T00:30:00Z
title: Big problems on a small scale
slug: small-forms
---

My future is bright, but my present is dreadful. Aside from usual life problems that I can't do anything about I've got a bunch I'm capable of resolving and that turned out to be a challenge I could not cast away.

### A bit of history

I've started helping my father's small company of 13 people plus three contractors working on the site, and it's content when I've heard enough of silly stories about problems with the company site. Three particular which enraged me the most were:

- `sitemap.xml` not renewed for 2 months after migration to the new platform causing _huge_ search engines traffic decrease
- `robots.txt` for regional subdomains having Hostname directive pointing to the main site, causing three sites to merge into a single one in the eyes of the search engines
- the cherry on the cake, [Google Lighthouse](https://developers.google.com/web/tools/lighthouse) website performance benchmark reliably shows 25-30 points from 100

<!--more-->

### Magnificent past

My father's business is very seasonal as it mostly sells building materials, and you couldn't build anything in the winter in Russia. The problems started around February which is exactly the time you want to be prepared the most and went through up to July without many changes. At that point in time, I was struck by a thought that as a Site Reliability Engineer, and the direct person I possess skills which are relevant both for making site work more reliable, setting up monitoring, speeding the site up, and finally telling people who were paid to do that before exactly what I think of their job.

Early August I've asked him to add me to the internal ticket system and introduce me to other people who work with the site. In a few days I created a basic monitoring for known problems and started getting into how things work.

In one month I've switched monitoring from a very basic one (Monit) to a normal one with graphs and history (Zabbix), found and eliminated a few small problems and inconsistencies in the site configuration and by pure luck found and eliminated a huge performance drain by unchecking a single checkbox in site admin interface which sped up the site from 25-30 to 55-65 points in Lighthouse test.

Before the glorious speed up of the site, I spent approximately 20 hours tinkering with its Nginx and apache2 configuration and installing and fine-tuning [ngx_pagespeed](https://developers.google.com/speed/pagespeed/module) module. Another 10 or 15 hours were spent in observing search engines webmaster and analytics tools in an attempt to find low-hanging Search Optimisation fruits, which yielding close to none measurable results so far as well.

### Grievous present

Fast forward to the present moment, I'm trying to do a simple task of adding a few more regional subdomains and couldn't do that because each step spawns long chains of thoughts:
 
- The current setup requires me to add new domains one by one in the "hosting control panel" which had its glory days back in 2011 but since then turned from the thing you brag about to fellow students into something which you blame for your misbehaviour on last year's mother's birthday when you lie on the psychotherapist couch;
- To avoid making 9 clicks per page multiplied by 10 sites I could alter Nginx and apache configuration for all sites at once, but I'll need a switch from "control panel" SSL certification renewal to my own;
- In order to renew certificates automatically I need to utilize certbot directly, and in order to do it reproducible I need to do it in docker-compose, which doesn't exist now;
- When I'll have certbot in docker-compose, it wouldn't make sense to have Nginx outside of docker, and I would want to move it inside docker-compose as well;
- When I'll have Nginx in docker-compose, the only thing to migrate would be apache, but it's a monster on its own, and it would be much better to switch to simpler php-fpm;
- When I'll have all web setup inside the docker-compose, I would want to move cron scripts there as well to get rid of any configuration which is not in the code yet;
- Somewhere above I forgot about an obscure MySQL 5.7 fork is running on the server, and I need to move it to docker-compose as well with migration to MySQL 8;
- Have I mentioned php-fpm is interchangeable with HHVM and I would want to test them both?

I can write down at least another five points but in the end it goes to the beginning of the list, and I still haven't started _actually doing something_.

### Radiant future

My conclusion for the night is that skills of SRE which are useful for thousands of servers and terabytes of data transferred hourly are useful on a super-small scale, and I know how to make a state-of-art system which would be very easy to debug, maintain and scale, but only God knows how long is the way lying ahead of me.
