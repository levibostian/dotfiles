---
description: Create a jj parent commit. Just a prompt that contains the commands so models that don't know jj well will have success in less steps. 
---

Create a parent jj commit. I want the files <list> committed alone in a NEW commit that becomes the parent of the current working copy, sitting on top of the current parent. Non-interactive:
 
```bash
EDITOR=true jj split -A "@-" -- <files...>
jj describe @- -m "<message>"
```
 
Then verify with jj log -r '@ | @- | @--'. If jj reports stray/conflicted commits, abandon them (jj abandon <id>) before finishing.