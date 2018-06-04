#include <tf2attributes>
#include <tf2_stocks>
#include <new_rpg>

new Float:BleedTime[MAXPLAYERS+1];
new Float:SmokeTime[MAXPLAYERS+1];
new Float:GetSpeed[MAXPLAYERS+1];
new bool:CheckSmoke[MAXPLAYERS+1];

public OnPluginStart()
{
	AddCommandListener(hook_VoiceMenu2, "voicemenu");
	HookEvent("post_inventory_application", iv, EventHookMode_Post);
}

public OnMapStart()
{
	PrecacheSound("player/taunt_shake_it.wav");
	PrecacheModel("models/player/gibs/gibs_duck.mdl");
	PrecacheParticleSystem("dooms_nuke_collumn");
}

public iv(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	CreateTimer(2.0, Timer_GetSpeed, client);
}

public Action:hook_VoiceMenu2(client, const String:command[], argc)
{
	decl String:cmd1[32], String:cmd2[32];
		
	if(argc < 2) return Plugin_Handled;
		
	GetCmdArg(1, cmd1, sizeof(cmd1));
	GetCmdArg(2, cmd2, sizeof(cmd2));

	if(StrEqual(cmd1, "0") && StrEqual(cmd2, "0") && IsPlayerAlive(client) && GetAbility(client, "smoke")) 
	{
		if(CheckSmokeCoolTime(client, 40.0))
		{
			EmitSoundToAll("player/taunt_shake_it.wav", client);
			
			new duck = CreateEntityByName("prop_physics_override");
			if (IsValidEntity(duck))
			{
				SetEntPropEnt(duck, Prop_Send, "m_hOwnerEntity", client);
				SetEntityModel(duck, "models/player/gibs/gibs_duck.mdl");
				SetEntityMoveType(duck, MOVETYPE_VPHYSICS);
				SetEntProp(duck, Prop_Send, "m_CollisionGroup", 1);
				SetEntProp(duck, Prop_Send, "m_usSolidFlags", 16);
				DispatchSpawn(duck);

				new rint = GetRandomInt(0,100);
				decl Float:pos[3];
				decl Float:vecAngles[3], Float:vecVelocity[3];
				GetClientEyeAngles(client, vecAngles);
				GetEntPropVector(client, Prop_Data, "m_vecVelocity", vecVelocity);
				GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
				pos[2] += 30;
				vecAngles[0] = DegToRad(vecAngles[0]);
				vecAngles[1] = DegToRad(vecAngles[1]);
				vecVelocity[0] = 650 * Cosine(vecAngles[0]) * Cosine(vecAngles[1]) + rint;
				vecVelocity[1] = 650 * Cosine(vecAngles[0]) * Sine(vecAngles[1]) + rint;
				vecVelocity[2] = 500.0 + rint;
				TeleportEntity(duck, pos, NULL_VECTOR, vecVelocity);
				
				CreateTimer(5.0, Smoke_Effect, duck);
				CreateTimer(17.0, Smoke_Disable, duck);
				SmokeTime[client] = GetEngineTime();
			}
			return Plugin_Handled; 
		}
		else PrintToChat(client, "\x0320 초를 기다려야합니다. (%.1f 초)", GetEngineTime() - SmokeTime[client]);
	}
	return Plugin_Continue;
}


public Action:Smoke_Effect(Handle:timer, any:ent)
{
	if (IsValidEntity(ent))
	{
		decl Float:pos[3];
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
		effect(pos, 17.0, "dooms_nuke_collumn");
		DispatchKeyValue(ent, "targetname", "smoke");
	}
}


public void OnGameFrame()
{
	decl Float:OtherPos[3], String:szName[128], Float:ParticlePos[3];
			
	int iEnt = MaxClients + 1;
	while((iEnt = FindEntityByClassname(iEnt, "prop_physics")) != -1)
	{
		if(IsValidEntity(iEnt))
		{
			new owner = GetEntPropEnt(iEnt, Prop_Send, "m_hOwnerEntity");
			if(PlayerCheck(owner))
			{
				GetEntPropString(iEnt, Prop_Data, "m_iName", szName, sizeof(szName));
				GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", ParticlePos);
				
				if(StrEqual(szName, "smoke"))
				{
					for(new i = 1; i <= MaxClients; i++)
					{ 
						if(AliveCheck(i))
						{
							GetClientAbsOrigin(i, OtherPos);
							new Float:distance = GetVectorDistance(OtherPos, ParticlePos);
						
							if(distance < 1200.0)
							{
								CheckSmoke[i] = true;
								TF2Attrib_SetByDefIndex(i, 819, 1.0);
								
								if(CheckBleedCoolTime(i, 1.0))
								{
									if(GetClientTeam(owner) != GetClientTeam(i))
									{	
										TF2_MakeBleed(i, owner, 1.0);
										BleedTime[i] = GetEngineTime();
									}
								}
								SetEntPropFloat(i, Prop_Send, "m_flMaxspeed", 200.0);
								
								new Handle:hBuffer = StartMessageOne("KeyHintText", i); 
								new String:tmptext[2048];
								Format(tmptext, sizeof(tmptext), "===== 연막탄 =====\n\n2단 점프가 불가능합니다.\n숨 쉬기 힘듭니다.\n이동 속도가 저하됩니다.");
								BfWriteByte(hBuffer, 1); 
								BfWriteString(hBuffer, tmptext); 
								EndMessage();
							}
							else
							{
								CheckSmoke[i] = false;
								SetEntPropFloat(i, Prop_Send, "m_flMaxspeed", GetSpeed[i]);
								TF2Attrib_RemoveByDefIndex(i, 819);
							}
						}
					}
				}
			}
		}
	}
}

public Action:Smoke_Disable(Handle:timer, any:ent)
{
	if(IsValidEntity(ent)) AcceptEntityInput(ent, "Kill");
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(AliveCheck(i))
		{
			if(CheckSmoke[i])
			{	
				SetEntPropFloat(i, Prop_Send, "m_flMaxspeed", GetSpeed[i]);
				TF2Attrib_RemoveByDefIndex(i, 819);
				CheckSmoke[i] = false;
			}
		}
	}
}

public Action:Timer_GetSpeed(Handle:timer, any:ent) GetSpeed[ent] = GetEntPropFloat(ent, Prop_Data, "m_flMaxspeed");

stock bool:CheckBleedCoolTime(any:iClient, Float:fTime)
{
	if(!AliveCheck(iClient)) return false;
	if(GetEngineTime() - BleedTime[iClient] >= fTime) return true;
	else return false;
}

stock bool:CheckSmokeCoolTime(any:iClient, Float:fTime)
{
	if(!AliveCheck(iClient)) return false;
	if(GetEngineTime() - SmokeTime[iClient] >= fTime) return true;
	else return false;
} 

stock effect(Float:pos[3], Float:time, String:effect[])
{
	new ent = CreateEntityByName("info_particle_system");
	if (ent != -1)
	{
		DispatchKeyValueVector(ent, "origin", pos);
		DispatchKeyValue(ent, "effect_name", effect);
		DispatchSpawn(ent);
					
		ActivateEntity(ent);
		AcceptEntityInput(ent, "Start");

		CreateTimer(time, DeleteParticle, ent, TIMER_FLAG_NO_MAPCHANGE);
	}
	return ent;
}

public Action:DeleteParticle(Handle:timer, any:pc)
{
    if (IsValidEntity(pc))
    {
        new String:classN[64];
        GetEdictClassname(pc, classN, sizeof(classN));
        if (StrEqual(classN, "info_particle_system", false))
        {
			AcceptEntityInput(pc, "Stop");
			RemoveEdict(pc);
        }
    }
}
