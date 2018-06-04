#include <sdkhooks>
#include <sdktools>
#include <tf2_stocks>
#include <new_rpg>

public OnEntityCreated(entity, const String:classname[]) if (StrEqual(classname, "instanced_scripted_scene", false)) 
	SDKHook(entity, SDKHook_Spawn, OnSceneSpawned);
	
public Action:OnSceneSpawned(entity)
{
	if(!IsValidEntity(entity)) return Plugin_Continue;
	new client = GetEntPropEnt(entity, Prop_Data, "m_hOwner"), String:scenefile[128];
	
	if(!AliveCheck(client)) return Plugin_Continue;
	if(!GetAbility(client, "songoku")) return Plugin_Continue;
	
	GetEntPropString(entity, Prop_Data, "m_iszSceneFile", scenefile, sizeof(scenefile));
	if (StrEqual(scenefile, "scenes/player/pyro/low/taunt02.vcd") && GetEntityFlags(client) & FL_ONGROUND)
	{
		if (TF2_IsPlayerInCondition(client, TFCond_Taunting)) return Plugin_Continue;
		CreateTimer(2.0, FireBall, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Continue;
}

public Action:FireBall(Handle:timer, any:client)
{
	if(!AliveCheck(client)) return Plugin_Stop;
	if(!GetAbility(client, "songoku")) return Plugin_Stop;
	if(!TF2_IsPlayerInCondition(client, TFCond_Taunting)) return Plugin_Stop;
	
	new Float:vPosition[3];
	new Float:vAngles[3];
	vAngles[2] += 25.0;
	new iTeam = GetClientTeam(client);
	GetClientEyePosition(client, vPosition);
	GetClientEyeAngles(client, vAngles);

	RocketsGameFiredSpell(client, "tf_projectile_lightningorb", vPosition, vAngles, 200.0, 800.0, iTeam, true);				
	return Plugin_Continue;
}

stock RocketsGameFiredSpell(client, String:entity[], Float:vPosition[3], Float:vAngles[3], Float:flSpeed = 650.0, Float:flDamage = 800.0, iTeam, bool:bCritical = false){

	new String:strClassname[32] = "CTFProjectile_Rocket";	
	new iRocket = CreateEntityByName(entity);
	if(!IsValidEntity(iRocket))
		return -0;
		
	decl Float:vVelocity[3];
	decl Float:vBuffer[3];
    
	GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
    
	vVelocity[0] = vBuffer[0]*flSpeed;
	vVelocity[1] = vBuffer[1]*flSpeed;
	vVelocity[2] = vBuffer[2]*flSpeed;
    
	TeleportEntity(iRocket, vPosition, vAngles, vVelocity);
    
	SetEntData(iRocket, FindSendPropInfo("CTFProjectile_Rocket", "m_iTeamNum"), GetClientTeam(client), true);
	SetEntData(iRocket, FindSendPropInfo(strClassname, "m_bCritical"), bCritical, true);
	SetEntPropEnt(iRocket, Prop_Send, "m_hOwnerEntity", client);
	SetEntDataFloat(iRocket, FindSendPropInfo(strClassname, "m_iDeflected") + 4, flDamage, true);
    
	SetVariantInt(iTeam);
	AcceptEntityInput(iRocket, "TeamNum", -1, -1, 0);

	SetVariantInt(iTeam);
	AcceptEntityInput(iRocket, "SetTeam", -1, -1, 0); 
    
	DispatchSpawn(iRocket);
	return iRocket;
}