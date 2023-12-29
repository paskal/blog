---
tags:
- feedback
- big-tech
- howto
date: 2022-06-06T14:00:00Z
title: Preparing technical feedback for Individual Contributors
description: List of things to take into consideration when writing technical feedback for Individual Contributors like Software Developers and Site Reliability Engineers
coverart: Amsterdam-Walenpleintje.jpg
coveralt: "Amsterdam, Walenpleintje street, June 2022: photo by Ksenia Gulyaeva"
slug: preparing-technical-feedback
---

Sporadically, I have to provide written technical feedback to my colleagues, some of whom I didn't interact with much but used their services regularly, or I happen to have just the right expertise to estimate their work quality and impact.

I review the traces of their work I can find for the period a colleague requested the feedback (six or twelve months usually) and try my best to identify the work's scope, intention, and impact. Here is a list of things I take into consideration:

1. **Pull Requests made** by the person:
   - `https://gitlab.com/dashboard/merge_requests?scope=all&state=merged&author_username=USERNAME` for GitLab
   - `https://github.com/pulls?q=is%3Amerged+archived%3Afalse+is%3Apr+author%3AUSERNAME` for GitHub
2. **Pull Requests reviewed** by the person:
   - `https://gitlab.com/dashboard/merge_requests?scope=all&state=merged&approved_by_usernames[]=USERNAME` for GitLab
   - `https://github.com/pulls?q=is%3Apr+reviewed-by%3AUSERNAME` for GitHub
3. **Wiki\documentation** changes made by the person. In particular, checking the difference between the document before and after the changes is extremely useful for the review.
4. If the above information is not enough, the **ticket system** like Jira, as a last resort. Usually, filtering resolved tickets assigned to the person is enough.

Written artefacts play a significant role in performance evaluations and promotions in the Big Tech (Meta, Google, Microsoft). Providing feedback is a great way to help a colleague receive deserved recognition from the company.

![Amsterdam, Walenpleintje street, June 2022: photo by Ksenia Gulyaeva](Amsterdam-Walenpleintje.jpg#center "Amsterdam, Walenpleintje street, June 2022: photo by Ksenia Gulyaeva")
<!--more-->
