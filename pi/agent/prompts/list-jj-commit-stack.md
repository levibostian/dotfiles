---
description: List all of the jj commits in current jj bookmark and await further instruction. 
---

You're in a jj repo. Your task is to list all of the jj working copy ids and 1st line of commit description on the current jj bookmark. 

Run the command `jj log -r "$(jj-bottom-stack)::$(jj-curr-bookmark)" --no-graph -T 'change_id ++ " " ++ commit_id.short() ++ " " ++ description.first_line() ++ "\n"'` to get the working copy id, commit description. 

Then await further instructions. 