# CureInfection
This ZPS plugin is an advanced pillscure-type plugin that allows for further customization of the ability of health items to cure infection. Not only can you make this plugin work like the original pillscure plugin, you can also do the following with it:

- Decide which health items can cure infection.
- Give health times a chance to cure/fail to cure.
- Disable the cure if players only have seconds before turning.
- Cause the cure to backfire and turn the player into a zombie (based on the item's cure chances)

The plugin checks if the survivor player is infected and if the player's health is less than 100. This way, it will prevent users from being cured if they cannot technically use the health item. Further customizations for the pillscure functionality may be added later or upon consideration.

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

# Changelog
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
