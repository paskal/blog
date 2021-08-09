---
tags:
- english
- software
- site-reliability
- architecture
date: 2021-08-09T20:00:00Z
title: A year of SRE work on a small Bitrix site
description: A tale on Site Reliability Engineer looking into tiny business web service performance and reliability
coverart: DOM\_load\_time\_July\_2020\_to\_2021\_50th\_percentile.png
coveralt: "DOM load time from July 2020 to July 2021"
slug: year-of-sre-work-on-bitrix
---

1. [Big problems on a small scale](/2020/small-forms/)

2. A year of SRE work on a small Bitrix site (this post)

I picked up responsibility for my father's website commercial and technical success the last summer. With Site Reliability Engineer the website should get decent monitoring, become maintenance-free and blazingly fast, and ultimately receive plenty of new customers, right? Kind of, but it takes time and a lot of effort, as I learned over the last year.

## Site speed

I assumed that Nginx + php-fpm instead of Apache, [Nginx PageSpeed mod](https://github.com/apache/incubator-pagespeed-ng) and upgrading PHP version alongside checking the code for possible JS optimisations should speed the site up. The page readiness time graph below shows that part of the assumptions had the effect opposite to the desired one.

![DOM load time from July 2020 to July 2021, 50th percentile](DOM_load_time_July_2020_to_2021_50th_percentile.png)

Percentiles: [50th](DOM_load_time_July_2020_to_2021_50th_percentile.png) | [75th](DOM_load_time_July_2020_to_2021_75th_percentile.png) | [90th](DOM_load_time_July_2020_to_2021_90th_percentile.png) | [95th](DOM_load_time_July_2020_to_2021_95th_percentile.png)

<!--more-->

Nginx enablement end of **September** 2020 showed no significant speed change over Apache in the [Chrome Lighthouse](https://developers.google.com/web/tools/lighthouse) and page generation speed as low as 0.5s with spikes up to 4s on the Zabbix page response time graph (following picture). I was unhappy but thought I'll figure the spikes root cause eventually.

The effect on the customers was disastrous: the 50th percentile of load time increased three times from the initial 6 seconds; however, I was not looking at that (client data) graph at the time and was relying only on synthetic checks by Zabbix.

In **October**, I applied optimisations recommended by [EverSQL](https://www.eversql.com). It allowed me to cut half the time PHP spent waiting for MySQL responses without learning the magic craft of database performance troubleshooting and index building. I assume that these optimisations are the primary contributor to sub-0.5s page generation time after the rest of the problems were fixed.

After discovering the DOM loading time graph above in early **January** 2021, I started looking for the reason for the degradation. After multiple attempts in the wrong places, I finally found that the pagespeed Nginx module was the root cause of the problem: removing it reduced the 50th percentile rendering time from 20-25 seconds to just 5-7. Here is the page generation time graph with pagespeed disabled at the 4 AM mark:

![pagespeed hurts performance, page generation time metric](after_pagespeed.png)

The new virtual machine provider gave a nice benchmark boost and a slight page generation time decrease in **February** but didn't affect the customers much as they spent most of the time rendering the page, not waiting for it to load from the server.

In **March**, I found the dirt-cheap improvement to the render time I was looking for. It turned out to be [delaying](https://constantsolutions.dk/2020/06/delay-loading-of-google-analytics-google-tag-manager-script-for-better-pagespeed-score-and-initial-load/) the load of Google Analytics and other JS scripts, which gave the final decrease of end-user DOM load time from 5.2s to 3.0s. That way, non-essential JS work is not affecting the initial page render time.

**June**, the site got bot traffic appearing as slow real clients in the monitoring, and I onboarded Cloudflare only to discover that:

1. Cloudflare cuts bots as well as provide better loading speed to the customers due to various optimisations for images and static resources they provide;

2. All Cloudflare public IPs are banned by Russian authorities since \~2016, and search engines prosecute you severely the moment you start using them.

You [*could*](https://community.cloudflare.com/t/reverse-proxy-infront-of-cloudflare/33972/8?u=favor.group2015) use Cloudflare behind your own IP to get around the ban, but that's terra incognita for me, and I have yet to see if it will help against bots.

Supposedly you want to avoid repeating my errors. In that case, **don't change the system without looking at the relevant data and graphs** you identified as a target of a change in advance, and, the first rule of any refactoring, **avoid introducing multiple changes at once** as they make results interpolation close to impossible.

## Infrastructure

When I started caring for the project, it was provider-configured Apache with MariaDB without code versioning, but with almost working backup. It was a system that worked without anyone knowing for sure how.

![small Bitrix project architecture](favor-group-architecture.png)

I've started refactoring the infrastructure at the time of writing the [first post](/2020/small-forms/), which ultimately ended in the architecture drawn above. All code for it is available for free at [paskal/bitrix.infra](https://github.com/paskal/bitrix.infra) GitHub under MIT license.

I won't go into a detailed description here as it won't be interesting to most readers; it is a docker-compose file with an extensive Readme describing how to set it up, which a few people found helpful already.

## Results

The site got roughly twice as many visits as the year before, which is reasonably good but way under my predictions. Repeating history, it turned out that technical excellence has a weak correlation with success.

The site works without maintenance after initial investment into infrastructure refactoring, which has not changed the state before. But the rendering speed became better, with only the 90th percentile still slow because of users with cheap mobile devices who have the 5x page rendering time of the desktop users; [Google AMP](https://developers.google.com/amp) could help with that.

Eliminating the technical obstacles made the site more transparent (available, resilient) for the users and search engines, which unlocked full-on work on the content. Since day one, I had to think not only about maintainability and speed but also about improving the site for the customers and the search engines. Now, after the proper technical rework is done, everything left is that endless search for ways of satisfying the customer better than competitors, which competent contractors will do better than me.

Leading that effort was the most satisfying thing I've done in the last few years. Helping a dozen people save their jobs and my father keep his business felt more meaningful than doing my part in the corporation, but having that corporate work experience and the world's best experts working alongside me was the precondition for me to bear that load.
