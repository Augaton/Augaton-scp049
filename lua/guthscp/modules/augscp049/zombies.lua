local augscp049 = guthscp.modules.augscp049

--[[--------------------------------------------------------------------------
    ROSTER DES ZOMBIES DE SCP-049  (configuration standalone)
----------------------------------------------------------------------------
    Pour ajouter un zombie : copie un bloc et change les valeurs.

    Chaque tier propose les 3 gabarits de base, pour une variété homogène :
      scout   -> peu de PV, rapide          (modèle : zombie_fast)
      normal  -> équilibré                   (modèle : zombie_classic)
      armored -> beaucoup de PV, lent        (modèle : zombie_soldier)

    Champs :
      id        = identifiant unique (texte sans espace)
      name      = nom affiché
      tier      = "common" | "rare" | "epic" | "legendary"
      model     = playermodel
      health    = points de vie
      speed     = vitesse de marche/course
      passive   = (optionnel) "regen" | "armor" | "lifesteal"
      ability   = (légendaires uniquement) "scout" | "normal" | "juggernaut" | "brute"

    Rôle des tiers :
      common     -> stats simples
      rare       -> meilleures stats
      epic        -> passif + stats
      legendary   -> abilité + passif + stats

    Passifs (réglés dans shared.lua -> augscp049.Passives) :
      regen      -> soin passif / seconde
      armor      -> réduction des dégâts subis
      lifesteal  -> soin à chaque coup porté

    Abilités (réglées dans le swep scp049_zombie) :
      scout      -> bond (leap)
      normal     -> accélération temporaire
      juggernaut -> redirige les dégâts des zombies alliés proches
      brute      -> slam : dégâts de zone + recul  (dispo, non utilisée par défaut)
--]]

augscp049.ZombieRoster = {

    -- ===== COMMUN : stats simples =====
    {
        id = "common_scout", name = "Common Scout", tier = "common",
        model = "models/player/zombie_fast.mdl",
        health = 450, speed = 250,
    },
    {
        id = "common_normal", name = "Common Zombie", tier = "common",
        model = "models/player/zombie_classic.mdl",
        health = 600, speed = 205,
    },
    {
        id = "common_armored", name = "Common Armored", tier = "common",
        model = "models/player/zombie_soldier.mdl",
        health = 800, speed = 170,
    },

    -- ===== RARE : meilleures stats =====
    {
        id = "rare_scout", name = "Rare Scout", tier = "rare",
        model = "models/player/zombie_fast.mdl",
        health = 600, speed = 250,
    },
    {
        id = "rare_normal", name = "Rare Zombie", tier = "rare",
        model = "models/player/zombie_classic.mdl",
        health = 850, speed = 210,
    },
    {
        id = "rare_armored", name = "Rare Armored", tier = "rare",
        model = "models/player/zombie_soldier.mdl",
        health = 1100, speed = 170,
    },

    -- ===== ÉPIQUE : passif + stats =====
    {
        id = "epic_scout", name = "Epic Scout", tier = "epic",
        model = "models/player/zombie_fast.mdl",
        health = 800, speed = 250, passive = "lifesteal",
    },
    {
        id = "epic_normal", name = "Epic Zombie", tier = "epic",
        model = "models/player/zombie_classic.mdl",
        health = 1050, speed = 205, passive = "regen",
    },
    {
        id = "epic_armored", name = "Epic Armored", tier = "epic",
        model = "models/player/zombie_soldier.mdl",
        health = 1200, speed = 160, passive = "armor",
    },

    -- ===== LÉGENDAIRE : abilité + passif + stats =====
    {
        id = "leg_scout", name = "Legendary Scout", tier = "legendary",
        model = "models/player/zombie_fast.mdl",
        health = 950, speed = 245, ability = "scout", passive = "lifesteal",
    },
    {
        id = "leg_normal", name = "Legendary Zombie", tier = "legendary",
        model = "models/player/zombie_classic.mdl",
        health = 1200, speed = 205, ability = "normal", passive = "regen",
    },
    {
        id = "leg_armored", name = "Legendary Juggernaut", tier = "legendary",
        model = "models/player/zombie_soldier.mdl",
        health = 1500, speed = 145, ability = "juggernaut", passive = "armor",
    },
}
