# Back2Uo Mod v.2.1 ReadMe - English

## Introduction

Thank you for your interest and support for the Back2UO Mod for Call of Duty 2.

Back2UO is a Call of Duty 2 modification which takes core elements of the original
game play from CoD United Offensive and adds it to CoD 2.
For example – the heads up display, functions, atmosphere and many effects.

This ReadMe describes the **v.2.1 Rebuild**. The source code is available on GitHub:
<https://github.com/blackangelxl/back2uo>

## Index

1. Setup
2. Settings
3. Known Mod-Bugs
4. Terms of Use
5. Manufacturer Data
6. Contact Information

## 1.) Setup

- Create a folder in your Call of Duty 2 Main Directory called `back2uo`.
- Into this folder, copy the following Back2Uo Mod Files:

**Back2Uo v.2.1 Files:**

| File | Content |
|------|---------|
| `z_back2uo_2.1_client.iwd` | Menus, images, effects, weapons, sounds (client) |
| `z_svr_back2uo_2.1.iwd` | Server scripts |
| `z_svr_back2uo_2.1_libcod.iwd` | zk_libcod functions (only for servers with zk_libcod, see below) |
| `localized_english_iw15.iwd` | English texts and sounds |
| `localized_german_iw15.iwd` | German texts and sounds |
| `mp_dawnville_cl.iwd` | Map Dawnville Classic |
| `back2uomod.cfg` | All mod settings |
| `cod2server.cfg` | Example server config |
| `maprotation.cfg` | Example map rotation |
| `zk_libcod.cfg` | Settings for zk_libcod (only for servers with zk_libcod) |

To start the Server with the Back2Uo Mod you need this parameter:

**Server Parameter:**

```
+set fs_game back2uo +exec cod2server.cfg
```

> **Note:**
>
> - To use your own Settings in the `back2uomod.cfg` you must load it from your own
>   `cod2server.cfg` (`exec back2uomod.cfg`).
> - If the Back2Uo config is not loaded, the Back2UO Mod will always start with the
>   default Settings.
> - It is important that `localized_english_iw15.iwd` and `localized_german_iw15.iwd`
>   are in the folder to enable every gamer to play independent of their game version,
>   with the corresponding sounds, graphics and texts in their language.
> - Clients download the mod through the auto download (`sv_allowDownload "1"`).

### zk_libcod

The mod uses [zk_libcod](https://github.com/ibuddieat/zk_libcod) if it is installed on the server.

- **Server with zk_libcod:** Keep `z_svr_back2uo_2.1_libcod.iwd` and load `zk_libcod.cfg`
  from your server config (`exec zk_libcod.cfg`).
- **Server without zk_libcod:** Delete `z_svr_back2uo_2.1_libcod.iwd`, otherwise the scripts
  do not compile. The mod then uses its fallback functions:
  - Sprinting swaps to a sprint weapon instead of raising the player speed.
  - Test bots stand still.
  - zk_libcod features like bullet drop (`g_bulletDrop`) are not available.

### Cod2server.cfg

- Feel free to use our predefined CoD 2 server Config. It already loads
  `zk_libcod.cfg`, `back2uomod.cfg` and `maprotation.cfg`.
- If you use your own Config you MUST set these parameters in it:

**Instructions:**

```
set com_hunkMegs "512"
set g_logsync "2"    // 0 = no log, 1 = buffered, 2 = continuous, 3 = append
set logfile "1"
set g_log "games_mp.log"

exec zk_libcod.cfg   // only with zk_libcod
exec back2uomod.cfg
exec maprotation.cfg
```

> **Note:**
>
> - Without these Commands you may experience performance problems.
> - If you receive errors relating to the config – check the log files.

## 2.) Settings

Here follow details on the functions of the mod. Every setting in `back2uomod.cfg`
has an inline comment with the allowed values and the default value.

### Back2Uo Mod Settings

**Back2Uo Mod Setup:**

- Here you can activate or deactivate the Mod with all its functions and settings
  (`back2uo_status`).

**Debug:**

- `back2uo_development` activates development test functions.
- `back2uo_logprint` writes mod events (`B2U;...`) into the server log,
  optionally with a function trace.
- Both should be turned off on a public server.

**Admin Commands:**

- Set an admin password with `back2uo_admin_password`. An empty password turns
  the commands off.
- The commands are entered in the player console:

```
/openscriptmenu -1 b2u_artillery:<password>           Grants one artillery strike to yourself
/openscriptmenu -1 b2u_airplanes:<count>:<password>   Starts an airplane fly-over (0 = count from back2uo_airplanes_max_count | 1 -> 6)
/openscriptmenu -1 b2u_mortar:<password>              Starts one mortar barrage
/openscriptmenu -1 b2u_ambtracer:<password>           Starts one wave of ambience anti-aircraft fire
/openscriptmenu -1 b2u_thunderfx:<password>           Plays one lightning flash with thunder
/openscriptmenu -1 b2u_rainfx:<password>              Rain on / off for the current round (replaces snow)
/openscriptmenu -1 b2u_snowfx:<password>              Snow on / off for the current round (replaces rain)
```

- After 3 wrong passwords the player is locked out of the commands for the current map.

**Test Bots:**

- Test bots for testing the mod, e.g. on a LAN or a test server (`back2uo_testbots_aktiv`,
  `back2uo_testbots`).
- The bots walk the stock maps and Dawnville Classic along waypoints, climb, jump
  and fight like players, including melee attacks.
- The bot skill (reaction, aim and turn speed) can be set from 1 = Easy to 3 = Hard
  (`back2uo_testbots_skill`).
- Bots get names that match their team.
- The test bots require zk_libcod. Without zk_libcod they stand still.

**Back2Uo Auto Download Info:**

- Here you have the possibility to keep out players who did not activate the auto
  download in COD 2. These players receive a warning message and are kicked from the
  Server automatically.

**Client Settings:**

- These contain standard settings for clients connecting to the Server.

Settings:

```
cg_errordecay           -> "100"
cg_fov                  -> "80"
cg_hudDamageIconHeight  -> "64"
cg_hudDamageIconInScope -> "0"
cg_hudDamageIconOffset  -> "128"
cg_hudDamageIconTime    -> "2000"
cg_hudDamageIconWidth   -> "128"
cg_hudObjectiveMaxRange -> "2048"
cg_hudObjectiveMinAlpha -> "1"
cg_hudObjectiveMinHeigth -> "-70"
cg_thirdperson          -> "0"
fx_sort                 -> "1"
```

**Random Map Rotation:**

- If set, the maps of the rotation are played in random order.

### COD 2 Elements

**Crosshair Notifications:**

- Switch the crosshair, turret crosshair, names over the crosshair, mini crosshair and
  red crosshair on or off.

**Player Head Icons:**

- Switch all existing icons appearing over a player's head on or off.

**Elements:**

- Configure notifications which are shown on the player HUD or visible on walls.

**Hud Elements:**

- Configure all default COD 2 HUD elements.

**Map Ambience Effects:**

- Configure all ambience map effects.

**Map Kill Trigger:**

- Since Patch v.1.2, COD 2 contains a Kill Trigger, this prevents a player staying on or
  moving onto a non-permitted position e.g. on a roof, tree, fire etc.
- You have the possibility of decreasing the energy of players who move onto these
  areas instead of killing them.

**Gametypes:**

- Sets the respawn time for Headquarters and Capture the Flag.

### COD 2 Menu

**Automatic Team selection:**

- Player team selection happens automatically.

**Back2Uo Server Information:**

- Turn on the server information menu display after a player connects.

**Back2Uo Favourite Menu:**

- Allows an extra menu point, where players can add the Server to their own
  favourite List.

**Vote System:**

- Configure the voting system (map restart, next map, map, gametype, player kick).

### Message System

**Clan Messages & Welcome Messages:**

- With these Settings you can set your own Messages.

e.g:

```
set back2uo_clanm_0                "Message 1"
set back2uo_clanm_1                "Message 2"
```

- For further messages you only have to add lines and increase the end
  number. (e.g. `set back2uo_clanm_2`, `_3`, `_4` and so on)

**Server Messages:**

- Display the Server name, a slogan or a banner.

**Player Status Messages:**

- Shows a message to all players when a player enters or leaves the server.

**Next Map Message:**

- Adjusts and controls the display of the next map / game type message in game.

### Weather Ambience System

**Weather Effect System:**

- Adjust strength and probability / frequency of the weather effects.
- Setting these effects to high could lead to performance and stability issues
  for the server or players.

**Thunder Effect & Winter Effect:**

- Controls the ambience effects dependent on the map – i.e. Snow -> Winter Maps.

### War Ambience System

**War Effects:**

- Set the war atmosphere effects.
- Setting these effects to high could lead to performance and stability issues
  for the server or players.

**Mortar Effects:**

- Sets mortars on a map and configures them (count, warning sound, earthquake,
  damage, radius and strength).

**Airplane Effects:**

- Sets airplane effects and configures them (count, flak).
- Airplanes hit by flak can crash (`back2uo_airplanes_crash`).
- Airplanes do not fly on small maps.

**Ambience Air-Defence-Fire:**

- Sets air defence fire and the number of anti-aircraft guns.

> **Note:** For the counts (`*_max_count`) the value `0` means a random count.

### Detection | Protection System

**AFK Detection:**

- Moves the player into spectator mode if they are AFK (away from keyboard).

**Camper Protection:**

- Shows campers on the Compass.
- This Option is recommended only for Deathmatch & Team Deathmatch.

**Spawn Protection:**

- Protects newly spawned players against damage from artillery or other players
  for a time period after their spawn.
- Optionally the protection ends as soon as the player moves or acts.

### Blood System

**Blood Effects:**

- Allows adjustment of blood effects and blood pools after a player dies.

### Player Sounds

**Taunts & Sounds:**

- Allows adjustment of sounds caused by player hits or death, taunts and grenade
  warnings. These sounds can be played together.

### Points System

**Ranking Plus or Minus Points:**

- Allows adjustment of player points + or – depending on certain actions or
  situations in the game (suicide, team kill, bomb plant / defuse, surviving a round,
  capturing / defending a flag).

### Hud Notifications

**Hud Notification:**

- Hud Fx Icon
  - Indicates on the HUD if ambience effects such as Rain or Mortars are active.
- Playerposition
  - In addition to the standard functionality this extends the player position
    display, showing the current stance of the player. This also shows
    the player stamina while sprinting.

**Hud Points Notification:**

- Allows you to choose a points display for Deathmatch or for Team
  Deathmatch (shows more details than DM, such as how many players are still alive).

**Hud Object Notification:**

- Binocular Distance
  - This helps you when aiming with the artillery via the binoculars – showing
    the distance to the target in metres.
- Hit Distance
  - Shows the distance to a victim, and also the body part the kill was inflicted on.

### Player Energy System

**Energy Notification:**

- Adjusts if a player health bar is shown or not.

**Player Energy Behavior:**

- Adjusts if a player's life energy stays reduced (realistic) or is allowed to
  regenerate again.

**Fall Damage:**

- Adjusts how much life energy is deducted when a player falls from a minimum
  or maximum height to the ground.

**Medipacks:**

- Adjusts health pack use when injured / dying - each player replenishes their
  energy via these packs. Injury / death depends on where the player receives
  their injury via other players, artillery or falling.
- Medipacks are picked up automatically or by pressing the 'Use' key
  (`back2uo_medipacks_pickup`).

**Helmet Popping:**

- Adjusts if player helmets fly off when a head shot is received.
- Also it is possible to control if players can survive indirect headshot(s).

### Sprinting System

**Player Sprinting (run):**

- Indicates if players can sprint.
- The sprinting functions as in COD United Offensive.

**Sprint Mode:**

- `back2uo_sprint_mode "1"`: The sprint raises the player speed
  (`back2uo_sprint_speedscale` x `g_speed`). This requires zk_libcod; without zk_libcod
  the weapon swap is used as fallback.
- `back2uo_sprint_mode "0"`: The player swaps to a sprint weapon while sprinting.

**Additional Info:**

- Sprinting is activated by holding the 'Use' key, default 'F'.
- Sprinting is only possible when moving. Not when a player uses binoculars, a turret,
  sits, is on a ladder, is prone or crouches, or plants / defuses a bomb.
- As with COD UO, after sprinting for the full limit the player becomes tired and
  cannot sprint again until the sprint meter has replenished. After a full sprint the
  player pants and is out of breath. This noise can be heard by other players.

### Ranking System

**Ranking Status:**

- Indicates whether the ranking system is activated. Ranks give bounties and
  are displayed in game.

**Ranking Notifications & Sounds:**

- Indicates whether ranking announcements are displayed and sounded, and whether
  ranking icons are shown on the scoreboard and over team mates.

**Ranking System Level:**

- Indicates the number of points needed for a ranking increase.
- As in COD UO there are 5 ranks which a player can achieve.

**Ranking Over Level (reach max rank):**

- This sets up the possibility of having artillery available to a player after they
  achieve the highest rank.

**Ranking 1 -> 4 Bounties:**

- Indicates which reward a player receives upon reaching a certain rank.
- This bounty is allocated after each round.
- A reduction in rank is also rewarded accordingly.

**Ranking Level Allocation:**

- Indicates from which ranking level a player receives the binoculars and the ability
  to call in artillery support.

**Artillery Order:**

- Configures the artillery (count of strikes, order and warning messages,
  warning radius before self-bombardment).

Info:

- The artillery is activated by aiming (looking) with the binoculars at the target
  and pressing the 'Use' key.
- Firing of the artillery is possible only with the announcement of a distance / value.
  - The artillery always comes from the opposite direction to the player aiming,
    i.e. the player aims northwards, and the artillery comes from the south.
  - Players under spawn protection cannot be wounded by artillery.
  - The artillery is not classed as friendly fire, thus with "0" it has effect and
    with "1 -> 3" other team players are protected.
  - A player who switches to spectator loses an unused artillery strike.

### Weapon System

**Weapon System:**

- Indicates whether the weapon optimization is active in the game.

**Weapontype Selection:**

- With this setup you choose which weapon type is allowed for
  free selection (all, only MG, only rifles, only snipers, only pistols).
  - This changes the Weapon Selection Menu.

**Weapon System Extra:**

- This is an extra option for the type of weapon allowed. It allows infinite
  ammunition for pistols in the pistol only mode.

**Weapon Allow:**

- With this setup you can permit or deactivate certain player weapons or map
  weapons in the game.
- It also allows 2 new weapons to be permitted: the G43 Sniper and the
  Panzerschreck. These will then also show in the Weapon Menu.

**Weapon Limits:**

- With this setup you can limit certain weapons per team,
  e.g. 1 Sniper & 1 Shotgun per Team.

**Grenade System:**

- With this setup you can configure the max number of grenades and smoke
  grenades for players.

**Special Equipment:**

- Allows you to modify the grenades and smoke grenades, e.g. shorten the
  throwing range or use cookable grenades.

**Weapon Strength:**

- Can change the strength of weapons or an action e.g. bash with a weapon.
  - 100% corresponds to the normal damage value the weapon or action causes.
    The smaller the percentage, the smaller the damage.

**Bullet Drop:**

- With zk_libcod the bullets can be affected by gravity (`g_bulletDrop` and
  `g_bulletDropMaxTime` in `zk_libcod.cfg`).

## 3.) Known Mod-Bugs

**Red Compass Points (with Enemy Fire):**

- The red points on the compass showing enemy fire are hidden on purpose by the file
  `compassping_enemyfiring` in the folder `materials/` of `z_back2uo_2.1_client.iwd`.
- This graphic file overwrites the original effect.
- To activate the red points on the compass again, remove or rename this file in
  the folder `materials/` of `z_back2uo_2.1_client.iwd`.
- The `*.iwd` file can be opened and edited easily with WinRar, WinZip or 7-Zip.

**Custom Maps:**

- Due to the use of Back2Uo's own custom scripts, models, sounds etc.
  we cannot give a warranty or guarantee that custom maps will be compatible with this MOD.
- As there are many custom multiplayer maps, with their own scripts for map effects
  etc., these could lead to problems with the Back2Uo programming.
- It is also possible that some maps have too many models attached, and those
  combined with the Back2Uo Mod might exceed the maximum model value of the
  COD 2 Engine and generate the error `G_ModelIndex: overflow`.

**Weapon Strength Setup (Turrets):**

- Due to a problem in the CoD 2 engine sometimes the weapon strength does not
  apply to turrets.

## 4.) Terms of Use

The Back2Uo Mod may be used and applied on each COD Server.
Removal of or changing or defacing the MOD or infringement of copyright is forbidden.
The Copyright note must remain visible, complete and in the Original Form free from
changes in any way.
Changes to the script and functions, or the adjustment and extension of desired
functions, lie at the discretion of the user and are at the users own risk. These changes
still apply under copyright.

Changes, add-ons, bug fixes etc. may not be spread, communicated or distributed
further without detailed permission from the devs below.

There is no guarantee or warranty of compatibility with other Mods.
The use of the Back2Uo Mod with other Mods could lead to loss of data,
errors, performance issues or lead to system crashes.

The Back2Uo team does not accept accountability or responsibility for any damage
caused by the installation of the Back2Uo Mod. The use of the Back2Uo Mod is at the
owners / users OWN risk.

## 5.) Dev and Manufacturer Data

**The Creator:**

- [GCF]Wulf

**The Assistant:**

- [LE|Style]Lejack
- -]GCF[-Tool

**Thanks:**

- My biggest thanks go to my colleagues from the -]GCF[-Team, who always give
  me help with testing, translating and the development of the MOD.
- Thanks to the Guys from the GFM Mod, for a good info exchange.
- Thanks also to the super Website iwnation.com.
- Many thanks go to COD Infobase (cod.esgnserver2.de), for its continual
  'good Mod' advertisement & support.
- Many thanks go to the CODW Clan (codw.net), which sponsored
  us a test server for the Back2Uo development and testing.
- And naturally also thanks to all Back2Uo fans, who gave good feedback and
  have supported the development of the MOD.
- Big Thanks to Tabbycat alias Paul Gallagher for the super Translation.

**Greetings:**

- A special greeting goes to the Ex-Back2Uo Co-worker 'RaZor'. Unfortunately this is in "Memory of a 'good Co-worker & Friend'".

## 6.) Contact Information

If you have problems with the installation, setup or playing of the Back2Uo
Mod, please open an issue on GitHub:

**GitHub:** <https://github.com/blackangelxl/back2uo>

If you are interested in the Back2Uo Mod, or you want to know the developers
or simply play a round with us… then simply visit us at our Gamers Club Formation
Homepage.

**Homepage:** <http://www.gcf-team.de>
