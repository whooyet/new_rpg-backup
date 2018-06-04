#include <sdkhooks>
#include <sdktools>
#include <tf2_stocks>
#include <new_rpg>

#define SOUND_LASER "ambient/levels/labs/electric_explosion1.wav"

new g_iBeamIndex;
new Float:laserPos[MAXPLAYERS+1][3];

public OnClientPutInServer(client)
{
	laserPos[client][0] = 0.0;
	laserPos[client][1] = 0.0;
	laserPos[client][2] = 0.0;
}

public OnMapStart()
{
	PrecacheSound(SOUND_LASER, true); 
	PrecacheParticleSystem("utaunt_lightning_parent");
	PrecacheParticleSystem("powerup_supernova_explode_red");
	PrecacheParticleSystem("powerup_supernova_explode_blue");
	g_iBeamIndex = PrecacheModel("materials/sprites/purplelaser1.vmt", true);
} 

public OnEntityCreated(entity, const String:classname[]) if (StrEqual(classname, "instanced_scripted_scene", false)) 
	SDKHook(entity, SDKHook_Spawn, OnSceneSpawned);
	
public Action:OnSceneSpawned(entity)
{
	if(!IsValidEntity(entity)) return Plugin_Continue;
	new client = GetEntPropEnt(entity, Prop_Data, "m_hOwner"), String:scenefile[128];
	
	if(!AliveCheck(client)) return Plugin_Continue;
	if(!GetAbility(client, "railgun")) return Plugin_Continue;
	
	GetEntPropString(entity, Prop_Data, "m_iszSceneFile", scenefile, sizeof(scenefile));

	if (StrEqual(scenefile, "scenes/player/heavy/low/taunt03_v1.vcd") && GetEntityFlags(client) & FL_ONGROUND)
	{
		if (TF2_IsPlayerInCondition(client, TFCond_Taunting)) return Plugin_Continue;
		CreateTimer(1.7, FireBall, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Continue;
}

public Action:FireBall(Handle:timer, any:client)
{
	if(!AliveCheck(client)) return Plugin_Stop;
	if(!GetAbility(client, "railgun")) return Plugin_Stop;
	if(!TF2_IsPlayerInCondition(client, TFCond_Taunting)) return Plugin_Stop;
	
	new Float:vPosition[3], Float:vAngles[3];
	vAngles[2] += 25.0;
	GetClientEyePosition(client, vPosition);
	GetClientEyeAngles(client, vAngles);

	new Handle:trace = TR_TraceRayFilterEx(vPosition, vAngles, MASK_SHOT, RayType_Infinite, TraceRayDontHitEntity, client);
	TR_GetEndPosition(laserPos[client], trace);

	EmitAmbientSound(SOUND_LASER, laserPos[client], client, _, _, _, 50);
	CreateExplosion(laserPos[client], client, 500.0, 512, 300);
	
	CreateParticle("utaunt_lightning_parent", laserPos[client]);
	
	if(GetClientTeam(client) == 2) CreateParticle("powerup_supernova_explode_red", laserPos[client]);
	else if(GetClientTeam(client) == 3) CreateParticle("powerup_supernova_explode_blue", laserPos[client]);
	
	SDKHook(client, SDKHook_PreThink, LaserThink);
	CreateTimer(0.5, Timer_End, client);
	return Plugin_Continue;
}

public LaserThink(client)
{
	decl Float:origin[3];
	GetClientEyePosition(client, origin);
	origin[2] -= 26.0;

	if(GetClientTeam(client) == 2)
		TE_SetupBeamPoints(origin, laserPos[client], g_iBeamIndex, 0, 0, 0, 1.0, 32.0, 0.1, 0, 0.0, {128, 32, 0, 255}, 0);
	else if(GetClientTeam(client) == 3)
		TE_SetupBeamPoints(origin, laserPos[client], g_iBeamIndex, 0, 0, 0, 1.0, 32.0, 0.1, 0, 0.0, {2, 100, 161, 255}, 0);
		
	TE_SendToAll(0.0);
}

public Action:Timer_End(Handle:timer, any:client) SDKUnhook(client, SDKHook_PreThink, LaserThink);

public bool TraceRayDontHitEntity(entity, mask, any:data)
{
	if (entity == data) return false;
	return true;
}
