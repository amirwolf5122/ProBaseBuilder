> ⚠️ **WARNING: This version is still in development. Possible bugs may be present.**

# ProBaseBuilder

<p align="center">BaseBuilder Mod for Counter-Strike 1.6 ( AMXX 1.8.2 / 1.9 / 1.10 ).</p>

<p align="center">
    <a href="https://github.com/amirwolf5122/ProBaseBuilder/archive/refs/heads/master.zip">
    <img src="https://img.shields.io/badge/ProBaseBuilder-v4.1-blue">
    <img alt="GitHub repo size" src="https://img.shields.io/github/repo-size/amirwolf5122/ProBaseBuilder">
    <a href="https://www.amxmodx.org/downloads-new.php">
    <img src="https://img.shields.io/badge/AmxModX-%3E%201.8.2-blue">

</p>
      
<p align="center">
  <a href="#about">About</a> •
  <a href="#downloads">Downloads</a> •
  <a href="#youtube">YouTube</a>
</p>

---
## About
- ProBaseBuilder is an enhanced version of the BaseBuilder mod for Counter-Strike 1.6, offering new features, improved gameplay mechanics, and seamless performance tailored for both players and administrators.

---
## Command
> **Important Note:** To use the core features of the mod , the map must be configured first.

| Command | Description |
| :--- | :--- |
| `/Clonemenu` | Opens a special admin menu for managing and cloning map blocks. |
| `/bbzones` | Opens a special admin menu for To create no build Zones. |

---
<table>
<tr>
<td valign="top">

### Player Commands

| Command | Alias |
| :--- | :--- |
| `+grab` / `-grab`| - |
| `+bb_copy` | - |
| `bb_rotate` | `R` |
| `/commands` | `/cmd` |
| `/class` | - |
| `/colors` | - |
| `/mycolor` | - |
| `/whois <color>`| - |
| `/guns` | - |
| `/team` | `/t` |
| `/unstuck` | `/uk` |
| `/respawn` | `/revive` |

</td>
<td valign="top">

### Admin Commands

| Command | Alias |
| :--- | :--- |
| `/adminmenu` | `C`, `/a` |
| `/adminhelp <player>`| `/ah` |
| `bb_buildban <player>`| `/ban` |
| `bb_swap <player>` | `/swap`, `/sp` |
| `bb_revive <player>` | `/revive`, `/rv` |
| `bb_teleport <player>`| `/teleport`, `/tp` |
| `bb_guns <player>` | - |
| `/health <player> <amount>`| `/hp` |
| `/light` | `/nor` |
| `bb_startround` | `/releasezombies`|
| `/lock` | `/claim` |

</td>
</tr>
</table>

---
Settings `Pro_basebuilder.ini`
<details>
<summary><code><strong>「 Click to expand view content 」</strong></code></summary>

* * *
```bash
# ===================================================================
#      * || Pro Base Builder: Zombie Mod Configuration || *
# ===================================================================
#      @developer: AmirWolf
#      @contact: https://t.me/Mr_Admins
# ===================================================================


# ---------------------------------
# >> Main Mod & Round Phases
# ---------------------------------

# Enables or disables the entire mod's functionality.
# If disabled, none of the mod's features will be active.
# 1 = Mod is fully enabled | 0 = Mod is fully disabled
MOD_ENABLED = 1

# Defines the duration of the "Build Phase" in seconds.
BB_BUILDTIME = 150

# Defines the duration of the "Prep Phase" in seconds.
BB_PREPTIME = 40

# How many seconds a Zombie must wait to respawn after being killed.
BB_ZOMBIE_RESPAWN = 1

# How many seconds a Human must wait to respawn as a Zombie after being infected.
BB_SURVIVOR_RESPAWN_INFECTION = 1


# ---------------------------------
# >> Building & Block Mechanics
# ---------------------------------

# Shows or hides HUD text messages on blocks.
# 1 = Enabled (Show messages) | 0 = Disabled (Hide messages)
BB_SHOW_MOVERS = 1

# Allows players to lock the blocks they place by using the lock command.
# will be rendered in red.
# 1 = Enabled (Normall) | 0 = Disabled (Locking are shown in red)
BB_LOCK_BLOCKS = 1

# The maximum number of blocks a single player can have locked at one time.
# This requires BB_LOCK_BLOCKS to be enabled (1).
BB_LOCKMAX = 20

# The maximum number of blocks a single player can copy with the clone command.
BB_MAX_USER_CLONES = 25

# Determines how block colors are assigned.
# 0 = Players choose a color from a menu.
# 1 = Each player gets a single, consistent color for all their blocks.
# 2 = Blocks are a random color every time they are placed.
BB_COLOR_MODE = 0

# Defines who can move locked blocks.
# If enabled, players can move their own locked blocks.
# If disabled, only admins can move locked blocks.
# 1 = Public can move own locked blocks. (Public = Regular Players) | 0 = Admin-only movement.
BB_MOVE_LOCKED_BLOCKS = 1

# The maximum distance (in game units) a player can push or pull a block.
BB_MAX_MOVE_DIST = 768

# Distance for snapping blocks into place when moving.
BB_MIN_MOVE_SET = 32

# Prevents players from placing blocks inside another player's block.
# This check respects team-building rules (teammates can still build together).
# 1 = Enabled (Removes the block) | 0 = Disabled (No block Removes)
BB_BLOCK_COLLISION = 1

# Admin can "grab" a player and reposition them.
# 1 = Enabled (Players can be grabbed) | 0 = Disabled (Only objects/blocks)
BB_GRAB_PLAYERS = 1


# ---------------------------------
# >> Gameplay & Player Items
# ---------------------------------

# Makes Zombie knife attacks an instant kill on Humans.
# 1 = Enabled (One-Hit Kill) | 0 = Disabled (Normal Damage)
BB_ZOMBIE_SUPERCUT = 0

# Enable or disable the internal guns menu.
# 1 = Enabled | 0 = Disabled
BB_GUNSMENU = 1

# Defines which grenades are automatically given to Humans at the start of the Prep phase.
# 'h' = HE Grenade, 'f' = Flashbang, 's' = Smoke Grenade.
BB_ROUNDNADES = hfs

# A list of letters that define which weapons are available for Humans to buy.
# a=Scout, b=XM1014, c=MAC-10, d=AUG, e=UMP45, f=SG-550, g=Galil, h=Famas, i=AWP,
# j=MP5-Navy, k=M249, l=M3, m=M4A1, n=TMP, o=G3/SG1, p=SG-552, q=AK-47, r=P90,
# s=P228, t=Dual Elites, u=Five-SeveN, v=USP, w=Glock18, x=Desert Eagle
BB_WEAPONS = bmqtx

# The file path for the custom Human knife model.
BB_KNIFE_HUMAN = models/basebuilder/v_knife.mdl


# ---------------------------------
# >> HUD, Colors & Brrier
# ---------------------------------

# Determines whether random color changes for doors are enabled.
# 1 = Enabled | 0 = Disabled
DOOR_RANDOM_COLOR_ENABLED = 1

# Time interval (in seconds) for door color changes when enabled
# This setting ONLY works if DOOR_RANDOM_COLOR_ENABLED is enabled (1).
DOOR_COLOR_CHANGE_INTERVAL = 5.0

# The primary color for barriers
# Format: R G B (values from 0.0 to 255.0). Use -1.0 for random.
BARRIER_PRIMARY_COLOR = -1.0 -1.0 -1.0

# Secondary color for the barrier.
# Format: R G B (values from 0.0 to 255.0). Use -1.0 for random.
BARRIER_SECONDARY_COLOR = 64.0 255.0 65.0

# Color of the "Build Time" countdown text.
# Format: R G B (values from 0 to 255). Use -1 for random.
DHUD_BUILD_TIME_COLOR = 182 225 50

# Screen position for the "Build Time" text.
# Format: X-coordinate Y-coordinate.
DHUD_BUILD_TIME_POSITION = -1.0 0.0

# Color of the "Prep Time" countdown text.
# Format: R G B (values from 0 to 255). Use -1 for random.
DHUD_PREP_TIME_COLOR = 182 225 50

# Screen position for the "Prep Time" text.
# Format: X-coordinate Y-coordinate.
DHUD_PREP_TIME_POSITION = -1.0 0.0

# HUD info color for humans
# Format: R G B (values from 0 to 255). Use -1 for random.
HUDINFO_HUMAN_COLOR = 0 210 120

# HUD info color for Zombies.
# Format: R G B (values from 0 to 255). Use -1 for random.
HUDINFO_ZOMBIE_COLOR = 0 200 0

# Screen position for the player info HUD.
# Format: X-coordinate Y-coordinate.
HUDINFO_POSITION = 0.01 0.22
```

</details>

* * *
## Downloads
- [Download the Latest Version](https://github.com/amirwolf5122/ProBaseBuilder/archive/refs/heads/master.zip)

## YouTube & Contact
- [YouTube Channel](https://www.youtube.com/@ProBaseBuilder)
- [Telegram ID](http://t.me/Mr_Admins)
