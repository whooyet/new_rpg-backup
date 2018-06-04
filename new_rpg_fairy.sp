#include <tf2_stocks>
#include <new_rpg>

public OnPluginStart()
{
	HookEvent("post_inventory_application", iv, EventHookMode_Post);
}

public Action:iv(Handle:event, const String:name2[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(GetAbility(client, "fairy"))
	{
		TF2_AddCondition(client, TFCond:86);
		SetOverlay(client, "");
	}
	else
	{
		if(TF2_IsPlayerInCondition(client, TFCond:86)) TF2_RemoveCondition(client, TFCond:86);
	}
}

stock SetOverlay(client, const String:szOverlay[])
{
    SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & ~FCVAR_CHEAT);
    ClientCommand(client, "r_screenoverlay \"%s\"", szOverlay); 
    SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") | FCVAR_CHEAT);
}