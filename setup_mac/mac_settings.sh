#!/bin/bash

source "_utils.sh"

############################################################################################
# MAC SETTINGS
############################################################################################

log_header "MAC SETTINGS"
log "DEBUG" "Source: https://github.com/herrbischoff/awesome-macos-command-line"

# Reduce transparancy for a darker dark mode
defaults write com.apple.universalaccess reduceTransparency -bool true

# -----------------------------------------------------------------------------------------

log "INFO" "Applying Safari settings."

log "DEBUG" "Enable develop menu and web inspector."
defaults write com.apple.Safari IncludeInternalDebugMenu -bool true
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true
defaults write -g WebKitDeveloperExtras -bool true

log "DEBUG" "Hiding Safari's bookmarks bar by default."
defaults write com.apple.Safari ShowFavoritesBar -bool false

log "DEBUG" "Hiding Safari's sidebar in Top Sites."
defaults write com.apple.Safari ShowSidebarInTopSites -bool false

# -----------------------------------------------------------------------------------------

log "INFO" "Applying visual settings."

log "DEBUG" "Use Dark mode."
defaults write -g AppleInterfaceStyle -string Dark

# -----------------------------------------------------------------------------------------

log "INFO" "Applying TextEdit settings."

log "DEBUG" "Use Plain Text Mode as Default."
defaults write com.apple.TextEdit RichText -int 0

# -----------------------------------------------------------------------------------------

log "INFO" "Applying Spaces settings."

log "DEBUG" "Disable Auto Rearrange Spaces Based on Most Recent Use."
defaults write com.apple.dock mru-spaces -bool false

# -----------------------------------------------------------------------------------------

log "INFO" "Applying Dock settings."

log "DEBUG" "Autohide dock"
defaults write com.apple.dock autohide -bool true

log "DEBUG" "Disable bouncing icons"
defaults write com.apple.dock no-bouncing -bool false

log "DEBUG" "Lock dock size"
defaults write com.apple.Dock size-immutable -bool yes

log "DEBUG" "Set a size."
defaults write com.apple.dock tilesize -int 15

log "DEBUG" "Do not show recent apps."
defaults write com.apple.dock show-recents -bool false

log "DEBUG" "Dock only show active applications"
defaults write com.apple.dock static-only -bool true

# -----------------------------------------------------------------------------------------

log "INFO" "Applying SSD disk settings."

log "DEBUG" "Disable Sudden Motion Sensor (Leaving this turned on is useless when you're using SSDs.)."
sudo pmset -a sms 0

# -----------------------------------------------------------------------------------------

log "INFO" "Applying Desktop settings."

log "DEBUG" "Show External Media (External HDs, thumb drives, etc.)."
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true

log "DEBUG" "Show Removable Media (CDs, DVDs, iPods, etc.)."
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true

log "DEBUG" "Show Network Volumes (AFP, SMB, NFS, WebDAV, etc.)."
defaults write com.apple.finder ShowMountedServersOnDesktop -bool true

# -----------------------------------------------------------------------------------------

log "INFO" "Applying Finder settings."

log "DEBUG" "Show All File Extensions."
defaults write -g AppleShowAllExtensions -bool true

log "DEBUG" "Toggle Folder Visibility in Finder."
chflags nohidden ~/Library

log "DEBUG" "Hide all desktop icons"
defaults write com.apple.finder CreateDesktop false

log "DEBUG" "Smooth scrolling."
defaults write -g NSScrollAnimationEnabled -bool true

log "DEBUG" "Rubberband scrolling."
defaults write -g NSScrollViewRubberbanding -bool true

log "DEBUG" "Show pathbar."
defaults write com.apple.finder ShowPathbar -bool true

log "DEBUG" "Show statusbar."
defaults write com.apple.finder ShowStatusBar -bool true

log "DEBUG" "Set Default Finder Location to Home Folder."
defaults write com.apple.finder NewWindowTarget -string "PfLo"
defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}"

log "DEBUG" "Set Sidebar Icon Size (Sets size to 'medium'.)."
defaults write -g NSTableViewDefaultSizeMode -int 2

log "DEBUG" "Use list view in all Finder windows by default."
defaults write com.apple.finder FXPreferredViewStyle Nlsv

log "DEBUG" "Reduce number of recent places" 
defaults write -g NSNavRecentPlacesLimit -int 1

log "DEBUG" "Show all hidden files"
defaults write com.apple.finder AppleShowAllFiles true

# -----------------------------------------------------------------------------------------

log "INFO" "Applying Metadata Files settings."

log "DEBUG" "Disable Creation of Metadata Files on Network Volumes (Avoids creation of .DS_Store and AppleDouble files.)."
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

log "DEBUG" "Disable Creation of Metadata Files on USB Volumes (Avoids creation of .DS_Store and AppleDouble files.)."
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# -----------------------------------------------------------------------------------------

log "INFO" "Applying Keyboard settings."

log "DEBUG" "Disable auto correct"
defaults write -g NSAutomaticSpellingCorrectionEnabled -bool false

# -----------------------------------------------------------------------------------------

log "INFO" "Applying Security settings."

log "DEBUG" "Enable application firewall."
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on

# -----------------------------------------------------------------------------------------

log "INFO" "Applying Date and Time settings."

log "DEBUG" "Set Clock Using Network Time."
sudo systemsetup setusingnetworktime on

# -----------------------------------------------------------------------------------------

log "INFO" "Applying Mouse and Trackpad settings."

log "DEBUG" "Setting trackpad & mouse speed above maximum in UI."
defaults write -g com.apple.trackpad.scaling 6
defaults write -g com.apple.mouse.scaling 6

# -----------------------------------------------------------------------------------------

log "INFO" "Applying Mail app settings."

log "DEBUG" "Setting email addresses to copy as 'foo@example.com' instead of 'Foo Bar <foo@example.com>'."
defaults write com.apple.mail AddressesIncludeNameOnPasteboard -bool false

# -----------------------------------------------------------------------------------------

log "INFO" "Applying Transmission app settings."

log "DEBUG" "Trash original torrent files."
defaults write org.m0k.transmission DeleteOriginalTorrent -bool true

log "DEBUG" "Hide the donate message."
defaults write org.m0k.transmission WarningDonate -bool false

log "DEBUG" "Hide the legal disclaimer."
defaults write org.m0k.transmission WarningLegal -bool false

