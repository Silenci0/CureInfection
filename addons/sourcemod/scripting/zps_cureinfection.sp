/************************************************************************
*************************************************************************
[ZPS] Cure Infection
Description: This plugin is meant to be an updated version of the pillscure
    plugin , but with a few more options to allow for tweaks to gameplay. 
    Server owners can enable/disable cure from being applied to medkits
    and/or pills separately from the configuration file. There is also a 
    chance feature that allows server owners to create a random chance
    that these items will cure the infection instead of guaranteeing it.
    
Pills Cure Plugin Author:
    Sammy-ROCK!

Author:
    Mr. Silence
    
*************************************************************************
*************************************************************************
This plugin is free software: you can redistribute 
it and/or modify it under the terms of the GNU General Public License as
published by the Free Software Foundation, either version 3 of the License, or
later version. 

This plugin is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this plugin.  If not, see <http://www.gnu.org/licenses/>.
*************************************************************************
*************************************************************************/
// Make sure it reads semicolons as endlines
#pragma semicolon 1

// Includes
#include <sourcemod>
#include <sdktools>

// Defines
#define PLUGIN_VERSION "1.1"
#define TEAM_SURVIVOR 2
#define TEAM_ZOMBIE 3

// Handles and other globals
new Handle:cvar_CIEnabled           = INVALID_HANDLE; // Enables/Disable plugin
new Handle:cvar_CIPillsCure         = INVALID_HANDLE; // Allow/Disallow pills to cure
new Handle:cvar_CIPCureChance       = INVALID_HANDLE; // Chance that pills cure infection
new Handle:cvar_CIHealthKitsCure    = INVALID_HANDLE; // Allow/Disallow healthkits to cure infection
new Handle:cvar_CIHKCureChance      = INVALID_HANDLE; // Chance that healthkits cure infection
new Handle:cvar_CIBackFire          = INVALID_HANDLE; // Enable cure backfire (based on chance of infection per item)
new Handle:cvar_CIFarGone           = INVALID_HANDLE; // Enable cure only if players are not too infected 
new Handle:cvar_CIFGoneTime         = INVALID_HANDLE; // The cut off time limit before a player is considered too far gone

// If the cure backfired, then we shouldn't allow them to be cured
new bool:g_bCIBackFired[MAXPLAYERS+1];
new bool:g_bCIKeyPressed[MAXPLAYERS+1];

// Other stuff
new InfectedOffset = -1;

// Plugin info/credits
public Plugin:myinfo = 
{
    name = "[ZPS] Cure Infection",
    author = "Mr.Silence",
    description = "Cure Infection via health items",
    version = PLUGIN_VERSION,
    url = "https://forums.alliedmods.net/"
}

///////////////////////////////////
//===============================//
//=====[ EVENTS ]================//
//===============================//
///////////////////////////////////
// Setup our config file and cvars
public OnPluginStart()
{
	// Give our handles information
    cvar_CIEnabled          = CreateConVar("sm_cureinfection_enabled", "1", "Enable/Disable Cure Infection plugin. \nEnable = 1  \nDisable = 0", FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_PLUGIN, true, 0.0, true, 1.0);
    cvar_CIPillsCure        = CreateConVar("sm_cureinfection_pills", "1", "Allow/Disallow pills to cure infection. \nEnable = 1  \nDisable = 0", FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_PLUGIN, true, 0.0, true, 1.0);
    cvar_CIPCureChance      = CreateConVar("sm_cureinfection_pchance", "1.0", "The chance that pills will cure infection. \n 0.1 (10%)- Lowest chance to cure infection,\n 1.0 (100%)- Guarantees cure infection.", FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_PLUGIN, true, 0.1, true, 1.0);
    cvar_CIHealthKitsCure   = CreateConVar("sm_cureinfection_healthkits", "1", "Allow/Disallow healthkits to cure infection. \nEnable = 1  \nDisable = 0", FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_PLUGIN, true, 0.0, true, 1.0);
    cvar_CIHKCureChance     = CreateConVar("sm_cureinfection_hkchance", "1.0", "The chance that healthkits will cure infection. \n 0.1 (10%)- Lowest chance to cure infection,\n 1.00 (100%)- Guarantees cure infection.", FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_PLUGIN, true, 0.1, true, 1.0);
    cvar_CIBackFire         = CreateConVar("sm_cureinfection_backfire", "0", "Enable/Disable option to have the cure backfire. \nEnable = 1  \nDisable = 0", FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_PLUGIN, true, 0.0, true, 1.0);
    cvar_CIFarGone          = CreateConVar("sm_cureinfection_fargone", "0", "Enable/Disable the option to only cure players who aren't about to turn, but are just infected. \nEnable = 1  \nDisable = 0", FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_PLUGIN, true, 0.0, true, 1.0);
    cvar_CIFGoneTime        = CreateConVar("sm_cureinfection_fgonetime", "5.0", "The time of infection, in seconds, when the cure becomes ineffective. \n5.0 = 5 seconds before turning into a zombie", FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_PLUGIN, true, 0.1, true);
    
    // Plugin version
    CreateConVar("sm_cureinfection_version", PLUGIN_VERSION, "[ZPS] Cure Infection Version.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
    // Get the offset for cure infection
    InfectedOffset = FindSendPropOffs("CHL2MP_Player", "m_IsInfected");
    
    // Hook player spawn in order to clear any flags
    HookEvent("player_spawn", Event_CIPlayerSpawn);
    
	// Create a config file for the plugin
    AutoExecConfig(true, "plugin.cureinfection");
}

// Set some variables to default values
public OnMapStart()
{
    for(new i = 1; i <= MaxClients; i++)
    {
        g_bCIBackFired[i] = false;
        g_bCIKeyPressed[i] = false;
    }
}

// Set some variables to default values
public OnClientDisconnect(client)
{
    g_bCIBackFired[client] = false;
    g_bCIKeyPressed[client] = false;
}

// When the player hits use, look at the item they use and see if its a health item, then cure based on our settings.
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
    // First off, is our plugin enabled?
    if(GetConVarBool(cvar_CIEnabled))
    {
        // It is! Did our player hit the IN_USE command, are they a survivor, and are they infected?
        // Find out in the next exciting if-statement of Sourcepawn Z!
        if((buttons & IN_USE) == IN_USE && GetClientTeam(client) == TEAM_SURVIVOR && GetEntData(client, InfectedOffset, 4))
        {
            // We have to check if they are holding the button down.
            if (g_bCIKeyPressed[client] == true)
            {
                // If the button was pressed and it is currently detected, stop them from that the use key is being held down
                if (GetClientButtons(client) == IN_USE)
                {
                    return Plugin_Continue;
                }
                // If not, then go through the rest of the plugin unhindered and change flags!
                else
                {
                    g_bCIKeyPressed[client] = false;
                }
            }
            
            // Now lets find our entity based on the client's viewpoint
            new ent = TraceToEntity(client);
          
            // Is it valid at all?
            if(IsValidEntity(ent) && IsValidEdict(ent))
            {
                // Compare the prop's position to the clients
                new Float:vecPosEntity[3] = 0.0;
                new Float:vecPosClient[3] = 0.0;
                GetClientEyePosition(client, vecPosClient);
                GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vecPosEntity);
                
                // Get the distance and see if its less than 94 hammer, based on the position of the entity/player.
                // NOTE: Seems that 90 units is as far as we can go away from the item before not being able to use it. 
                //       Something tells me this might end up being a problem somehow...
                if(GetVectorDistance(vecPosClient, vecPosEntity, false) <= 94.0)
                {
                    // Yes it is! Lets find out which item it is!
                    new String:edictname[64];
                    GetEdictClassname(ent, edictname, 64);

                    // Lets find out which item we are using. 
                    // Pills
                    if(StrEqual(edictname, "item_healthvial", true) && GetConVarBool(cvar_CIPillsCure))
                    {   
                        CurePInfection(client, GetConVarFloat(cvar_CIPCureChance));
                        g_bCIKeyPressed[client] = true;
                        return Plugin_Continue;
                    }
                
                    // Health kits
                    if(StrEqual(edictname, "item_healthkit", true) && GetConVarBool(cvar_CIHealthKitsCure))
                    {
                        CurePInfection(client, GetConVarFloat(cvar_CIHKCureChance));
                        g_bCIKeyPressed[client] = true;
                        return Plugin_Continue;
                    }
                }
            }
        }
    }
    return Plugin_Continue;
}

public Action:Event_CIPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event,"userid"));
    g_bCIBackFired[client] = false;
    g_bCIKeyPressed[client] = false;
}

///////////////////////////////////
//===============================//
//=====[ FUNCTIONS ]=============//
//===============================//
///////////////////////////////////
// Trace the entity to the player client
public TraceToEntity(client)
{
    // Get both eye position and angle vectors of our client
    new Float:vecClientEyePos[3], Float:vecClientEyeAng[3];
    GetClientEyePosition(client, vecClientEyePos);
    GetClientEyeAngles(client, vecClientEyeAng);
    
    // Trace me like one of your french girls!
    // NOTE: This method does not use local variables/handles. Instead, it uses the global handles.
    //       Since Sourcemod will never use multi-threading, this is actually safer/more efficient than
    //       using handles.
    TR_TraceRayFilter(vecClientEyePos, vecClientEyeAng, MASK_VISIBLE, RayType_Infinite, TraceRayDontHitSelf, client);
	
    // If its hitting the right entity... 
    // NOTE: fyi, we using the global trace result from the above statement! This is why it seems like magic!
    if(TR_DidHit(INVALID_HANDLE))
    {
        // Return our entity's index!
        return TR_GetEntityIndex(INVALID_HANDLE);
    }
    
    // Return -1 for and invalid entity.
    return -1;
}

// Check our data to check that the entity we "hit" is not itself
// In other words: STOP HITTING YOURSELF! STOP HITTING YOURSELF! STOP HITTING YOURSELF!
public bool:TraceRayDontHitSelf(entity, mask, any:data)
{
    if(entity == data)
    {
        return false;
    }
    return true;
}

// Method used to determine how to cure infection for whatever item we want
// ... or to make it backfire depending on chance >:3
CurePInfection(client, Float:chance)
{
    // Get our chance of infection and player health
    new Float:rand = GetRandomFloat(0.0, 1.0);
    new health = GetClientHealth(client);
    new Float:getInfectTime = GetTurnTime(client);
    
    // If our chance setting is greater than or equal to what was generated, we cure infection
    if(chance >= rand && health < 100)
    {
        // If we enabled the fargone cvar
        if (GetConVarBool(cvar_CIFarGone) && g_bCIBackFired[client] == false)
        {
            if (getInfectTime > GetConVarFloat(cvar_CIFGoneTime))
            {
                PrintToChat(client, "You've been cured from infection!");
                SetEntData(client, InfectedOffset, 0, 4, false);
                return;
            }
            if (getInfectTime <= GetConVarFloat(cvar_CIFGoneTime))
            {
                PrintToChat(client, "The cure did not work, you're too infected to cure...");
                return;
            }
        }
        if (!GetConVarBool(cvar_CIFarGone))
        {   
            PrintToChat(client, "You've been cured from infection!");
            SetEntData(client, InfectedOffset, 0, 4, false);
            return;
        }
    }
    
    // If the cure change is less than what was generated and they have less than 100 health, the user is not cured.
    if(chance < rand && health < 100 && g_bCIBackFired[client] == false)
    {   
        // If backfire was enabled, set the user's turn time to 5 second (almost instant transformation!) 
        // then prevent them from being cured
        if (GetConVarBool(cvar_CIBackFire))
        {
            PrintToChat(client, "It backfired! The infection spreads faster!");
            if (getInfectTime > 5.0)
            {
                g_bCIBackFired[client] = true;
                SetTurnTime(client, 5.0);
            }
            return;
        }
        if (!GetConVarBool(cvar_CIBackFire))
        {
            PrintToChat(client, "The cure was not effective!");
            return;
        }
    }
    return;
}

///////////////////////////////////
//===============================//
//=====[ STOCKS ]================//
//===============================//
///////////////////////////////////
// Player will immediately become infected, turning into a zombie after <seconds> time
stock Float:SetTurnTime(ent, Float:seconds) 
{
    if(!(IsClientInGame(ent) && IsPlayerAlive(ent)))
        return 0.0;
    
    new InfectTimeOffset = FindDataMapOffs(ent,"m_tbiPrev");
    
    new Float:turnTime = GetGameTime() + seconds; // time of zombification
    SetEntData(ent, InfectTimeOffset, turnTime);
    SetEntData(ent, InfectedOffset, 1, 4, false); 
    return turnTime;
}

// Grab player infection time 
stock Float:GetTurnTime(player) 
{
    new InfectTimeOffset = FindDataMapOffs(player,"m_tbiPrev");
    return GetEntDataFloat(player, InfectTimeOffset);
}