---
comments: false
date: 2012-05-12 13:14:23
layout: post
title: Перенос пользователей со старого linux сервера на новый
categories:
- soft
---

Прекрасная [статья о переносе пользователей со старого linux сервера на новый](http://linax.wordpress.com/2010/07/20/move-user-accounts-from-old-linux-server-to-a-new-linux-server/).

Вместо `tar -zcvpf /root/move/mail.tar.gz /var/spool/mail` читать `tar -zcvpf /root/move/mail.tar.gz /var/spool/mail/*`
