# cronjobs 

This is meant to be my easy way to create and manage cronjobs.

# Create new cronjob

1. create a new script inside of this directory. 
2. Test it works by running it: `./scripts/my-new-cronjob.sh`
3. Add a new line to the `jobs-list` file. 
4. Run `./sync-jobs` to update your crontab.

# Debugging/testing 

I used this prompt in an ai agent: 

```
run this loop:
- delete the /tmp/cron-update-pi.log file
- update the @jobs-list file to run the update-pi script 1 minute
from now.
- run @sync-jobs to update cron's schedule.
- wait for /tmp/cron-update-pi.log to get created, indicating the
cronjob ran.
- read the /tmp/cron-update-pi.log file and check for errors.
```

I needed this because agents by default will just run the script in my current terminal session, which is not the same as running it in a cronjob.