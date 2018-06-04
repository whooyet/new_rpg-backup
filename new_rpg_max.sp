#include <sdkhooks>
#include <sdktools>
#include <tf2_stocks>
#include <new_rpg>

new Handle:kv[100] = {INVALID_HANDLE, ...};
new MaxItem_Look;

public OnPluginStart()
{
	RPG_Config();
	RegAdminCmd("sm_max", aaaa, 0);
}

public OnMapEnd() for(new i = 0 ; i < 100 && i < MaxItem_Look; i++) if(kv[i] != INVALID_HANDLE) CloseHandle(kv[i]);

public Action:aaaa(client, args)
{
	if(GetClientLevel(client) == 32 || GetClientLevel(client) >= 900)
	{
		new Handle:info = CreateMenu(Menu_Information);
		SetMenuTitle(info, "무기를 고르세요~~~~");
		
		decl String:name[256], String:lv[5];
		
		for(new i = 0 ; i < MaxItem_Look ; i++)
		{
			if(kv[i] != INVALID_HANDLE) 
			{
				GetArrayString(kv[i], 0, lv, sizeof(lv));
				GetArrayString(kv[i], 1, name, sizeof(name));
			}

			if(StringToInt(lv) < 899 || StringToInt(lv) > 998) AddMenuItem(info, lv, name); 
		}
		
		SetMenuExitButton(info, true);
		DisplayMenu(info, client, MENU_TIME_FOREVER);
	}
	else
	{
		PrintToChat(client, "\x03당신은 만렙이 아닙니다.");
		return Plugin_Handled;
	}
	
	return Plugin_Handled;
}
public Menu_Information(Handle:menu, MenuAction:action, client, select)
{
	if(action == MenuAction_Select)
	{ 
		decl String:info[5];
		GetMenuItem(menu, select, info, sizeof(info));
		SetClientLevel(client, StringToInt(info));
	}
	else if(action == MenuAction_End) CloseHandle(menu);
}

stock bool:RPG_Config()
{
	decl String:strPath[192], String:szBuffer[100];
	new count = 0;
	
	BuildPath(Path_SM, strPath, sizeof(strPath), "configs/new_rpg.cfg");
	
	new Handle:DB = CreateKeyValues("rpg");
	FileToKeyValues(DB, strPath);

	if(KvGotoFirstSubKey(DB))
	{
		do
		{
			kv[count] = CreateArray(256);
			
			KvGetSectionName(DB, szBuffer, sizeof(szBuffer));
			PushArrayString(kv[count], szBuffer);	
			
			KvGetString(DB, "name", szBuffer, sizeof(szBuffer));
			PushArrayString(kv[count], szBuffer);
			
			KvGetString(DB, "class", szBuffer, sizeof(szBuffer));
			PushArrayString(kv[count], szBuffer);
			
			PushArrayCell(kv[count], KvGetNum(DB, "slot"))
			
			KvGetString(DB, "classname", szBuffer, sizeof(szBuffer));
			PushArrayString(kv[count], szBuffer);
			
			KvGetString(DB, "attribute", szBuffer, sizeof(szBuffer));
			PushArrayString(kv[count], szBuffer);

			PushArrayCell(kv[count], KvGetNum(DB, "index"))
			PushArrayCell(kv[count], KvGetNum(DB, "exp"))	

			KvGetString(DB, "ability", szBuffer, sizeof(szBuffer));
			PushArrayString(kv[count], szBuffer);
			
			KvGetString(DB, "description", szBuffer, sizeof(szBuffer));
			PushArrayString(kv[count], szBuffer);

			KvGetString(DB, "description2", szBuffer, sizeof(szBuffer));
			PushArrayString(kv[count], szBuffer);

			KvGetString(DB, "description3", szBuffer, sizeof(szBuffer));
			PushArrayString(kv[count], szBuffer);

			PushArrayCell(kv[count], KvGetNum(DB, "look"));

			KvGetString(DB, "look_att", szBuffer, sizeof(szBuffer));
			PushArrayString(kv[count], szBuffer);

			count++;
		}
		while(KvGotoNextKey(DB));
	}
	CloseHandle(DB);
	MaxItem_Look = count;
}
