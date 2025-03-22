//------------------------------------------------------
//     Author: 4512369781
//     Steam: https://steamcommunity.com/profiles/76561198052420500/myworkshopfiles/?appid=550
//------------------------------------------------------


if (!("L4D2Lxc_NCS" in getroottable()))
{
	::L4D2Lxc_NCS <-
	{
		FirstLoad = true
		Initialized = false
		AllowTakeDamageFuncs = []
		
		
		function OnGameEvent_player_spawn(params)
		{
			local player = GetPlayerFromUserID(params["userid"]);
			if (player.IsSurvivor() && !IsPlayerABot(player))
			{
				player.ValidateScriptScope();
				local scope = player.GetScriptScope();
				scope.LastPunchAngle <- Vector();
			}
		}
		
		//after this event, camera will shake, so we save the last "m_vecPunchAngle" value
		function OnGameEvent_bullet_impact(params)
		{
			local attacker = GetPlayerFromUserID(params["userid"]);
				local victim = Entities.FindByClassnameNearest("player", Vector(params.x, params.y, params.z), 0.0);
				if (!victim || !victim.IsSurvivor() || IsPlayerABot(victim))
					return;
				local scope = victim.GetScriptScope();
				scope.LastPunchAngle = NetProps.GetPropVector(victim, "localdata.m_Local.m_vecPunchAngle");
		}
		
		function NoCameraShakeWhenBotsShootYou(damageTable)
		{
			//DMG_BULLET
			if ((damageTable.DamageType & 2) == 2)
			{
				local victim = damageTable.Victim;
				if (victim && victim.IsPlayer() && victim.IsSurvivor() && !IsPlayerABot(victim) && damageTable.Attacker == damageTable.Inflictor)
				{
					local NoShake = victim.GetScriptScope().LastPunchAngle;
					NetProps.SetPropVector(victim, "localdata.m_Local.m_vecPunchAngle", NoShake);
					//NetProps.SetPropVector(victim, "localdata.m_Local.m_vecPunchAngleVel", NoShake); //not sure for this, always get "Vector(0, 0, 0)".
				}
			}
			return true;
		}
		
		function AllowTakeDamageEX(damageTable)
		{
			local Damage = true;
			foreach (func in ::L4D2Lxc_NCS.AllowTakeDamageFuncs)
			{
				if (func(damageTable) == false)
					Damage = false;
			}
			return Damage;
		}
		
		//how the "PunchAngle" decay //https://www.unknowncheats.me/wiki/%22No_Recoil%22_Reversed_and_Explained
		//but now i found a better way.
		/*function DecayPunchAngle(vPunchAngle, v = Vector(), tick = 1.0/30.0)
		{
			local decay_rate = Convars.GetFloat("punch_angle_decay_rate");
			//printl("orig - "+vPunchAngle);
			v.x = vPunchAngle.x; v.y = vPunchAngle.y; v.z = vPunchAngle.z;
			//local v = Vector(vPunchAngle.x, vPunchAngle.y, vPunchAngle.z);
			local len = v.Norm();
			len -= (decay_rate + len * 0.5) * tick;
			if (len < 0.0)
				len = 0.0;
			//printl(len);
			//printl("decay - " + v * len);
			return v * len;
		}*/
		
		function Initialize()
		{
			if (FirstLoad)
			{
				//"director_base_addon.nut" will load twice, skip the first time
				FirstLoad = false;
				Initialized = false;
				return;
			}
			FirstLoad = true; //if round restarts, this will fix something
			SetAllowTakeDamageHook();
		}
		
		function SetAllowTakeDamageHook()
		{
			if (Initialized)
				return;
			
			printl("[no camera shake when bots shoot you] Loading...");
			
			if (AllowTakeDamageFuncs.find(NoCameraShakeWhenBotsShootYou) == null)
				AllowTakeDamageFuncs.insert(0, NoCameraShakeWhenBotsShootYou);
			
			local RootTable = getroottable();
			if ("HooksHub" in RootTable) //Left 4 Lib, used for Left 4 Bots, Left 4 Bots 2
			{
				HooksHub.SetAllowTakeDamage("LXC_NCS", AllowTakeDamageEX);
			}
			else if ("VSLib" in RootTable) //it should be fine
			{
				local mode = "AllowTakeDamage" in g_ModeScript ? delete g_ModeScript.AllowTakeDamage : AllowTakeDamageEX;
				local root = "AllowTakeDamage" in RootTable ? delete RootTable.AllowTakeDamage : mode;
				if (mode != AllowTakeDamageEX && AllowTakeDamageFuncs.find(mode) == null)
					AllowTakeDamageFuncs.append(mode);
				if (root != mode)
					AllowTakeDamageFuncs.append(root);
				
				g_ModeScript.AllowTakeDamage <- AllowTakeDamageEX;
				RootTable.AllowTakeDamage <- AllowTakeDamageEX;
			}
			else
			{
				//'AllowTakeDamage' hook can add to 'g_ModeScript, g_MapScript, getroottable()' scope, but only one will exec and follow 'g_ModeScript > g_MapScript > getroottable()' priority, so not add the low priority hook
				if ("AllowTakeDamage" in g_ModeScript && g_ModeScript.AllowTakeDamage != AllowTakeDamageEX)
				{
					local mode = delete g_ModeScript.AllowTakeDamage;
					if (AllowTakeDamageFuncs.find(mode) == null)
						AllowTakeDamageFuncs.append(mode);
				}
				else if ("AllowTakeDamage" in g_MapScript && g_MapScript.AllowTakeDamage != AllowTakeDamageEX)
				{
					local map = delete g_MapScript.AllowTakeDamage;
					if (AllowTakeDamageFuncs.find(map) == null)
						AllowTakeDamageFuncs.append(map);
				}
				else if ("AllowTakeDamage" in RootTable && RootTable.AllowTakeDamage != AllowTakeDamageEX)
				{
					local root = delete RootTable.AllowTakeDamage;
					if (AllowTakeDamageFuncs.find(root) == null)
						AllowTakeDamageFuncs.append(root);
				}
				
				g_ModeScript.AllowTakeDamage <- AllowTakeDamageEX;
				//g_MapScript.AllowTakeDamage <- AllowTakeDamageEX;
				//RootTable.AllowTakeDamage <- AllowTakeDamageEX;
			}
			
			Initialized = true;
		}
		
		function ClearAllowTakeDamage()
		{
			FirstLoad = true;
			Initialized = false;
			AllowTakeDamageFuncs.clear();
			
			if ("AllowTakeDamage" in g_ModeScript && g_ModeScript.AllowTakeDamage == AllowTakeDamageEX)
				delete g_ModeScript.AllowTakeDamage;
			if ("AllowTakeDamage" in g_MapScript && g_MapScript.AllowTakeDamage == AllowTakeDamageEX)
				delete g_MapScript.AllowTakeDamage;
			if ("AllowTakeDamage" in getroottable() && getroottable().AllowTakeDamage == AllowTakeDamageEX)
				delete getroottable().AllowTakeDamage;
		}
		
		function OnGameEvent_round_end(params)
		{
			ClearAllowTakeDamage();
		}
	}
}
::L4D2Lxc_NCS.Initialize();
__CollectEventCallbacks(::L4D2Lxc_NCS, "OnGameEvent_", "GameEventCallbacks", ::RegisterScriptGameEventListener);

