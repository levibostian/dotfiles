# dotfiles

Home directory dotfiles as well as scripts to setup Mac. 

This project should be all that I need in order to setup a new Mac. 

# Setup Mac

* When you first startup terminal, it may be set to zsh instead of bash as your shell. Run `chsh -s /bin/bash` to change the shell to bash for your user.

* Run the scripts in `./setup_mac` in this order:

1. `brew.sh`
2. `langs.sh`
3. `brew_install.sh`
4. `manual.sh`
5. `brew_cask.sh`
6. `xcode.sh`
7. `appstore.sh`
8. `mac_settings.sh`
9. `clean.sh`

* Setup SSH on this machine. Open 1Password and download files `~/.ssh/id_rsa` and `~/.ssh/id_rsa.pub`

* Go into 1Password and follow instructions for New mac install. There are more private keys in there to install. 

* Then, restart your Mac to apply all settings. 

# dotfiles 

This project is setup to work with [dotbot](https://github.com/anishathalye/dotbot). Why?
* Light solution, not heavy. 
* Manage within the project. No dependencies. 
* Does not lock you in. Simply creates sym links for you. 

To use...

```
cd
git clone git@github.com:levibostian/dotfiles.git .dotfiles
cd .dotfiles
./install # downloads and runs dotbot 
```

# Restore backups

I have enabled settings syncing for many applications. Here are some instructions to get back up and running with all of my apps. 

* Import keys into GNU GPG. Download file export from 1Password. 

* Open VSCode > Install [settings sync plugin](https://marketplace.visualstudio.com/items?itemName=Shan.code-settings-sync) and follow instructions to enable sync with existing backup. 

* Go through directories in Dropbox where I have settings files saved. Restore those files. 

# Credits 

* [Scripts for setting up Mac](https://github.com/Kevin-De-Koninck/macOS-setup-script)