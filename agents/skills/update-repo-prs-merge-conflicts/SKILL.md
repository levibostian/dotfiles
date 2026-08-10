---
name: update-repo-prs-merge-conflicts
description: Gets list of pull requests for this github repo (the repository linked to the cwd git repo), checks what ones have merge conflicts, and resolves the merge conflict. 
---

# Get list of pull requests that have merge conflicts

Run command: `gh pr list --author @me --state open --json number,title,url,mergeStateStatus,mergeable,headRefName,baseRefName` to get a list of all of my pull requests that are open, and check which ones have merge conflicts. The `mergeStateStatus` field will be `DIRTY` for pull requests that have merge conflicts.

If there are none, tell the user and exit. 

# Update each of the pull requests

Treat the pull request as the single source of truth regarding the base branch and the head branch. For each pull request that has merge conflicts, do the following:
1. Checkout the base branch of the pull request. Note: the branch might be part of a git worktree, so you may need to use `git worktree list` to find the path to the base branch. If you can't find it, you may need to fetch from origin. 
2. Pull the latest changes from the remote for the base branch.
3. Checkout the head branch of the pull request.
4. Merge the base branch into the head branch.
5. Run skill `/skill:resolving-merge-conflicts` to resolve the merge conflicts. 
6. Make sure the linter, formatter, and tests pass. If they don't, fix them. If you can't fix them, tell the user and exit.
7. Commit the changes. DO NOT PUSH the changes. 

# Summary 

Tell the user what branches you made commits to. 

