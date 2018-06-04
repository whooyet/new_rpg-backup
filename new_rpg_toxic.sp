#include <sdkhooks>
#include <sdktools>
#include <tf2_stocks>
#include <new_rpg>

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
	
	HookEvent("post_inventory_application", iv, EventHookMode_Post);
	HookEvent("player_death", Event_PlayerDeath);
}

public Action Event_PlayerDeath(Handle hEvent, const char[] sName, bool bDontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(PlayerCheck(client) && GetAbility(client, "toxic")) SDKCall(g_hStopParticleEffects, client);
	return Plugin_Continue;
}

public Action:iv(Handle:event, const String:name2[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(GetAbility(client, "toxic"))
	{
		SDKCall(g_hDispatchParticleEffect, "eb_aura_angry01", 1, client, "head", 1);
	}
	else
	{
		SDKCall(g_hStopParticleEffects, client);
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if(AliveCheck(client) && GetAbility(client, "toxic"))
	{
		decl Float:pos[3], Float:ipos[3];
		GetClientAbsOrigin(client, pos);
		
		for(int i = 1; i <= MaxClients; i++)
		{
			if(AliveCheck(i) && client != i)
			{
				GetClientAbsOrigin(i, ipos);
			
				new Float:fDistance = GetVectorDistance(pos, ipos);
				if(fDistance < 128.0) SDKHooks_TakeDamage(i, client, client, 10.0, DMG_BLAST);
			}
		}
	}
}
