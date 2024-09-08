---
tags:
- site-reliability
- architecture
- big-tech
date: 2022-03-28T01:00:00Z
title: Ссылки для подготовки к интервью по системному дизайну уровня Google и Meta
description: Ресурсы, которые помогут кандидату пройти интервью по траблшутингу и системному дизайну в компании уровня Google, Meta, Apple, Microsoft, Booking
coverart: Consistent-Hashing-Sample-Illustration.png
coveralt: "Пример иллюстрации согласованного хеширования"
slug: system-design-interview
---

В последнее время я помогал двум людям подготовиться к переходу из разработки в Site Reliability Engineering, и вот список ресурсов на английском, которые я им рекомендовал:

1. [The System Design Primer](https://github.com/donnemartin/system-design-primer) - предлагаю начать с раздела "[System Design topics start here](https://github.com/donnemartin/system-design-primer#system-design-topics-start-here)", а затем перейти к примерам. Таким образом вы узнаете, какие компоненты можно использовать в качестве строительных блоков и какие у них есть достоинства, недостатки и компромиссы.

2. Главы из книги Site Reliability Engineering: [Monitoring Distributed Systems](https://sre.google/sre-book/monitoring-distributed-systems/) и [Service Level Objectives](https://sre.google/sre-book/service-level-objectives/).

3. [Crack the System Design Interview](https://tianpan.co/notes/2016-02-13-crack-the-system-design-interview)

4. [Back of the Envelope Calculation for System Design Interviews](https://www.codementor.io/@robinpalotai/back-of-the-envelope-calculation-for-system-design-interviews-z4ljbsp5l)

5. [Non-Abstract Large System Design](https://sre.google/workbook/non-abstract-design/) из SRE Workbook - очень подробный пример, который детально объясняет подход которому следует опытный SRE во время процесса проектирования системы.

Пройтись по этим пяти ссылкам с достаточным вниманием должно быть достаточно, чтобы получить фундаментальные знания по системному дизайну в целом и подготовиться к интервью.

![Пример иллюстрации согласованного хеширования](../../../../en/post/2022/system-design-interview/Consistent-Hashing-Sample-Illustration.png#center "WikiLinuz, CC BY-SA 4.0, via Wikimedia Commons")

## Траблшутинг

[Здесь](https://gist.github.com/ameenkhan07/4f0a65fb2bdec58656850f09ef8e2c48#file-linuxinternals-md) вы найдёте хорошую шпаргалку по траблшутингу, основанную на интервью в Meta (Facebook) на позицию Production Engineer. Отличие Production Engineer в Meta от SRE в Google в том, что в Meta больший упор идёт на Linux internals и сети, а в Google больше на системный дизайн и программирование.

## Чеклист SRE

[mxssl/sre-interview-prep-guide](https://github.com/mxssl/sre-interview-prep-guide) - полный чеклист всего что вам нужно знать как SRE, за исключением программирования. Если вы изучите каждый пункт этого (довольно обширного) списка, вы будете готовы к собеседованию в качестве SRE в любую компанию Big Tech, пройдя барьер технических собеседований в FAANG (Meta\Facebook, Amazon, Apple, Netflix и Alphabet\Google).

<!--more-->
