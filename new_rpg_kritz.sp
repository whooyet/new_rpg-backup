#include <sdkhooks>
#include <sdktools>
#include <tf2_stocks>
#include <new_rpg>

#define LASERBEAM		"sprites/laserbeam.vmt"

float	g_fTeamCritsRange	= 300.0;

int g_iCritBoostEnt[MAXPLAYERS+1][MAXPLAYERS+1];
int CheckMe[MAXPLAYERS+1];
bool:CheckBeam[MAXPLAYERS+1];
int g_iCritBoostsGetting[MAXPLAYERS+1] = {0, ...};

public OnPluginStart()
{
	for(new i = 1; i <= MaxClients; i++) if(PlayerCheck(i)) SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
	HookEvent("player_death", EventDeath, EventHookMode_Pre);
}
public OnClientPutInServer(i)
{
	CheckMe[i] = 0;
	CheckBeam[i] = false;
	g_iCritBoostsGetting[i] = 0;
	SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
}

public OnMapStart() PrecacheModel(LASERBEAM);

public EventDeath(Handle:event, const String:Spawn_Name[], bool:Spawn_Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new assister = GetClientOfUserId(GetEventInt(event, "assister"));
	
	if(PlayerCheck(client) && PlayerCheck(attacker) || PlayerCheck(assister))
	{
		if(client != attacker)
		{
			if(CheckBeam[attacker])
			{
				SetClientExp(CheckMe[attacker], 1, 0);
				
				if(GetClientTeam(attacker) == 3)
					PrintToChat(CheckMe[attacker], "\x03[Exp Up] \x0799CCFF%N\x03 님이 \x07FF4040%N\x03 님을 죽여서 \x07FFFFFF1 \x03경험치를 얻었습니다.", attacker, client);
				if(GetClientTeam(attacker) == 2)
					PrintToChat(CheckMe[attacker], "\x03[Exp Up] \x07FF4040%N\x03 님이 \x0799CCFF%N\x03 님을 죽여서 \x07FFFFFF1 \x03경험치를 얻었습니다.", attacker, client);
			}
		}
	}
}

public Action:OnTakeDamage(attacker, &client, &inflictor, &Float:fDamage, &iDamagetype, &iWeapon, Float:fForce[3], Float:fForcePos[3], damagecustom)
{
	if(AliveCheck(attacker) && AliveCheck(client))
		 if(client != attacker) if(CheckBeam[client]) SDKHooks_TakeDamage(attacker, CheckMe[client], CheckMe[client], 1.0);
	return Plugin_Continue;
}

public Action:OnPlayerRunCmd(client, &iButtons, &iImpulse, Float:fVel[3], Float:fAng[3], &iWeapon)
	if(PlayerCheck(client)) TeamCriticals_DrawBeamsFor(client);

void TeamCriticals_DrawBeamsFor(int client){

	int iTeam = GetClientTeam(client);
	for(int i = 1; i <= MaxClients; i++){
	
		if(i == client)
			continue;
			
		if(!GetAbility(client, "kritz")){
		
			if(g_iCritBoostEnt[client][i] > MaxClients)
				TeamCriticals_SetCritBoost(client, i, false, iTeam);
			
			continue;
		}
			
		if(!IsPlayerAlive(client)){
		
			if(g_iCritBoostEnt[client][i] > MaxClients)
				TeamCriticals_SetCritBoost(client, i, false, iTeam);
			
			continue;
		}
		
		if(!IsClientInGame(i)){
		
			if(g_iCritBoostEnt[client][i] > MaxClients)
				TeamCriticals_SetCritBoost(client, i, false, iTeam);
			
			continue;
		
		}
		
		if(!TeamCriticals_IsValidTarget(client, i, iTeam)){
		
			if(g_iCritBoostEnt[client][i] > MaxClients)
				TeamCriticals_SetCritBoost(client, i, false, iTeam);
		
			continue;
		
		}
		
		if(!CanEntitySeeTarget(client, i)){
		
			if(g_iCritBoostEnt[client][i] > MaxClients)
				TeamCriticals_SetCritBoost(client, i, false, iTeam);
			
			continue;
		}
		
		if(g_iCritBoostEnt[client][i] <= MaxClients)
			TeamCriticals_SetCritBoost(client, i, true, iTeam);
	
	}

}

bool TeamCriticals_IsValidTarget(int client, int iTrg, int iClientTeam){
	
	float fPos[3], fEndPos[3];
	GetClientAbsOrigin(client, fPos);
	GetClientAbsOrigin(iTrg, fEndPos);
	
	if(GetVectorDistance(fPos, fEndPos) > g_fTeamCritsRange)
		return false;
	
	if(TF2_IsPlayerInCondition(iTrg, TFCond_Cloaked))
		return false;
	
	int iEndTeam = GetClientTeam(iTrg);
	
	if(TF2_IsPlayerInCondition(iTrg, TFCond_Disguised)){
	
		if(iClientTeam == iEndTeam)
			return false;
		
		else
			return true;
	
	}
	
	return (iClientTeam == iEndTeam);

}

void TeamCriticals_SetCritBoost(int client, int iTrg, bool bSet, int iTeam){

	g_iCritBoostsGetting[iTrg] += bSet ? 1 : -1;

	if(bSet){
		g_iCritBoostEnt[client][iTrg] = ConnectWithBeam(client, iTrg, iTeam == 2 ? 255 : 64, 64, iTeam == 2 ? 64 : 255);
		
		if(g_iCritBoostsGetting[iTrg] < 2)
		{
			TF2_AddCondition(iTrg, TFCond_CritOnFirstBlood);
			CheckBeam[iTrg] = true;
			CheckMe[iTrg] = client;
		}
	}else{
	
		if(IsValidEntity(g_iCritBoostEnt[client][iTrg]))
			AcceptEntityInput(g_iCritBoostEnt[client][iTrg], "Kill");
		
		g_iCritBoostEnt[client][iTrg] = 0;
		CheckMe[iTrg] = 0;
		CheckBeam[iTrg] = false;
		
		if(g_iCritBoostsGetting[iTrg] < 1) TF2_RemoveCondition(iTrg, TFCond_CritOnFirstBlood);
	
	}

}

stock bool CanEntitySeeTarget	(int entity, int iTarget){

	float fStart[3], fEnd[3];

	if(PlayerCheck(entity))
		GetClientEyePosition(entity, fStart);
	else
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", fStart);

	if(PlayerCheck(iTarget))
		GetClientEyePosition(iTarget, fEnd);
	else
		GetEntPropVector(iTarget, Prop_Send, "m_vecOrigin", fEnd);

	Handle hTrace = TR_TraceRayFilterEx(fStart, fEnd, MASK_SOLID, RayType_EndPoint, TraceFilterIgnorePlayersAndSelf, entity);
	if(hTrace != INVALID_HANDLE){

		if(TR_DidHit(hTrace)){

			delete hTrace;
			return false;

		}
	
	}

	delete hTrace;
	return true;

}


public bool TraceFilterIgnorePlayersAndSelf	(int iEntity, int iContentsMask, any iTarget){

	if(iEntity >= 1 && iEntity <= MaxClients)
		return false;

	if(iEntity == iTarget)
		return false;

	return true;

}

stock int ConnectWithBeam		(int iEnt, int iEnt2, int iRed=255, int iGreen=255, int iBlue=255, float fStartWidth=1.0, float fEndWidth=1.0, float fAmp=1.35){

	int iBeam = CreateEntityByName("env_beam");
	
	if(iBeam <= MaxClients) return -1;
	
	if(!IsValidEntity(iBeam)) return -1;
	
	SetEntityModel(iBeam, LASERBEAM);
	
	char sColor[16];
	Format(sColor, sizeof(sColor), "%d %d %d", iRed, iGreen, iBlue);
	
	DispatchKeyValue(iBeam, "rendercolor", sColor);
	DispatchKeyValue(iBeam, "life", "0");
	
	DispatchSpawn(iBeam);
	
	SetEntPropEnt(iBeam, Prop_Send, "m_hAttachEntity", EntIndexToEntRef(iEnt));
	SetEntPropEnt(iBeam, Prop_Send, "m_hAttachEntity", EntIndexToEntRef(iEnt2), 1);
	
	SetEntProp(iBeam, Prop_Send, "m_nNumBeamEnts", 2);
	SetEntProp(iBeam, Prop_Send, "m_nBeamType", 2);
	
	SetEntPropFloat(iBeam, Prop_Data, "m_fWidth", 1.0);
	SetEntPropFloat(iBeam, Prop_Data, "m_fEndWidth", 1.0);
	
	SetEntPropFloat(iBeam, Prop_Data, "m_fAmplitude", 1.35);
	
	SetVariantFloat(32.0);
	AcceptEntityInput(iBeam, "Amplitude");
	AcceptEntityInput(iBeam, "TurnOn");
	
	return iBeam;

}