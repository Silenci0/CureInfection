# CureInfection
This ZPS plugin is an advanced pillscure-type plugin that allows for further customization of the ability of health items to cure infection. Not only can you make this plugin work like the original pillscure plugin, you can also do the following with it:

- Decide which health items can cure infection.
- Give health times a chance to cure/fail to cure.
- Disable the cure if players only have seconds before turning.
- Cause the cure to backfire and turn the player into a zombie (based on the item's cure chances)

The plugin checks if the survivor player is infected and if the player's health is less than 100. This way, it will prevent users from being cured if they cannot technically use the health item. Further customizations for the pillscure functionality may be added later or upon consideration.

KNOWN BUGS:
- Reloading this plugin or simply reloading the server (ie: round restart, map restart, etc.) in order to update the plugin can cause the plugin to bug out. I am assuming this is due to how I've had to deal with infection in general with all the handles and timers needed to calculate this.
- When "Far Gone" mode is enabled and a player is infected, depending on whether the round had just started/server just rebooted, it does not always create the timer which would sometimes lead to the infection never being cured. This was with 100% infection rate however.

Also, please keep in mind that I had to change a lot of things to get the plugin to work in a fashion similar to how it used to work. Because of this, there are bound to be bugs. I have tested the plugin enough times that I can say the main features all work, but there are bound to be bugs with the plugin. Feel free to report them or fix them yourself if you'd rather. Just be sure to share with others that which has been shared with you.

If you find any bugs, contact me via my Steam group: https://steamcommunity.com/groups/silencesfuncorner

# Cvars
The following cvars are available in the plugin:
    
- sm_cureinfection_enabled = Disables/Enables the plugin.
- sm_cureinfection_pills = Disable/Enables cure infection on the pill bottle health item.
- sm_cureinfection_pchance = Sets the chance that the pill bottles cures infection. Requires sm_cureinfection_pills to be enabled. 1.0 = 100%
- sm_cureinfection_healthkits = Disable/Enables cure infection on the healthkit health item.
- sm_cureinfection_hkchance = Sets the chance that the pill bottles cures infection. Requires sm_cureinfection_healthkits to be enabled. 1.0 = 100%
- sm_cureinfection_backfire = Optional setting that will cause the player to zombify faster upon cure failure.
- sm_cureinfection_fargone = Optional setting that can cause the cure to be ineffective if player has been infected for too long.
- sm_cureinfection_fgonetime = The time until infection, in seconds, in which the cure becomes ineffective. Requires sm_cureinfection_fargone to be enabled. Defauilt is 5 seconds.
- sm_cureinfection_infecttime = ZPS's overall infection time in seconds. This does not need to be changed, but it was added in case infection time was ever updated in a future game update.Do not change this unless the game was updated and infection time changed.


# Changelog

2.0 Update (06-20-2018)
----------------------
- Added the ZPS Infection Stocks includes/gamedata to the plugin. Because of the changes to how infection is managed between 2.4.1 and 3.0, a lot of things had to change, particularly we have to use virtual function offsets to grab the correct infection functions from the game instead of referencing a pointer. 
- Added a timer to gauge in-game infection time so that we can use the "Far Gone" mode. Currently, infection lasts about 53 seconds total (the last 2-3 seconds are the transformation). The plugin uses 50 seconds as the basis of the infection timer.
- Added a cvar "sm_cureinfection_infecttime" that manages in-game infection time. This does not need to be changed (I discourage doing this currently), however if an update comes up that changes the length of infection time, you can use this to change it without changing code.
- Overhauled most of the code that utilized old infection logic and removed a few methods (or added them to the infection stocks include).
- Please keep in mind that this plugin was not exactly simple to recreate, so there are bound to be bugs. If you find any, please report them to me via my Steam Group!

1.1 Update (06-08-2017)
-----------------
- Fixed an issue with button presses and the CureInfection method.
- Fixed bug with health items not curing the user.
- Refined code to get cvars to work correctly.
- Added global client flags to control cure functionality as well as conditions to clear said flags.

1.0 Initial Commit (06-04-2017)
-----------------
- Cure infection plugin created.
- Created cvars for each health item (pills and healthkits) as well as an infection cure chance for each.
- Created backfire cvar. This setting will cause the acceleration of the infection, causing them to become a zombie almost instantly. This assumes that the health item fails to cure the user.
- Created fargone cvar. This setting is used to determine if a player is too infected to cure, based on the time, in seconds, specified.
- Created cvar to disable/enable the plugin.
- Added config file for plugin (plugin will also auto generate a config file).
- Compiled on Sourcemod 1.7.3
