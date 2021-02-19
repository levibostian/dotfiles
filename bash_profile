# File exists only to load .bashrc file on terminal shell startup
[[ -s ~/.bashrc ]] && source ~/.bashrc

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/levibostian/google-cloud-sdk/path.bash.inc' ]; then . '/Users/levibostian/google-cloud-sdk/path.bash.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/levibostian/google-cloud-sdk/completion.bash.inc' ]; then . '/Users/levibostian/google-cloud-sdk/completion.bash.inc'; fi
