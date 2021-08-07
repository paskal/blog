---
draft: true
tags:
- english
- software
- site-reliability
- architecture
date: 2021-08-08T20:00:00Z
title: A year of work on a small Bitrix site
description: A tale on high-performing Site Reliability Engineer looking into tiny business web service performance and reliability
coverart: DOM\_load\_time\_July\_2020\_to\_2021\_50th\_percentile.png
coveralt: "DOM load time from July 2020 to July 2021"
slug: year-of-work-on-bitrix
---

1. [Big problems on a small scale](/2020/small-forms/)
2. A year of work on a small Bitrix site (this post)

Last summer, I started helping my father's business. A Site Reliability Engineer will improve monitoring, automate the toil and fine-tune the website's performance, and it will bring plenty of new customers, right? Almost entirely wrong, as I learned over the last year.

## Site speed

I assumed, fine-tuned Nginx + php-fpm instead of Apache, [Nginx PageSpeed mod](https://github.com/apache/incubator-pagespeed-ng) and upgrading PHP version alongside checking the code for possible JS libraries optimisations would speed the site up.

![DOM load time from July 2020 to July 2021, 50th percentile](DOM_load_time_July_2020_to_2021_50th_percentile.png)

Percentiles: [50th](DOM_load_time_July_2020_to_2021_50th_percentile.png) | [75th](DOM_load_time_July_2020_to_2021_75th_percentile.png) | [90th](DOM_load_time_July_2020_to_2021_90th_percentile.png) | [95th](DOM_load_time_July_2020_to_2021_95th_percentile.png)

<!--more-->

Nginx enablement end of **September** 2020 showed no significant speed change over Apache in the benchmark (Chrome Lighthouse) and faster page generation speed (as low as 0.5s) with spikes up to 4s from time to time. I was unhappy but thought I'll figure it out eventually.

As you can see on the graph, the effect on the actual users was disastrous: load time 50th percentile of users increased from 6s to 17-20s; however, I was not looking at that graph at the time and was relying on synthetic benchmarks.

In **October**, I applied many optimisations recommended by amazing [EverSQL](https://www.eversql.com), which allowed me to cut half the time PHP spent waiting for MySQL. It didn't play very well in the moment, however I assume it's the primary reason I've got sub-0.5s page generation time after fixing the rest of the problems later.

Early **January** 2021, after discovering the DOM loading time graph you see above I wrestled with the performance problems for a month. While ruling out the contributing factors, I found that pagespeed Nginx module caused the most significant speed problems I observed: removing it reduced the 50th percentile loading time from 20-25 seconds to just 5-7. Here is the page generation time graph with pagespeed disabled at the 4 AM time mark:

![pagespeed hurts performance, page generation time metric](after_pagespeed.png)

Migration to a new cloud provider in **February** gave a nice benchmark boost and page generation time decrease but didn't affect end users much because they spent most of the time rendering the page, not waiting for it to load.

Finally, in **March**, I found the dirt-cheap improvement to the render time I was looking for. I've started [delaying](https://constantsolutions.dk/2020/06/delay-loading-of-google-analytics-google-tag-manager-script-for-better-pagespeed-score-and-initial-load/) a load of Google Analytics, Yandex Metrika and customer chat JS scripts by three seconds which gave me the final decrease of end-user DOM load time from 5.2s to 2.8-3.0s.

June, we got a lot of bot traffic appearing as slow clients in the analytics, and in August, I gave up the protection against them to Cloudflare only to discover that:

1. their solution cuts bots flawlessly as well as provide better loading speed for pages due to various built-in optimisations for images and code

2. all Cloudflare public IPs are banned by Russian authorities since \~2016 and search engines prosecute you severely the minute you start using these

You [*could*](https://community.cloudflare.com/t/reverse-proxy-infront-of-cloudflare/33972/8?u=favor.group2015) hide Cloudflare behind your own IP if you really want to like in case I've got here, but that's terra incognita for me and I have see if it will help against bots.

Supposedly you want to be smarter than me. In that case, **don't try optimising without looking at the relevant data and graphs** you identified as a target in advance, and (first rule of refactoring) **avoid introducing multiple changes at once** as they make results interpolation close to impossible.

## Infrastructure

When I started caring for the project, it was provider-configured Apache with MariaDB without code versioning but with almost working backup. It was a system that worked without anyone knowing for sure how.

![small Bitrix project architecture](favor-group-architecture.png)

When writing the [first post](/2020/small-forms/), I've started refactoring the infrastructure, which ultimately ended in the architecture drawn above. All code is available for free at [paskal/bitrix.infra](https://github.com/paskal/bitrix.infra) under MIT license.

I won't go into a detailed description here as it won't be interesting to most readers. In short, it is a docker-compose file with an extensive Readme describing how to set it up and run it, which a few people found helpful already.

## Results

The site got roughly twice as many visits as the previous year, which is reasonably good but way under my predictions. As always, it turned out that technical excellence is rarely relevant for success.

Technical changes made the maintenance costs non-existing, as, after initial investment into refactoring, the site just works. The rendering speed became a little bit better overall, but in general (90th percentile and higher) still restricted by clients with cheap mobile devices who have the 5x page rendering time of the desktop.

Eliminating the technical difficulties made the site more transparent (available, resilient) for the users and search engines, which unlocked full-on work on the content. Since day one, I had to think not only about infrastructure and speed but also about improving the site for the customers and the search engines, and after the proper technical rework is done, everything which is left is that endless chase for finding ways of satisfying the customer better than your competitors which competent contractors and not me will better do.

Leading that effort was the most satisfying work I've done in the last few years. I saw that helping a dozen people save their jobs and my father keep his business feels more meaningful than doing my part in the corporation, but having that corporate work experience and exposure to the world's best experts in their areas working alongside me was the precondition for me to be able to bear that load.
