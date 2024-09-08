---
tags:
- security
- howto
date: 2014-01-15T00:00:00Z
title: Установка SoftEther VPN в Ubuntu 
description: Как установить последнюю сборку SoftEther VPN в Ubuntu используя PPA
slug: softether-vpn-ubuntu
---

В этой статье рассказывается, как установить SoftEther VPN в Ubuntu\Debian.

<!--more-->

### Вступление

Что такое SoftEther VPN подробно описано в посте на habr'е, советую ознакомиться с ней, если вы её ещё не читали:

{{< blockquote author="ValdikSS" title="SoftEther VPN — продвинутый мультипротокольный VPN-сервер и клиент" link="https://habr.com/ru/articles/208782/" >}}
в этой статье речь пойдет о VPN-сервере, который может поднимать L2TP/IPsec, OpenVPN, MS-SSTP, L2TPv3, EtherIP-серверы, а также имеет свой собственный протокол «SSL-VPN», который неотличим от обычного HTTPS-трафика (чего не скажешь про OpenVPN handshake, например), может работать не только через TCP/UDP, но и через ICMP (подобно pingtunnel, hanstunnel) и DNS (подобно iodine), работает быстрее (по заверению разработчиков) текущих имплементаций, строит L2 и L3 туннели, имеет встроенный DHCP-сервер, поддерживает как kernel-mode, так и user-mode NAT, IPv6, шейпинг, QoS, кластеризацию, load balancing и fault tolerance, может быть запущен под Windows, Linux, Mac OS, FreeBSD и Solaris и является Open-Source проектом под GPLv2
{{< /blockquote >}}

### Документация SoftEther VPN

[Официальный сайт](https://www.softether.org/ "SoftEther VPN Project — SoftEther VPN Project")

[Возможности](https://www.softether.org/3-spec "Specification — SoftEther VPN Project")

[Документация](https://www.softether.org/4-docs/1-manual "SoftEther VPN Manual — SoftEther VPN Project") (англ.)

### Requirements

Подойдёт любая Ubuntu Server последнего LTS релиза или новее, обыкновенная Ubuntu, или другой современный .deb based дистрибутив типа Debian. Установка будет производиться в соответствии с [соответствующим разделом мануала](https://www.softether.org/4-docs/1-manual/7._Installing_SoftEther_VPN_Server/7.3_Install_on_Linux_and_Initial_Configurations "7.3 Install on Linux and Initial Configurations — SoftEther VPN Project") в [Service Mode](https://www.softether.org/4-docs/1-manual/3._SoftEther_VPN_Server_Manual/3.2_Operating_Modes "3.2 Operating Modes — SoftEther VPN Project").

### Установка

    sudo apt-add-repository ppa:paskal-07/softethervpn && sudo apt-get update && sudo apt-get upgrade && sudo apt-get install softether-vpnserver

**Важно**! Начиная с Ubuntu 21.04 пакеты SoftEther VPN [доступны](https://launchpad.net/ubuntu/+source/softether-vpn) внутри системы и должны устанавливаться без использования PPA:

    sudo apt-get update && sudo apt-get upgrade && sudo apt-get install softether-vpnserver
