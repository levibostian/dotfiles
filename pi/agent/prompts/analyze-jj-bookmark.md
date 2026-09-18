---
description: Read all changes made to the current jj bookmark and await further instruction. 
---

You're in a jj repo. Your task is to analyze all of the changes that I have made to the jj current bookmark to catch you up to speed with what I am working on. Analyze the jj working copy id, commit description, and diff of all of the commits. 

Run the command `jj diff --no-pager -r "$(jj-parent-bookmark)..$(jj-curr-bookmark)"` to get the diff. 
Run the command `jj log -r "$(jj-bottom-stack)::$(jj-curr-bookmark)" --no-graph -T 'change_id ++ " " ++ commit_id.short() ++ " " ++ description.first_line() ++ "\n"'` to get the working copy id, commit description. 

Then await further instructions. 