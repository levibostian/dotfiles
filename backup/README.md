# ~/.backup — mackup config for settings sync to Dropbox

## What's here

| file/dir | purpose |
|---|---|
| `mackup.cfg` | main mackup config. Manually edit it and also use scripts in this dir to generate parts of it. |
| `applications/*.cfg` | collection of custom mackup configs that are not built-in to mackup. |
| `suggest-mackup` | given an app name, print the mackup cfg it should use (built-in if one exists, else a detected guess) |
| `run-backup` | runs `mackup backup` |

## Daily workflow

```sh
~/.backup/run-backup
```

