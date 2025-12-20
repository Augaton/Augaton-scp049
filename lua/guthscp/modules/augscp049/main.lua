local MODULE = {
    name = "SCP-049",
    author = "Augaton",
    version = "1.1.0",
    description = "Be the doctor. Heal your patients",
    icon = "icon16/user.png",
	version_url = "https://raw.githubusercontent.com/Revan-Angel/scp049-guthen/refs/heads/main/lua/guthscp/modules/augscp049/main.lua?",
    dependencies = {
		base = "2.4.0",
		guthscpkeycard = "optional:2.1.6",
	},
    requires = {
		["server.lua"] = guthscp.REALMS.SERVER,
		["shared.lua"] = guthscp.REALMS.SHARED,
		["client.lua"] = guthscp.REALMS.CLIENT,
	},
}

MODULE.menu = {
	config = {
		form = {
			"General",
			{
				{
					type = "Number",
					name = "Keycard Level",
					id = "keycard_level",
					desc = [[Compatibility with keycard system. Set a keycard level to SCP-049's swep]],
					default = 5,
					min = 0,
					max = function( self, numwang )
						if self:is_disabled() then return 0 end

						return guthscp.modules.guthscpkeycard.max_keycard_level
					end,
					is_disabled = function( self, numwang )
						return guthscp.modules.guthscpkeycard == nil
					end,
				},
				{
					type = "Number",
					name = "Walk Speed",
					id = "walk_speed",
					desc = "Speed of walking for SCP-049, in hammer units",
					default = 150,
				},
				{
					type = "Number",
					name = "Run Speed",
					id = "run_speed",
					desc = "Speed of running for SCP-049, in hammer units",
					default = 210,
				},
				{
					type = "Number",
					name = "Heal Delay",
					id = "heal_time",
					desc = "Zombie healing time by SCP-049 (in seconds)",
					default = 2,
					min = 0.1,
				},
				{
					type = "Number",
					name = "Zombie Limits",
					id = "zb_limits",
					desc = "Zombie limits wich SCP-049 can transform (0 = No Limit)",
					default = 9,
					min = 0,
				},

				{
					type = "Bool",
					name = "Disable Jump",
					id = "disable_jump",
					desc = "Should SCP-049 be able to jump?",
					default = true,
				},
				{
					type = "Bool",
					name = "Immortal",
					id = "scp049_immortal",
					desc = "If checked, SCP-049 can't take damage",
					default = true,
				},
				{
					type = "Bool",
					name = "Ignores SCPs",
					id = "ignore_scps",
					desc = "If checked, SCP-049 won't be able to transform others SCP's Teams",
					default = true,
				},

				{
					type = "Teams",
					name = "Ignore Teams",
					id = "ignore_teams",
					desc = "All teams that can't be transform by SCP-049.",
					default = {},
				},
			},
			"Progress Bar",
			{
				{
					type = "Bool",
					name = "Progress Bar",
					id = "progressbar",
					desc = "Should progress bar for SCP-049 be enabled?",
					default = false,
				},
				{
					type = "Number",
					name = "Progress speed",
					id = "progressbar_speed",
					desc = "How fast should the operation be ?",
					default = 2,
				},
			},
			"Sounds",
			{
				{
					type = "String[]",
					name = "Random Sounds",
					id = "random_sound",
					desc = "Random-sound played by 049",
					default = {
						"scp049/don'tafraid.wav",
						"scp049/greetings.wav",
						"scp049/hello.wav",
						"scp049/iseeinyou.wav",
                        "scp049/notadoctor.wav",
                        "scp049/song049.wav",
					},
				},
			},
			"Translations",
			{
				type = "String",
				name = "Instructions", 
				id = "translation_1", 
				desc = "Text display with the weapon as a Instructions", 
				default = "LMB - Cure the pestilence; RMB - Restore health to the cured player;  R  - Choose a treatment method",
			},
			{
				type = "String",
				name = "Already cured",
				id = "translation_3", 
				desc = "Text display when the player is a zombie", 
				default = "This player doesn\'t have a pestilence!",
			},
			{
				type = "String",
				name = "Zombie Cap.",
				id = "translation_4", 
				desc = "Max zombie limit reach'", 
				default = "You have exceeded the limit of treatment for pestilence.",
			},
			{
				type = "String",
				name = "Menu Close Button",
				id = "translation_5", 
				desc = "Close button", 
				default = "Close",
			},
			{
				type = "String",
				name = "Start Infection",
				id = "translation_progress_start", 
				desc = "Text shown to the player when the infection is started",
				default = "The operation on patient start !",
			},
			{
				type = "String",
				name = "Infection Complete",
				id = "translation_progress_finish", 
				desc = "Text shown to the player when the infection is completed",
				default = "The operation is a great sucess !",
			},
			{
				type = "String",
				name = "Stop Infection",
				id = "translation_progress_stop", 
				desc = "Text shown to the player when the infection is stopped",
				default = "The operation has been canceled !",
			},

			"Zombie type 1 : Juggernaut",
			{
				type = "String",
				name = "Name",
				id = "jugg_name", 
				desc = "The name of the type of this zombie",
				default = "Juggernaut Zombie",
			},
			{
				type = "Number",
				name = "Health", 
				id = "jugg_health", 
				desc = "The health of the zombie", 
				default = 1500,
			},
			{
				type = "String",
				name = "Model",
				id = "jugg_model", 
				desc = "The Playermodel of the zombie",
				default = "models/player/zombie_soldier.mdl",
			},
			{
				type = "Number",
				name = "Speed",
				id = "jugg_speed", 
				desc = "The speed of the zombie", 
				default = 140,
			},

			"Zombie type 2 : Normal",
			{
				type = "String",
				name = "Name",
				id = "normal_name", 
				desc = "The name of the type of this zombie",
				default = "Normal Zombie",
			},
			{
				type = "Number",
				name = "Health", 
				id = "normal_health", 
				desc = "The health of the zombie", 
				default = 800,
			},
			{
				type = "String",
				name = "Model",
				id = "normal_model", 
				desc = "The Playermodel of the zombie",
				default = "models/player/zombie_classic.mdl",
			},
			{
				type = "Number",
				name = "Speed",
				id = "normal_speed", 
				desc = "The speed of the zombie", 
				default = 180,
			},

			"Zombie type 3 : Scout",
			{
				type = "String",
				name = "Name",
				id = "scout_name", 
				desc = "The name of the type of this zombie",
				default = "Scout Zombie",
			},
			{
				type = "Number",
				name = "Health", 
				id = "scout_health", 
				desc = "The health of the zombie", 
				default = 400,
			},
			{
				type = "String",
				name = "Model",
				id = "scout_model", 
				desc = "The Playermodel of the zombie",
				default = "models/player/zombie_fast.mdl",
			},
			{
				type = "Number",
				name = "Speed",
				id = "scout_speed", 
				desc = "The speed of the zombie", 
				default = 240,
			},
			
		},
	},
	details = {
		{
			text = "CC-BY-SA",
			icon = "icon16/page_white_key.png",
		},
		"Wiki",
		{
			text = "Read Me",
			icon = "icon16/information.png",
			url = "https://github.com/Revan-Angel/scp049-guthen/blob/main/README.md",
		},
		"Social",
		{
			text = "Github",
			icon = "guthscp/icons/github.png",
			url = "https://github.com/Revan-Angel/scp049-guthen/tree/main",
		},
		{
			text = "Steam",
			icon = "guthscp/icons/steam.png",
			url = "https://steamcommunity.com/id/RevanAngel/"
		},
		{
			text = "Discord",
			icon = "guthscp/icons/discord.png",
			url = "https://discord.gg/Jpr7gshRXR",	
		},
	},
}

function MODULE:init()
    MODULE:info("The SCP 049 system has been loaded !")
end

guthscp.module.hot_reload("augscp049")
return MODULE
