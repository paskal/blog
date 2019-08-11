---
tags:
- software
date: 2017-08-24T19:24:03Z
description: How to setup remote code execution using VSC
title: How to build code remotely in Visual Studio Code
slug: remote-code-build-in-visual-studio-code
---

In Sublime Text you could achieve remote code execution using the following code:

``` json
{
    "shell":true,
    "cmd": ["rsync -az '$file' server.example.org:~ && ssh server.example.org 'chmod +x ./$file_name; ./$file_name'"],
}
```

In VSC same could be achieved using [Tasks](https://code.visualstudio.com/docs/editor/tasks) functionality. The difference is you couldn't create global settings, whatever you do will be saved in the project you're working in. Another difference is you could write something in the console and it will be sent over to script's STDIN, which is unachievable in Sublime Text.

To start, open your project task configuration file via **Ctrl**+**P**, **>Configure Task Runner**, **Others**. Then paste following json text and customize it for yourself:

``` json
{
    // See https://go.microsoft.com/fwlink/?LinkId=733558
    // for the documentation about the tasks.json format
    "version": "2.0.0",
    "tasks": [
        {
            "taskName": "server.example.org",
            "command": "rsync -az '${file}' server.example.org:~ && ssh server.example.org 'chmod +x ./${fileBasename}; ./${fileBasename}'",
            "type": "shell",
            "group": {
                "kind": "build",
                "isDefault": true
            }
        }
    ]
}
```

What will it do? Copy currently open file to server's home (~) folder using rsync (non-verbose mode, add **-v** in case of trouble), then make it executable and run it via ssh.

<!--more-->
