#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <new_rpg>

#define SPEED 500.0

public OnGameFrame()
{
	new i = -1; 
	while ((i=FindEntityByClassname(i, "tf_projectile_arrow"))!=INVALID_ENT_REFERENCE)
	{
		if(!IsValidEntity(i)) return;
		new client = GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity");
		if(!PlayerCheck(client)) return;
		if(!GetAbility(client, "bow_speed")) return;
		
		decl Float:vPosition[3], Float:vAngles[3], Float:angle[3];
		GetClientEyePosition(client, vPosition);
		GetClientEyeAngles(client, vAngles);
	
		new Float:fDirection[3], Float:fVelocity[3];
		GetEntPropVector(i, Prop_Data, "m_angRotation", angle);

		if(IsPlayerAlive(client)) GetAngleVectors(vAngles, fDirection, NULL_VECTOR, NULL_VECTOR);
		else GetAngleVectors(angle, fDirection, NULL_VECTOR, NULL_VECTOR);
		
		fVelocity[0] = fDirection[0]*SPEED;
		fVelocity[1] = fDirection[1]*SPEED;
		fVelocity[2] = fDirection[2]*SPEED;
		
		if(IsPlayerAlive(client)) TeleportEntity(i, NULL_VECTOR, vAngles, fVelocity); 
		else TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, fVelocity); 
	}
}
/*
public OnEntityCreated(entity, const String:classname[])
	if(StrEqual(classname, "tf_projectile_arrow")) SDKHook(entity, SDKHook_Spawn, OnSpawn);

	
public OnSpawn(iEntity)
{
	CreateTimer(0.1, ThinkHook, EntIndexToEntRef(iEntity), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action:ThinkHook(Handle:hTimer, any:iEntityRef)
{
	new iEntity = EntRefToEntIndex(iEntityRef);
	if(!IsValidEntity(iEntity)) return Plugin_Stop;
	new client = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");
	if(!PlayerCheck(client)) return Plugin_Stop;
	if(!GetAbility(client, "bow_speed")) return Plugin_Stop;
	
	new bool:crit = ( TF2_IsPlayerInCondition(client, TFCond_Kritzkrieged) || TF2_IsPlayerInCondition(client, TFCond_CritOnWin) );
		
	new rocket = ShootRocket(iEntity, client, crit, 30.0, "", true);
	if (rocket>MaxClients) SetEntPropEnt(rocket, Prop_Send, "m_hLauncher", GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"));
	return Plugin_Continue;
}

stock ShootRocket(iProjectile, const client, bool:bCrit = false, const Float:dmg, const String:model[], bool:arc = false)
{
	if (!IsValidEdict(iProjectile)) return 0;
	
	decl Float:vPosition[3], Float:vAngles[3];
	GetClientEyePosition(client, vPosition);
	GetClientEyeAngles(client, vAngles);

	new Float:fDirection[3], Float:fVelocity[3];

	GetAngleVectors(vAngles, fDirection, NULL_VECTOR, NULL_VECTOR);
	
	fVelocity[0] = fDirection[0]*SPEED;
	fVelocity[1] = fDirection[1]*SPEED;
	fVelocity[2] = fDirection[2]*SPEED;
	
	SetEntPropEnt(iProjectile,	Prop_Send, "m_hOwnerEntity", client);
	SetEntProp(iProjectile,		Prop_Send, "m_bCritical", (bCrit ? 1 : 0));
	
	new iTeam = GetClientTeam(client);
	SetEntProp(iProjectile,		Prop_Send, "m_iTeamNum", iTeam, 1);
	SetEntProp(iProjectile,		Prop_Send, "m_nSkin", (iTeam-2));

	SetVariantInt(iTeam);
	AcceptEntityInput(iProjectile, "TeamNum", -1, -1, 0);
	SetVariantInt(iTeam);
	AcceptEntityInput(iProjectile, "SetTeam", -1, -1, 0);

	TeleportEntity(iProjectile, NULL_VECTOR, vAngles, fVelocity); 
	
	if (arc) SetEntityMoveType(iProjectile, MOVETYPE_FLYGRAVITY);
	if(!StrEqual(model, "")) SetEntityModel(iProjectile, model);
	return iProjectile;
}
*/
stock float[] Vec_NormalizeVector(const float vec[3])
{
	float output[3]; NormalizeVector(vec, output);
	return output;
}
stock float[] Vec_GetAngleVecForward(const float angle[3])
{
	float output[3]; GetAngleVectors(angle, output, NULL_VECTOR, NULL_VECTOR);
	return output;
}