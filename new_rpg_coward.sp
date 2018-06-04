#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <new_rpg>

new Float:CoolTime[MAXPLAYERS+1];

public OnPluginStart()
{
	HookEvent("post_inventory_application", iv, EventHookMode_Post);
}

public OnClientPutInServer(i)
{
	CoolTime[i] = 0.0;
}

public Action:iv(Handle:event, const String:name2[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(GetAbility(client, "coward"))
	{
		badak(client, -85.0);
		CreateTimer(0.1, BadakTimer, client);
	}
	else
	{
		badak(client, 0.0);
		CreateTimer(0.1, BadakTimer, client);
	}
}

public Action OnClientCommandKeyValues(int client, KeyValues kv)
{
	char strCmd[256];
	kv.GetSectionName(strCmd, 256);
	
	if(StrEqual(strCmd, "+use_action_slot_item_server") && IsPlayerAlive(client) && GetAbility(client, "coward"))
	{
		if(CheckCoolTime(client, 20.0))
		{
			if(GetClientTeam(client) == 2) ChangeClientTeamAlive(client, 3);
			else if(GetClientTeam(client) == 3) ChangeClientTeamAlive(client, 2);
			CoolTime[client] = GetEngineTime();
		}
		else PrintToChat(client, "\x0320 초를 기다려야합니다. (%.1f 초)", GetEngineTime() - CoolTime[client]);
	}
	return Plugin_Continue;
}

stock bool:CheckCoolTime(any:iClient, Float:fTime)
{
	if(!AliveCheck(iClient)) return false;
	if(GetEngineTime() - CoolTime[iClient] >= fTime) return true;
	else return false;
}

stock ChangeClientTeamAlive(client, team){
	SetEntProp(client, Prop_Send, "m_lifeState", 2);
	ChangeClientTeam(client, team);
	SetEntProp(client, Prop_Send, "m_lifeState", 0);
}

public Action:BadakTimer(Handle:timer, any:client) SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);


stock badak(client, Float:value)
{
	decl Float:StartAngle[3], String:modelPath[PLATFORM_MAX_PATH];
	new String:Input[100];

	GetClientModel(client, modelPath, sizeof(modelPath));

	SetVariantString(modelPath);
	AcceptEntityInput(client, "SetCustomModel", client);
	
	GetClientEyeAngles(client, StartAngle);
	
	SetVariantBool(true);
	StartAngle[0] = value;
	
	Format(Input, sizeof(Input), "%.1f %.1f %.1f", StartAngle[0], StartAngle[1], StartAngle[2]);
	
	SetVariantString(Input);
	AcceptEntityInput(client, "SetCustomModelRotation", client);
}