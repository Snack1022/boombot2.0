# BoomBot2.0
Step up, soldiers! Your new bot has arrived!  

### About the developer
Hi, my name is Cubuzz, I'm a developer since 2012. I've been coding Discord Bots since quite some time now and because a friend of mine asked me to code a bot for him, I thought I'd make it open-source.  

### About this bot
This bot was coded in order to improve the abilities a user has when using Discord. A few example features:
* Temporary Roles
* Re-Assign Roles on rejoin
* Enable you to ping un-pingable roles (coming soon)
* Auto-Moderation
* more to come!

### How to setup:
* Install ruby.
> Windows users: Go to rubyinstaller.org and download a version newer than 2.4  
> Linux users: Run 'apt install ruby'. If that doesn't work, try 'apt-get install ruby' or add sudo.  
> Run 'gem install bundler'  
> Run 'bundle install' in current directory  

* Create a file called 'config.yml' in the bot directory and add the following to it:
`---
:token: <Your Bot Token>
:clid: <Your Bot Client ID>
:owner:
  - <Owner 1 User ID>
  - <Owner 2 User ID>
    (etc.)
:permitted:
  - <Role ID 1 of permitted roles list>
  - <Role ID 2 of permitted roles list>
    (etc.)`

* Launch the bot from a command line using `ruby ./main.rb`
