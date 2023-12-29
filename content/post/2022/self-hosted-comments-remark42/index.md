---
tags:
- howto
date: 2022-08-30T21:00:00Z
title: How to run Remark42 for your site or blog using Public Cloud
description: Instructions for deploying a self-hosted instance of Remark42 comment system for site or blog using Digital Ocean or Oracle Cloud
coverart: Prague-Riegrovy-sady.jpg
coveralt: "Prague, Riegrovy sady, June 2022: photo by Ksenia Gulyaeva"
slug: self-hosted-comments-remark42
---

This post is a short guide on hosting a privacy-focused comment system [Remark42](https://remark42.com) on a virtual machine in the cloud for free or a small monthly fee.

![Prague, Riegrovy sady, June 2022: photo by Ksenia Gulyaeva](Prague-Riegrovy-sady.jpg#center "Prague, Riegrovy sady, June 2022: photo by Ksenia Gulyaeva")

## Obtaining a virtual machine instance in the public cloud

Follow one of the instructions below to obtain an instance. At the end of the setup process, generate an SSH key and download it to your machine. The default location to store the private part of the key on Mac and Linux is `~/.ssh/id_rsa`. You'll need to connect to that instance using SSH during the next step.

### Oracle Cloud, free

[Register](https://signup.cloud.oracle.com/) (requires credit card details) first. Then, create [an instance](https://cloud.oracle.com/compute/instances/) there: you should pick a machine type Ampere "VM.Standard.A1.Flex" with 4 CPUs and 24GB of RAM. Initially, you would have a free trial for many resources, but that machine would be free and [remain free for you for the time being](https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier_topic-Always_Free_Resources.htm#compute).

In case you need more machines for other purposes, you can run up to four with 1 CPU and 6Gb of RAM each, as long as the total number of CPUs and RAM amount fits the number above. Oracle Linux is the default OS there, but you can pick something else like Ubuntu if you wish.

<!--more-->

### Digital Ocean, $4-$6 per month

[Register](https://m.do.co/c/60ca78166540) first if you don't have an account there yet. The link is a referral and would give you 100$ for 60 days, effectively giving free Remark42 hosting for the first two months.

Then, create the smallest\cheapest server possible in that cloud provider. For DigitalOcean, virtual machines are called [droplets](https://cloud.digitalocean.com/droplets), and you need "Basic" -> "Regular with SSD" -> $4/month 1 CPU, **512MB** RAM and **10GB** SSD, or $6/month 1CPU, **1GB** RAM and **20GB** SSD if $4 option is not available in the region of your choice. Any operating system will do, in case you are unsure — pick Ubuntu.

## How to start Remark42 on the virtual machine

1. Before starting the work, point remark42.example.org (with your domain name instead of example.org) to the IP address of the instance using your DNS provider.
1. SSH to the instance and install Docker and docker-compose to it using [this guide for Ubuntu](https://docs.docker.com/engine/install/ubuntu/) or [that for CentOS / Oracle Linux](https://docs.docker.com/engine/install/centos/).
1. Create `docker-compose.yml` on the instance and paste the content below into it:

   ```yaml
   version: "2"
   
   services:
     remark:
       image: umputun/remark42:latest
       container_name: "remark42"
       hostname: "remark42"
       restart: always
   
       logging:
         driver: json-file
         options:
           max-size: "10m"
           max-file: "5"
   
       ports:
         - "443:8443"
         # uncomment the line below to make remark42
         # work not only on HTTPS but also via HTTP
         # - "80:8080"
   
       environment:
         - REMARK_URL=https://remark42.example.org
         - ADMIN_SHARED_EMAIL=
         - SECRET=
         - DEBUG=true
         - SSL_TYPE=auto
         - AUTH_ANON=true
         # Enable it only for the initial comment
         # import or for manual backups.
         # Do not leave the server running with the
         # ADMIN_PASSWD set if you don't have an intention
         # to keep creating backups manually!
         # - ADMIN_PASSWD=<your secret password>
       volumes:
         - ./var:/srv/var
   ```

   Complete setup could be done using [parameters' documentation](https://remark42.com/docs/configuration/parameters/). Here are the minimum required steps:

   - set `SECRET` to a random string
   - set `ADMIN_SHARED_EMAIL` to your email address (Remark42 will subscribe it to HTTPS certificate renewal notifications)
   - replace example.org with your domain name `REMARK_URL`

1. Run `docker compose up` to start the instance and observe the logs. After that, <https://remark42.example.org/web/> (with your domain name instead of example.org) should show you the working Remark42 demo.

   After making sure that the Remark42 demo works, make it persistent. Stop the previous command by pushing `Ctrl`+`C` and run `docker-compose up -d` instead: it will run Remark42 in the background and start automatically on the VM restart. To see the log of the Remark42 container running in the background mode, you'll need to run the command `docker compose logs remark42 -f`

After the steps above are done, you can set up the frontend [according to the instruction](https://remark42.com/docs/getting-started/installation/#setup-on-your-website).
