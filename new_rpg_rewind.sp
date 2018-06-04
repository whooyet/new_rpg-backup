#include <sdktools>
#include <new_rpg>
#include <tf2_stocks>

ArrayList g_hPositions[MAXPLAYERS + 1];
ArrayList g_hAngles[MAXPLAYERS + 1];
ArrayList g_hHealthPoints[MAXPLAYERS + 1];

new bool:CheckRewind[33];
new Float:CoolTime[MAXPLAYERS+1];

public OnPluginStart() HookEvent("post_inventory_application", iv, EventHookMode_Post);

public OnMapStart() PrecacheSound("replay/rendercomplete.wav");

public OnClientPutInServer(i)
{
	CheckRewind[i] = false;
	CoolTime[i] = 0.0;
}

public iv(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(GetAbility(client, "rewind"))
	{
		SetEntPropFloat(client, Prop_Send, "m_flModelScale", 0.2);
		SetEntPropFloat(client, Prop_Send, "m_flStepSize", 18.0 * 0.2);
	}
	else
	{
		new Float:flModelScale = GetEntPropFloat(client, Prop_Send, "m_flModelScale");
		if(flModelScale != 1.0)
		{
			SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.0);
			SetEntPropFloat(client, Prop_Send, "m_flStepSize", 18.0 * 1.0);
		}
	}
}

public Action:OnPlayerRunCmd(client, &iButtons, &iImpulse, Float:fVel[3], Float:fAng[3], &iWeapon)
{
	if(AliveCheck(client) && GetAbility(client, "rewind"))
	{
		if(iButtons & IN_ATTACK2)
		{
			if(CheckCoolTime(client, 5.0) && !CheckRewind[client])
			{
				SetEntityMoveType(client, MOVETYPE_NOCLIP);
				TF2_AddCondition(client, TFCond_Bonked);
				EmitSoundToAll("replay/exitperformancemode.wav", client);
				EmitSoundToClient(client, "replay/exitperformancemode.wav");
				CheckRewind[client] = true;
				CoolTime[client] = GetEngineTime();
			}
		}
	
		if(!CheckRewind[client])
		{
			if(g_hPositions[client] == null)
			{
				g_hPositions[client] = new ArrayList(3);
				g_hAngles[client] = new ArrayList(3);
				g_hHealthPoints[client] = new ArrayList(1);
			}
			else
			{
				float flPos[3], flAng[3], flLastPos[3];
				GetClientAbsOrigin(client, flPos);
				GetClientEyeAngles(client, flAng);
					
				int iLength = g_hPositions[client].Length;
					
				if(iLength > 0) g_hPositions[client].GetArray(iLength - 1, flLastPos);
					
				if(g_hPositions[client].Length < 100)
				{
					if(GetVectorDistance(flPos, flLastPos) >= 10.0)
					{
						g_hPositions[client].PushArray(flPos);
						g_hAngles[client].PushArray(flAng);
						g_hHealthPoints[client].Push(GetEntProp(client, Prop_Send, "m_iHealth"));
					}
				}
				else
				{
					g_hPositions[client].Erase(0);
					g_hAngles[client].Erase(0);
					g_hHealthPoints[client].Erase(0);
				}
			}
		}
		else
		{
			if(g_hPositions[client] != null)
			{
				float flPos[3];
				GetClientAbsOrigin(client, flPos);
				
				for(int i = 0; i < g_hPositions[client].Length; i++)
				{
					float flLastPos[3], flAng[3];
					g_hPositions[client].GetArray(i, flLastPos);
					g_hAngles[client].GetArray(i, flAng);
						
					float flVecTo[3];
					MakeVectorFromPoints(flPos, flLastPos, flVecTo);
					NormalizeVector(flVecTo, flVecTo);
					ScaleVector(flVecTo, 600.0);
						
					TeleportEntity(client, NULL_VECTOR, flAng, flVecTo);
						
					if(GetVectorDistance(flPos, flLastPos) <= 32.0)
					{
						SetEntProp(client, Prop_Send, "m_iHealth", g_hHealthPoints[client].Get(i));
							
						g_hPositions[client].Erase(i);
						g_hAngles[client].Erase(i);
						g_hHealthPoints[client].Erase(i);
					}
				}
					
				if(g_hPositions[client].Length <= 0) EndAbilities(client);
			}
		}
	}
}

stock EndAbilities(int client)
{
	SetEntityMoveType(client, MOVETYPE_WALK);
			
	TF2_RemoveCondition(client, TFCond_Bonked);
		
	EmitSoundToAll("replay/rendercomplete.wav", client);
	EmitSoundToClient(client, "replay/rendercomplete.wav");
			
	if(g_hPositions[client] != null)
	{
		g_hPositions[client].Clear();
		g_hAngles[client].Clear();
		g_hHealthPoints[client].Clear();
				
		delete g_hPositions[client];
		delete g_hAngles[client];
		delete g_hHealthPoints[client];
	}
	
	CheckRewind[client] = false;
}

stock bool:CheckCoolTime(any:iClient, Float:fTime)
{
	if(!AliveCheck(iClient)) return false;
	if(GetEngineTime() - CoolTime[iClient] >= fTime) return true;
	else return false;
}