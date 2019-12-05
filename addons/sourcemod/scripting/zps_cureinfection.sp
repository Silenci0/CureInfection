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
#pragma semicolon 1

// Includes
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <zpsinfection_stocks>

#pragma newdecls required

// Defines
#define PLUGIN_VERSION "3.1.0"
#define TEAM_SURVIVOR 2
#define TEAM_ZOMBIE 3

// Handles and other globals
ConVar cvar_CIEnabled           = null; // Enables/Disable plugin
ConVar cvar_CIPillsCure         = null; // Allow/Disallow pills to cure
ConVar cvar_CIPCureChance       = null; // Chance that pills cure infection
ConVar cvar_CIHealthKitsCure    = null; // Allow/Disallow healthkits to cure infection
ConVar cvar_CIHKCureChance      = null; // Chance that healthkits cure infection
ConVar cvar_CIBackFire          = null; // Enable cure backfire (based on chance of infection per item)
ConVar cvar_CIPillsName         = null; // Entity name for pills (configurable via configs)
ConVar cvar_CIHKitName          = null; // Entity name for healthkits (configurable via configs)

// If the cure backfired, then we shouldn't allow them to be cured
bool g_bCIBackFired[MAXPLAYERS+1];
bool g_bCIKeyPressed[MAXPLAYERS+1];

// The name variables used to 
char g_sCIPillsName[PLATFORM_MAX_PATH];
char g_sCIHKitName[PLATFORM_MAX_PATH];

// Plugin info/credits
public Plugin myinfo = 
{
    name = "[ZPS] Cure Infection",
    author = "Mr.Silence",
    description = "Cure Infection via health items",
    version = PLUGIN_VERSION,
    url = "https://github.com/Silenci0/CureInfection"
}

///////////////////////////////////
//===============================//
//=====[ EVENTS ]================//
//===============================//
///////////////////////////////////
// Setup our config file and cvars
public void OnPluginStart()
{
	// Give our handles information.
    cvar_CIEnabled = CreateConVar(
        "sm_cureinfection_enabled", 
        "1", 
        "Enable/Disable Cure Infection plugin. \nEnable = 1  \nDisable = 0", 
        FCVAR_NOTIFY|FCVAR_REPLICATED, true, 0.0, true, 1.0
    );
    
    cvar_CIPillsCure = CreateConVar(
        "sm_cureinfection_pills", 
        "1", 
        "Allow/Disallow pills to cure infection. \nEnable = 1  \nDisable = 0", 
        FCVAR_NOTIFY|FCVAR_REPLICATED, true, 0.0, true, 1.0
    );
    
    cvar_CIPCureChance = CreateConVar(
        "sm_cureinfection_pchance", 
        "1.0", 
        "The chance that pills will cure infection. \n 0.1 (10%)- Lowest chance to cure infection,\n 1.0 (100%)- Guarantees cure infection.", 
        FCVAR_NOTIFY|FCVAR_REPLICATED, true, 0.1, true, 1.0
    );
    
    cvar_CIHealthKitsCure = CreateConVar(
        "sm_cureinfection_healthkits", 
        "1", 
        "Allow/Disallow healthkits to cure infection. \nEnable = 1  \nDisable = 0", 
        FCVAR_NOTIFY|FCVAR_REPLICATED, true, 0.0, true, 1.0
    );
    
    cvar_CIHKCureChance = CreateConVar(
        "sm_cureinfection_hkchance", 
        "1.0", 
        "The chance that healthkits will cure infection. \n 0.1 (10%)- Lowest chance to cure infection,\n 1.00 (100%)- Guarantees cure infection.", 
        FCVAR_NOTIFY|FCVAR_REPLICATED, true, 0.1, true, 1.0
    );
    
    cvar_CIBackFire = CreateConVar(
        "sm_cureinfection_backfire", 
        "0", 
        "Enable/Disable option to have the cure backfire. \nEnable = 1  \nDisable = 0", 
        FCVAR_NOTIFY|FCVAR_REPLICATED, true, 0.0, true, 1.0
    );
    
    cvar_CIPillsName = CreateConVar(
        "sm_cureinfection_pillsname",
        "item_healthvial",
        "Specifies the entity name for the pills that we'll be looking for. This should only be changed if the pills entity name has been changed."
    );
    
    cvar_CIHKitName = CreateConVar(
        "sm_cureinfection_hkitname",
        "item_healthkit",
        "Specifies the entity name for the healthkits that we'll be looking for. This should only be changed if the healthkit entity name has been changed."
    );
    
    // Plugin version
    CreateConVar("sm_cureinfection_version", PLUGIN_VERSION, "[ZPS] Cure Infection Version.", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
    
    // Initialize infection info!
    ZPSInfectionInit();
    
    // Hook player spawn in order to clear any flags
    HookEvent("player_spawn", Event_CIPlayerSpawn);
    
	// Create a config file for the plugin
    AutoExecConfig(true, "plugin.cureinfection");
}

public void OnPluginEnd()
{
    UnhookEvent("player_spawn", Event_CIPlayerSpawn);
}

// Set some variables to default values
public void OnMapStart()
{
    // Get the names of our pills and healthkits
    GetConVarString(cvar_CIPillsName, g_sCIPillsName, PLATFORM_MAX_PATH);
    GetConVarString(cvar_CIHKitName, g_sCIHKitName, PLATFORM_MAX_PATH);

    // Set our stuff to defaults, just in case
    for(int i = 1; i <= MaxClients; i++)
    {
        g_bCIBackFired[i] = false;
        g_bCIKeyPressed[i] = false;
    }
}

// Set some variables to default values
public void OnClientDisconnect(int client)
{
    g_bCIBackFired[client] = false;
    g_bCIKeyPressed[client] = false;
}


/////////////////////////////////
//=============================//
//=====[ Actions ]=============//
//=============================//
/////////////////////////////////
// NOTE: Figure out a more accurate way to ensure the entity we clicked use on actually does what its supposed to...
// When the player hits use, look at the item they use and see if its a health item, then cure based on our settings.
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
    // First off, is our plugin enabled?
    if(GetConVarBool(cvar_CIEnabled))
    {
        // It is! Did our player hit the IN_USE command, are they a survivor, and are they infected?
        // Find out in the next exciting if-statement of Sourcepawn Z!
        if((buttons & IN_USE) == IN_USE && GetClientTeam(client) == TEAM_SURVIVOR && IsPlayerInfected(client))//GetEntData(client, InfectedOffset, 4))
        {
            // If we have enabled the backfire 
            if (GetConVarBool(cvar_CIBackFire))
            {
                if (g_bCIBackFired[client] == true)
                {
                    return Plugin_Continue;
                }
            }
            
            // We have to check if they are holding the button down just in case!
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
            int ent = TraceToEntity(client);
          
            // Is it valid at all?
            if(IsValidEntity(ent) && IsValidEdict(ent))
            {
                // Compare the prop's position to the clients
                float vecPosEntity[3] = 0.0;
                float vecPosClient[3] = 0.0;
                GetClientEyePosition(client, vecPosClient);
                GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vecPosEntity);
                
                // Get the distance and see if its less than 100 hammer, based on the position of the entity/player.
                // NOTE: Seems that 100 units is as far as we can go away from the item before not being able to use it. 
                //       Something tells me this might end up being a problem somehow...
                if(GetVectorDistance(vecPosClient, vecPosEntity, false) <= 100.0)
                {
                    // Yes it is! Lets find out which item it is!
                    char edictname[64];
                    GetEdictClassname(ent, edictname, 64);

                    // Pills
                    if(StrEqual(edictname, g_sCIPillsName, true) && GetConVarBool(cvar_CIPillsCure))
                    {   
                        CurePInfection(client, GetConVarFloat(cvar_CIPCureChance));
                        g_bCIKeyPressed[client] = true;
                        return Plugin_Continue;
                    }
                    
                    // Health kits
                    if(StrEqual(edictname, g_sCIHKitName, true) && GetConVarBool(cvar_CIHealthKitsCure))
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

public Action Event_CIPlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event,"userid"));
    g_bCIBackFired[client] = false;
    g_bCIKeyPressed[client] = false;
}

///////////////////////////////////
//===============================//
//=====[ FUNCTIONS ]=============//
//===============================//
///////////////////////////////////
// Trace the entity to the player client
public int TraceToEntity(int client)
{
    // Get both eye position and angle vectors of our client
    float vecClientEyePos[3] = 0.0; 
    float vecClientEyeAng[3] = 0.0;
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
public bool TraceRayDontHitSelf(int entity, int mask, any data)
{
    if(entity == data)
    {
        return false;
    }
    return true;
}


// Method used to determine how to cure infection for whatever item we want
// ... or to make it backfire depending on chance >:3
void CurePInfection(int client, float chance)
{
    // Get our chance of infection and player health
    float rand = GetRandomFloat(0.0, 1.0);
    int health = GetClientHealth(client);

    // If our chance setting is greater than or equal to what was generated, we cure infection
    if(chance >= rand && health < 100)
    {
        PrintToChat(client, "You've been cured from infection! Chance: %f Rand: %f", chance, rand);
        UnInfectPlayer(client);
        return;
    }
    
    // If the cure change is less than what was generated and they have less than 100 health, the user is not cured.
    if(chance < rand && health < 100)
    {   
        // If backfire was enabled, set the user's turn time to 5 second (almost instant transformation!) 
        // Otherwise, just let them know they are not cured
        if (GetConVarBool(cvar_CIBackFire))
        {
            PrintToChat(client, "It backfired! The infection spreads faster!");
            InfectPlayer(client, -45.0);
            g_bCIBackFired[client] = true;
            return;
        }
        if (!GetConVarBool(cvar_CIBackFire))
        {
            PrintToChat(client, "The cure did not work, you'll need more drugs... ");
            return;
        }
    }
    return;
}
