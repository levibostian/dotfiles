# dotfiles

What started out as a project to just store my home directory dotfiles has expanded to a suite of tools, configs, and scripts. I use these files to not only setup a mac to get up and running ASAP but I also use these files daily for my workflow. 

# Steps to setup a new mac

* Install homebrew. Open the built-in terminal app that ships with macos and use that to install it. 
* Install [oh-my-zsh](https://ohmyz.sh/). If asked about how to install it, select option to deleting `~/.oh-my-zsh` because the contents that we already have inside are installed in this version controlled repo. We can just restore our extra files after it's installed. 
* Run these commands 

```
cd
git clone git@github.com:levibostian/dotfiles.git .dotfiles
cd .dotfiles
./install 
```

Done! You now have all of your programs installed that you need and a lot of the settings restored. 

* You probably have a private backup made. See `~/.backup` to restore all of that. 
* Setup your personal calendar with Apple Calendar. 
* Go into `~/.startup` and view the README to get your startup scripts running again. 

# dotbot 

This project is setup to work with [dotbot](https://github.com/anishathalye/dotbot). Why?
* Light solution, not heavy. 
* Manage within the project. No dependencies. 
* Does not lock you in. Simply creates sym links for you. 

# Credits 

* [Scripts for setting up Mac](https://github.com/Kevin-De-Koninck/macOS-setup-script)
