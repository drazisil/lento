---
allowed-tools: Bash(find:*)
description: Show whether Lento mode is currently on or off in this directory
---

!`find . -maxdepth 1 -name '.lento-mode'`

If the line above shows `./.lento-mode`, Lento is **on** for this working directory. If the line is empty, Lento is **off**.
