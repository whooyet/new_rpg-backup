#include <sdkhooks>
#include <sdktools>
#include <tf2_stocks>
#include <new_rpg>

#define SOUND_EARTHQUAKE	"ambient/atmosphere/terrain_rumble1.wav"
#define SOUND_JUMP1			"vo/demoman_paincrticialdeath01.mp3"
#define SOUND_JUMP2			"vo/demoman_paincrticialdeath02.mp3"
#define SOUND_JUMP3			"vo/demoman_paincrticialdeath06.mp3"
#define SOUND_JUMP4			"vo/demoman_paincrticialdeath05.mp3"
#define TRAIL "materials/trails/rainbow.vmt"

#define GIB_COUNT	6
#define SOUND_GORE	"physics/flesh/flesh_bloody_break.wav"

char g_sGibName[9][] = {

	"scout", "soldier", "pyro",
	"demo", "heavy", "engineer",
	"medic", "sniper", "spy",

};

new XBeamSprite;
new g_HaloSprite;

Handle g_hDispatchParticleEffect;
Handle g_hStopParticleEffects;


public OnPluginStart()
{
	StartPrepSDKCall(SDKCall_Static);
	PrepSDKCall_SetSignature(SDKLibrary_Server, "\x55\x8B\xEC\x56\x8B\x75\x10\x57\x83\xCF\xFF", 11);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);		//pszParticleName
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);	//iAttachType
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);	//pEntity
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);		//pszAttachmentName
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);			//bResetAllParticlesOnEntity 
	if ((g_hDispatchParticleEffect = EndPrepSDKCall()) == INVALID_HANDLE) SetFailState("Failed to create SDKCall for DispatchParticleEffect signature!");
	
	StartPrepSDKCall(SDKCall_Static);
	PrepSDKCall_SetSignature(SDKLibrary_Server, "\x55\x8B\xEC\x81\xEC\xAC\x00\x00\x00\x8D\x8D\x54\xFF\xFF\xFF", 15);
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);	//pEntity
	if ((g_hStopParticleEffects = EndPrepSDKCall()) == INVALID_HANDLE) SetFailState("Failed to create SDKCall for StopParticleEffects signature!");
	

	for(new i = 1; i <= MaxClients; i++) if(PlayerCheck(i)) SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
	HookEvent("post_inventory_application", iv, EventHookMode_Post);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("item_pickup", item_pickup);
}

public OnClientPutInServer(i)
{
	SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
}

public OnMapStart()
{
	XBeamSprite = PrecacheModel("materials/sprites/laser.vmt")
	g_HaloSprite = PrecacheModel("materials/sprites/halo01.vmt")
	
	PrecacheSound(SOUND_GORE, true);
	PrecacheSound(SOUND_EARTHQUAKE, true);
	
	PrecacheSound(SOUND_JUMP1, true);
	PrecacheSound(SOUND_JUMP2, true);
	PrecacheSound(SOUND_JUMP3, true);
	PrecacheSound(SOUND_JUMP4, true);
	
	PrecacheModel(TRAIL, true);
	AddFileToDownloadsTable(TRAIL);
}

public Action:OnTakeDamage(attacker, &client, &inflictor, &Float:fDamage, &iDamagetype, &iWeapon, Float:fForce[3], Float:fForcePos[3], damagecustom)
{
	if(iDamagetype & DMG_FALL)
	{
		if(AliveCheck(attacker) && GetAbility(attacker, "wildmon"))
		{
			decl Float:pos[3];
			GetClientAbsOrigin(attacker, pos);
			
			EmitSoundToAll(SOUND_JUMP1, client, SNDCHAN_VOICE);
			Rainbow(attacker);
			
			for(new i = 1; i <= MaxClients; i++)
			{
				if(AliveCheck(i) && GetClientTeam(attacker) != GetClientTeam(i))
				{
					new Float:vEPosit[3], Float:Dist;
					GetClientAbsOrigin(i, vEPosit);
					Dist = GetVectorDistance(pos, vEPosit);
					
					if(Dist <= 300.0)
					{
						SDKHooks_TakeDamage(i, attacker, attacker, 15.0);
						TF2_StunPlayer(i, 1.0, _, TF_STUNFLAGS_LOSERSTATE, 0);
						EmitSoundToAll(SOUND_EARTHQUAKE, i);
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

public item_pickup(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(GetAbility(client, "wildmon"))
	{
		decl String:item[64];
		GetEventString(event, "item", item, sizeof(item));
		
		if(StrContains(item, "medkit", false) != -1)
		{
			PrintToChat(client, "\x07ff0000와일드몬\x07FFFFFF의 \x03긍지\x07FFFFFF를 갖고 있으면서 \x03힐 킷\x07FFFFFF은 \x07ff0000비열해\x03")
			ForcePlayerSuicide(client);
		}
	}
}

public Action Event_PlayerDeath(Handle hEvent, const char[] sName, bool bDontBroadcast)
{

	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(client == 0) return Plugin_Continue;

	int attacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	if(attacker == 0) return Plugin_Continue;
	
	if(client != attacker) if(GetAbility(attacker, "wildmon")) RipAndTear(client, attacker);
	else if(GetAbility(client, "wildmon")) SDKCall(g_hStopParticleEffects, client);
	return Plugin_Continue;
}
 
public Action:iv(Handle:event, const String:name2[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(GetAbility(client, "wildmon"))
	{
		SDKCall(g_hDispatchParticleEffect, "ghost_pumpkin", 1, client, "head", 1);
		CreateTimer(0.2, Timer_SuperJump, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		SDKCall(g_hStopParticleEffects, client);
	}
}

public Action:Timer_SuperJump(Handle:hTimer, any:client)
{
	if(!AliveCheck(client)) return Plugin_Stop;
	if(!GetAbility(client, "wildmon")) return Plugin_Stop;

	static iJumpCharge[MAXPLAYERS + 1];
	new iButtons = GetClientButtons(client);
	
	if((iButtons & IN_DUCK || iButtons & IN_ATTACK2) && iJumpCharge[client] >= 0)
	{
		if(iJumpCharge[client] + 5 < 25) iJumpCharge[client] += 5;
		else iJumpCharge[client] = 25;
		PrintCenterText(client, "%d%", iJumpCharge[client] * 4);
	}
	else if(iJumpCharge[client] < 0)
	{
		iJumpCharge[client] += 3;
		PrintCenterText(client, "%d초 후에 슈퍼 점프가 준비됩니다.", -iJumpCharge[client] / 10);
	}
	else
	{
		if(iJumpCharge[client] > 1)
		{
			decl Float:fVelocity[3];
			GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVelocity);

			SetEntProp(client, Prop_Send, "m_bJumping", 1);

			fVelocity[2] = 1000 + iJumpCharge[client] * 13.0;
			fVelocity[0] *= (1 + Sine(float(iJumpCharge[client]) * FLOAT_PI / 50));
			fVelocity[1] *= (1 + Sine(float(iJumpCharge[client]) * FLOAT_PI / 50));
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fVelocity);

			iJumpCharge[client] = -120;

			decl Float:fPosition[3];
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", fPosition);

			new iRandom = GetRandomInt(0, 3);
			switch(iRandom)
			{
				case 0: EmitSoundToAll(SOUND_JUMP1, client, SNDCHAN_VOICE);
				case 1: EmitSoundToAll(SOUND_JUMP2, client, SNDCHAN_VOICE);
				case 2: EmitSoundToAll(SOUND_JUMP3, client, SNDCHAN_VOICE);
				case 3: EmitSoundToAll(SOUND_JUMP4, client, SNDCHAN_VOICE);
			}
		}
		else
		{
			iJumpCharge[client] = 0;
			PrintCenterText(client, "");
		}
	}
	return Plugin_Continue;
}

stock Rainbow(client)
{
	decl Float:Clientposition[3];
	GetClientAbsOrigin(client, Clientposition);
				
	new String:positionstring[128], String:colorstring[128];
			
	Format(positionstring, 128, "%f %f %f", Clientposition[0], Clientposition[1], Clientposition[2]);
	Format(colorstring, 128, "%d %d %d %d", 255, 255, 255, 255);
	
	new temp = CreateEntityByName("env_spritetrail");
	DispatchKeyValue(temp, "Origin", positionstring);
	DispatchKeyValue(temp, "lifetime", "3.5");
	DispatchKeyValue(temp, "startwidth", "16.0");
	DispatchKeyValue(temp, "endwidth", "8.0");
	DispatchKeyValue(temp, "spritename", TRAIL);
	DispatchKeyValue(temp, "renderamt", "255");
	DispatchKeyValue(temp, "rendercolor", colorstring);
	DispatchKeyValue(temp, "rendermode", "5");
	DispatchSpawn(temp);
	
	SetEntPropFloat(temp, Prop_Send, "m_flTextureRes", 0.05);
	SetEntPropFloat(temp, Prop_Data, "m_flSkyboxScale", 1.0);
	
	TE_SetupBeamRingPoint(Clientposition, 20.0, 300.0, XBeamSprite, g_HaloSprite, 0, 1, 0.5, 30.0, 0.0, {255,0,0,255}, 10, 0);
	TE_SendToAll(0.0);
	TE_SetupBeamRingPoint(Clientposition, 20.0, 300.0, XBeamSprite, g_HaloSprite, 0, 1, 0.5, 30.0, 0.0, {255, 127, 0,255}, 10, 0);
	TE_SendToAll(0.05);
	TE_SetupBeamRingPoint(Clientposition, 20.0, 300.0, XBeamSprite, g_HaloSprite, 0, 1, 0.5, 30.0, 0.0, {255, 255, 0,255}, 10, 0);
	TE_SendToAll(0.09);
	TE_SetupBeamRingPoint(Clientposition, 20.0, 300.0, XBeamSprite, g_HaloSprite, 0, 1, 0.5, 30.0, 0.0, {0, 255, 0,255}, 10, 0);
	TE_SendToAll(0.11);
	TE_SetupBeamRingPoint(Clientposition, 20.0, 300.0, XBeamSprite, g_HaloSprite, 0, 1, 0.5, 30.0, 0.0, {0, 127, 255,255}, 10, 0);
	TE_SendToAll(0.13);
	TE_SetupBeamRingPoint(Clientposition, 20.0, 300.0, XBeamSprite, g_HaloSprite, 0, 1, 0.5, 30.0, 0.0, {0,0,255,255}, 10, 0);
	TE_SendToAll(0.15);
	TE_SetupBeamRingPoint(Clientposition, 20.0, 300.0, XBeamSprite, g_HaloSprite, 0, 1, 0.5, 30.0, 0.0, {143, 0, 255,255}, 10, 0);
	TE_SendToAll(0.17);
}

void RipAndTear(int client, int atk){

	RequestFrame(RipAndTear_NextFrame, GetClientSerial(client));

	for(int i = 0; i < 5; i++)
		EmitSoundToAll(SOUND_GORE, client);

	int iRagdoll = CreateEntityByName("tf_ragdoll");
	if(iRagdoll <= MaxClients || !IsValidEntity(iRagdoll))
		return;

	float fPos[3], fPos2[3], fAng[3], fVel[3];
	GetClientAbsOrigin(client, fPos);
	GetClientAbsOrigin(atk, fPos2);
	GetClientAbsAngles(client, fAng);
	TFClassType Class = TF2_GetPlayerClass(client);

	MakeVectorFromPoints(fPos2, fPos, fVel);
	NormalizeVector(fVel, fVel);
	ScaleVector(fVel, 256.0);

	for(int i = 1; i <= GIB_COUNT; i++) SpawnGib(fPos, fAng, fVel, Class, i);

	for(int i = 1; i <= 4; i++) SpawnGib(fPos, fAng, fVel, Class, i);

	for(int i = 0; i < 2; i++) CreateParticle2(fPos, "tfc_sniper_mist", 16.0);
	
	SDKCall(g_hStopParticleEffects, client);
}

public void RipAndTear_NextFrame		(int iSerial){

	int client = GetClientFromSerial(iSerial);
	if(client == 0)
		return;

	int iRagdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if(iRagdoll > MaxClients && IsValidEntity(iRagdoll))
		AcceptEntityInput(iRagdoll, "Kill");

}

void SpawnGib (float fPos[3], float fAng[3], float fVel[3], TFClassType Class, int iGibCount){

	int iGib = CreateEntityByName("prop_physics");

	char sGibPath[PLATFORM_MAX_PATH];
	Format(sGibPath, PLATFORM_MAX_PATH, "models/player/gibs/%sgib00%d.mdl", g_sGibName[ClassToIndex(Class)], iGibCount);

	if(!IsModelPrecached(sGibPath))
		PrecacheModel(sGibPath);

	SetEntityModel(iGib, sGibPath);

	DispatchKeyValue(iGib, "modelscale", "1.2");
	SetEntProp(iGib, Prop_Send, "m_CollisionGroup", 1);
	SetEntProp(iGib, Prop_Data, "m_CollisionGroup", 1);

	DispatchSpawn(iGib);
	TeleportEntity(iGib, fPos, fAng, fVel);

	SetVariantString("OnUser1 !self:kill::5.0:1");
	AcceptEntityInput(iGib, "AddOutput");
	AcceptEntityInput(iGib, "FireUser1");
}

int ClassToIndex						(TFClassType Class){

	switch(Class){
	
		case TFClass_Scout:
			return 0;
	
		case TFClass_Soldier:
			return 1;
	
		case TFClass_Pyro:
			return 2;
	
		case TFClass_DemoMan:
			return 3;
	
		case TFClass_Heavy:
			return 4;
	
		case TFClass_Engineer:
			return 5;
	
		case TFClass_Medic:
			return 6;
	
		case TFClass_Sniper:
			return 7;
	
		case TFClass_Spy:
			return 8;
	
	}

	return 0;

}

stock void CreateParticle2(float fPos[3], const char[] strParticle, float fZOffset){

	int iParticle = CreateEntityByName("info_particle_system");
	if(!IsValidEdict(iParticle))
		return;

	fPos[2] += fZOffset;
	TeleportEntity(iParticle, fPos, NULL_VECTOR, NULL_VECTOR);
	DispatchKeyValue(iParticle, "effect_name", strParticle);

	DispatchSpawn(iParticle);
	ActivateEntity(iParticle);
	AcceptEntityInput(iParticle, "Start");

	SetVariantString("OnUser1 !self:kill::4.0:1");
	AcceptEntityInput(iParticle, "AddOutput");
	AcceptEntityInput(iParticle, "FireUser1");

}