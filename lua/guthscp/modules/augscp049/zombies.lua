local augscp049 = guthscp.modules.augscp049

--[[--------------------------------------------------------------------------
    ROSTER DES ZOMBIES DE SCP-049  (configuration standalone)
----------------------------------------------------------------------------
    Pour ajouter un zombie : copie un bloc et change les valeurs.

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
      brute      -> slam : dégâts de zone + recul
--]]

augscp049.ZombieRoster = {

    -- ----- COMMUN : stats simples -----
    {
        id = "husk", name = "Common Husk", tier = "common",
        model = "models/player/zombie_classic.mdl",
        health = 600, speed = 200,
    },
    {
        id = "crawler", name = "Agile Zombie", tier = "common",
        model = "models/player/zombie_fast.mdl",
        health = 450, speed = 250,
    },

    -- ----- RARE : meilleures stats -----
    {
        id = "stalker", name = "Stalker", tier = "rare",
        model = "models/player/zombie_fast.mdl",
        health = 900, speed = 225,
    },
    {
        id = "bruiser", name = "Bruiser", tier = "rare",
        model = "models/player/zombie_classic.mdl",
        health = 1100, speed = 180,
    },

    -- ----- ÉPIQUE : passif + stats -----
    {
        id = "vampire", name = "Vampire Zombie", tier = "epic",
        model = "models/player/zombie_classic.mdl",
        health = 1100, speed = 200, passive = "lifesteal",
    },
    {
        id = "armored", name = "Armored Zombie", tier = "epic",
        model = "models/player/zombie_soldier.mdl",
        health = 1200, speed = 150, passive = "armor",
    },
    {
        id = "revenant", name = "Revenant", tier = "epic",
        model = "models/player/zombie_soldier.mdl",
        health = 1200, speed = 190, passive = "regen",
    },

    -- ----- LÉGENDAIRE : abilité + passif + stats -----
    {
        id = "leg_scout", name = "Scout Zombie", tier = "legendary",
        model = "models/player/zombie_fast.mdl",
        health = 450, speed = 240, ability = "scout", passive = "lifesteal",
    },
    {
        id = "leg_reaver", name = "Reaver Zombie", tier = "legendary",
        model = "models/player/zombie_classic.mdl",
        health = 850, speed = 185, ability = "normal", passive = "regen",
    },
    {
        id = "leg_jugg", name = "Juggernaut Zombie", tier = "legendary",
        model = "models/player/zombie_soldier.mdl",
        health = 1600, speed = 140, ability = "juggernaut", passive = "armor",
    },
    {
        id = "leg_brute", name = "Brute Zombie", tier = "legendary",
        model = "models/player/zombie_soldier.mdl",
        health = 1050, speed = 165, ability = "brute", passive = "regen",
    },
}
