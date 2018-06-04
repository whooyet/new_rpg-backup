#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <new_rpg>

#define SPEED 0.0

public OnMapStart()
{
    PrecacheModel("models/weapons/w_models/w_cannonball.mdl", true);
}

public OnEntityCreated(entity, const String:classname[])
	if(StrEqual(classname, "tf_projectile_rocket")) SDKHook(entity, SDKHook_SpawnPost, soldier);

public soldier(ent)
{
	new client = GetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity");

	if(PlayerCheck(client) && GetAbility(client, "goksa"))
	{
		new bool:crit = ( TF2_IsPlayerInCondition(client, TFCond_Kritzkrieged) || TF2_IsPlayerInCondition(client, TFCond_CritOnWin) );
		
		new rocket = ShootRocket(ent, client, crit, 30.0, "", true);
		if (rocket>MaxClients) SetEntPropEnt(rocket, Prop_Send, "m_hLauncher", GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"));
	}
}

stock ShootRocket(iProjectile, const client, bool:bCrit = false, const Float:dmg, const String:model[], bool:arc = false)
{
	if (!IsValidEdict(iProjectile)) return 0;
	
	decl Float:vPosition[3], Float:vAngles[3], Float:vVec[3];
	GetClientEyePosition(client, vPosition);
	GetClientEyeAngles(client, vAngles);

	vVec[0] = Cosine( DegToRad(vAngles[1]) ) * Cosine( DegToRad(vAngles[0]) );
	vVec[1] = Sine( DegToRad(vAngles[1]) ) * Cosine( DegToRad(vAngles[0]) );
	vVec[2] = -Sine( DegToRad(vAngles[0]) );

	vPosition[0] += vVec[0] * SPEED;
	vPosition[1] += vVec[1] * SPEED;
	vPosition[2] += vVec[2] * SPEED;
		
	// float vVelocity[3];
	// vVelocity = Vec_GetAngleVecForward(vAngles);

	// if (!arc) vVelocity = Vec_NormalizeVector(vVelocity);
	// else vVelocity[2] -= 0.025;
	
	SetEntPropEnt(iProjectile,	Prop_Send, "m_hOwnerEntity", client);
	SetEntProp(iProjectile,		Prop_Send, "m_bCritical", (bCrit ? 1 : 0));
	
	new iTeam = GetClientTeam(client);
	SetEntProp(iProjectile,		Prop_Send, "m_iTeamNum", iTeam, 1);
	SetEntProp(iProjectile,		Prop_Send, "m_nSkin", (iTeam-2));

	SetVariantInt(iTeam);
	AcceptEntityInput(iProjectile, "TeamNum", -1, -1, 0);
	SetVariantInt(iTeam);
	AcceptEntityInput(iProjectile, "SetTeam", -1, -1, 0);
	SetEntDataFloat(iProjectile, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected")+4, dmg, true);

	TeleportEntity(iProjectile, vPosition, vAngles, NULL_VECTOR); 
	
	if (arc) SetEntityMoveType(iProjectile, MOVETYPE_FLYGRAVITY);
	if(!StrEqual(model, "")) SetEntityModel(iProjectile, model);
	return iProjectile;
}

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