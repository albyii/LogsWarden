#requires -Version 5.1
<#
    LogsWarden
    Defensive Minecraft log-analysis / screenshare evidence tool.

    IMPORTANT:
      - This script only READS text/log files.
      - It never executes Minecraft mods, jars, DLLs, or log contents.
      - Matches are evidence leads. A string match alone is NOT proof that a player cheated.
      - Designed to work as a single-file PowerShell 5.1+ tool with a Windows Forms GUI.

    One-line launcher:
      powershell -ExecutionPolicy Bypass -Command "irm 'https://raw.githubusercontent.com/albyii/LogsWarden/main/LogsWarden.ps1' | iex"
#>

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# -----------------------------
# Detection database
# -----------------------------
# Many aliases are intentionally included because different clients/loggers expose
# different names. Generic terms are given lower confidence and should be reviewed.

$Signatures = @()

function Add-Signature {
    param(
        [string]$Name,
        [string]$Category,
        [int]$Weight,
        [string]$Reason,
        [string[]]$Patterns,
        [switch]$Lead
    )
    $script:Signatures += [PSCustomObject]@{
        Name     = $Name
        Category = $Category
        Weight   = $Weight
        Reason   = $Reason
        Patterns = $Patterns
        Lead     = [bool]$Lead
    }
}

# Combat
Add-Signature "KillAura / Combat Aura" "Combat" 18 "Automated target selection or attack feature." @(
    "killaura","kill aura","targetaura","target aura","combataura","combat aura",
    "attack aura","aura module","aura hack","auraassist"
)
Add-Signature "AimAssist / Aimbot" "Combat" 18 "Aim assistance or automated targeting indicator." @(
    "aimassist","aim assist","aimbot","aim bot","silentaim","silent aim",
    "aimhelper","aim helper","rotationassist","rotation assist","targeting assist"
)
Add-Signature "TriggerBot" "Combat" 16 "Automated attack trigger indicator." @(
    "triggerbot","trigger bot","autotrigger","auto trigger","attackoncrosshair"
)
Add-Signature "AutoClicker / Clicker" "Combat" 16 "Automated mouse-clicking indicator." @(
    "autoclicker","auto clicker","clicker","clickbot","click bot",
    "clickassist","click assist","cps","clickspeed","click speed","butterflyclick"
)
Add-Signature "Reach" "Combat" 18 "Attack-range manipulation indicator." @(
    "reach","attackreach","attack reach","extendedreach","extended reach",
    "reachdistance","reach distance"
)
Add-Signature "Hitbox" "Combat" 16 "Entity hitbox manipulation indicator." @(
    "hitbox","hitboxes","hitboxexpand","hitbox expand","hitboxsize","hitbox size"
)
Add-Signature "Velocity / AntiKnockback" "Combat" 16 "Knockback manipulation indicator." @(
    "velocity","antiknockback","anti knockback","anti-kb","antikb","knockbackmodifier",
    "knockback reduction","kb reduction"
)
Add-Signature "Criticals" "Combat" 14 "Automated critical-hit behavior indicator." @(
    "criticals","criticalsmodule","critical hits","criticalhit","critical hit",
    "crit hack","crit hack"
)
Add-Signature "AutoTotem" "Combat" 15 "Automated totem handling indicator." @(
    "autototem","auto totem","totempop","totem pop","totemswap","totem swap"
)
Add-Signature "AutoArmor" "Combat" 12 "Automated armor management indicator." @(
    "autoarmor","auto armor","armorswap","armor swap"
)
Add-Signature "AutoWeapon / WeaponSwap" "Combat" 12 "Automated weapon selection indicator." @(
    "autoweapon","auto weapon","autoswitch","auto switch","weaponswitch",
    "weapon switch","swordswap","sword swap"
)
Add-Signature "AutoPotion" "Combat" 11 "Automated potion use indicator." @(
    "autopotion","auto potion","potionbot","potion bot","potswap","pot swap"
)
Add-Signature "CrystalAura" "Combat" 18 "Automated crystal-combat indicator." @(
    "crystalaura","crystal aura","autocrystal","auto crystal","crystalbot",
    "crystal bot","crystalassist","crystal assist"
)
Add-Signature "BedAura / AutoBed" "Combat" 17 "Automated bed-combat indicator." @(
    "bedaura","bed aura","autobed","auto bed","bedbreaker","bed breaker"
)
Add-Signature "AnchorAura / AutoAnchor" "Combat" 18 "Automated respawn-anchor combat indicator." @(
    "anchoraura","anchor aura","autoanchor","auto anchor","doubleanchor",
    "double anchor","anchoraction","anchor action","anchorbot","anchor bot"
)
Add-Signature "MaceSwap / MaceAssist" "Combat" 17 "Automated mace switching/action indicator." @(
    "maceswap","mace swap","maceassist","mace assist","macebot","mace bot",
    "autoswitchback","auto switch back"
)
Add-Signature "Surround / AutoSurround" "Combat" 13 "Automated defensive block placement indicator." @(
    "surround","autosurround","auto surround","surroundplus","surround+",
    "surround assist"
)
Add-Signature "HoleFill / AutoHoleFill" "Combat" 13 "Automated hole-fill indicator." @(
    "holefill","hole fill","autoholefill","auto hole fill"
)
Add-Signature "WTap / SprintReset" "Combat" 12 "Automated sprint-reset timing indicator." @(
    "wtap","w-tap","w tap","sprintreset","sprint reset","sprint-reset",
    "strafetap","strafe tap"
)
Add-Signature "AutoBlock / BlockHit" "Combat" 12 "Automated blocking/attack timing indicator." @(
    "autoblock","auto block","blockhit","block hit","blockhitting","block hitting"
)
Add-Signature "FastBow / BowAimbot" "Combat" 14 "Bow timing or aim automation indicator." @(
    "fastbow","fast bow","bowaimbot","bow aimbot","bowassist","bow assist",
    "bowbot","bow bot"
)
Add-Signature "TargetStrafe" "Combat" 12 "Automated combat strafing indicator." @(
    "targetstrafe","target strafe","orbit target","combat orbit"
)
Add-Signature "BackTrack" "Combat" 15 "Target position manipulation/backtracking indicator." @(
    "backtrack","back track","backtracking","lagcomp","fake lag"
)
Add-Signature "AutoFirework / ElytraAssist" "Combat" 11 "Automated elytra/firework utility indicator." @(
    "autofirework","auto firework","elytraswap","elytra swap","elytraassist",
    "elytra assist","fireworkbot"
)

# Movement
Add-Signature "Speed / SpeedHack" "Movement" 18 "Movement-speed manipulation indicator." @(
    "speedhack","speed hack","speedmode","speed mode","speedtimer","bhop",
    "bunnyhop","bunny hop","strafe speed","movement speed"
)
Add-Signature "Fly / Flight" "Movement" 18 "Flight or airborne movement bypass indicator." @(
    "flyhack","fly hack","flymode","fly mode","flightmode","flight mode",
    "airwalk","air walk","flyspeed","fly speed"
)
Add-Signature "NoFall" "Movement" 15 "Fall-damage bypass indicator." @(
    "nofall","no fall","fall damage bypass","fallbypass"
)
Add-Signature "Jesus / WaterWalk" "Movement" 15 "Liquid-walking indicator." @(
    "jesus","jesusmode","jesus mode","waterwalk","water walk","liquidwalk",
    "liquid walk"
)
Add-Signature "Step / StepHeight" "Movement" 13 "Step-height manipulation indicator." @(
    "stepheight","step height","stepmode","step mode","step hack"
)
Add-Signature "LongJump" "Movement" 16 "Long-jump movement manipulation indicator." @(
    "longjump","long jump","longjumpmode","long jump mode"
)
Add-Signature "HighJump" "Movement" 16 "Jump-height manipulation indicator." @(
    "highjump","high jump","jumpheight","jump height","jump hack"
)
Add-Signature "Spider / WallClimb" "Movement" 15 "Wall-climbing movement indicator." @(
    "spider","spidermode","spider mode","wallclimb","wall climb","climbwalls"
)
Add-Signature "Glide" "Movement" 14 "Glide movement indicator." @(
    "glide","glidemode","glide mode","airglide","air glide"
)
Add-Signature "Phase / NoClip" "Movement" 18 "Collision bypass indicator." @(
    "phase","phasemode","phase mode","noclip","no clip","no-clip","collision bypass"
)
Add-Signature "Blink" "Movement" 16 "Packet-delay/position-blink indicator." @(
    "blink","blinkmode","blink mode","position blink","packet blink"
)
Add-Signature "Timer" "Movement" 17 "Client tick/timer manipulation indicator." @(
    "timerhack","timer hack","timermod","timer mod","timer speed","timerboost",
    "timer boost"
)
Add-Signature "NoSlow / NoWeb" "Movement" 13 "Movement restriction bypass indicator." @(
    "noslow","no slow","noslowdown","no slowdown","noweb","no web",
    "nosoulsand","no soul sand"
)
Add-Signature "InventoryMove" "Movement" 10 "Movement while inventory/container is open indicator." @(
    "inventorymove","inventory move","inv move","inventory movement"
)
Add-Signature "FastLadder / FastClimb" "Movement" 11 "Climbing-speed manipulation indicator." @(
    "fastladder","fast ladder","fastclimb","fast climb","ladder speed"
)
Add-Signature "AirJump / MultiJump" "Movement" 15 "Repeated/air jump indicator." @(
    "airjump","air jump","multijump","multi jump","doublejump","double jump"
)
Add-Signature "Strafe / BunnyHop" "Movement" 12 "Automated or abnormal strafing indicator." @(
    "strafe","strafehack","strafe hack","bhop","bunnyhop","bunny hop"
)
Add-Signature "VelocityMove / JumpReset" "Movement" 10 "Movement timing manipulation indicator." @(
    "jumpreset","jump reset","velocitymove","velocity move","movement exploit"
)

# World / render / information
Add-Signature "XRay / CaveFinder" "World" 20 "World/resource visibility manipulation indicator." @(
    "xray","x-ray","xrayhack","xray hack","cavefinder","cave finder",
    "orefinder","ore finder","oreesp","ore esp","newchunks","new chunks"
)
Add-Signature "ESP / Tracers" "World" 16 "Enhanced entity/player visibility indicator." @(
    "playeresp","player esp","mobesp","mob esp","entityesp","entity esp",
    "itemesp","item esp","storageesp","storage esp","tracers","tracer",
    "nametagshack","name tags hack"
)
Add-Signature "BlockESP / CaveESP / ChunkESP" "World" 15 "World-information overlay indicator." @(
    "blockesp","block esp","caveesp","cave esp","chunkesp","chunk esp",
    "blocksearch","block search","entitysearch","entity search"
)
Add-Signature "NoRender" "World" 12 "Render suppression indicator." @(
    "norender","no render","no-render","renderfilter","render filter"
)
Add-Signature "Freecam" "World" 18 "Camera detachment/camera bypass indicator." @(
    "freecam","free cam","free-camera","camera noclip","camera noclip"
)
Add-Signature "FullBright / Gamma" "World" 8 "Visibility enhancement indicator; may be legitimate." @(
    "fullbright","full bright","full-bright","gamma","night vision"
) -Lead
Add-Signature "StorageESP / ChestESP" "World" 15 "Storage discovery overlay indicator." @(
    "chestesp","chest esp","storage esp","containeresp","container esp",
    "barrelesp","barrel esp","shulkeresp","shulker esp"
)
Add-Signature "EntityRadar / PlayerRadar" "World" 14 "Entity/player location overlay indicator." @(
    "entityradar","entity radar","playerradar","player radar","radar"
)
Add-Signature "Search / Finder" "World" 12 "Automated world-information search indicator." @(
    "blocksearch","itemsearch","entitysearch","searchmodule","search module",
    "findores","find ores","basefinder","base finder","stashfinder","stash finder"
)
Add-Signature "Chunk / Seed Tools" "World" 9 "World-generation analysis indicator; requires context." @(
    "seedcracker","seed cracker","seedfinder","seed finder","chunkbase",
    "chunk finder","structure finder"
) -Lead
Add-Signature "Baritone / Pathfinder" "Automation" 13 "Automated pathing/mining indicator." @(
    "baritone","pathfinder","path finder","pathing bot","pathingbot"
)
Add-Signature "Printer / Schematic" "Automation" 13 "Automated schematic/block placement indicator." @(
    "printer","schematic","autoprinter","auto printer","buildprinter",
    "build printer","schematicprinter","schematic printer"
)
Add-Signature "Nuker / FastBreak" "World" 18 "Automated or accelerated block-breaking indicator." @(
    "nuker","nukerhack","nuker hack","fastbreak","fast break","instantbreak",
    "instant break","ghosthand","ghost hand","packetmine","packet mine"
)
Add-Signature "ReachMining / FastMine" "World" 14 "Mining-range or mining-speed manipulation indicator." @(
    "fastmine","fast mine","reachmine","reach mine","automine","auto mine",
    "automining","auto mining"
)

# Automation / player utilities
Add-Signature "AutoEat" "Automation" 11 "Automated food consumption indicator." @(
    "autoeat","auto eat","eatingbot","eating bot"
)
Add-Signature "FastEat" "Automation" 13 "Eating timing manipulation indicator." @(
    "fasteat","fast eat","eatspeed","eat speed"
)
Add-Signature "AutoFish" "Automation" 11 "Automated fishing indicator." @(
    "autofish","auto fish","fishingbot","fishing bot"
)
Add-Signature "ChestStealer / InventoryStealer" "Automation" 16 "Automated inventory-looting indicator." @(
    "cheststealer","chest stealer","inventorystealer","inventory stealer",
    "containerstealer","container stealer"
)
Add-Signature "AutoMine" "Automation" 13 "Automated mining indicator." @(
    "automine","auto mine","automining","auto mining","minebot","mine bot"
)
Add-Signature "AutoRegear" "Automation" 11 "Automated inventory/regear indicator." @(
    "autoregear","auto regear","regear","auto kit","autokit","auto kit"
)
Add-Signature "AutoCraft / AutoSmelt" "Automation" 10 "Automated crafting/smelting indicator." @(
    "autocraft","auto craft","autosmelt","auto smelt","craftbot","craft bot"
)
Add-Signature "AutoTool" "Automation" 9 "Automated tool selection indicator." @(
    "autotool","auto tool","toolselect","tool select"
)
Add-Signature "AutoRespawn" "Automation" 8 "Automated respawn interaction indicator." @(
    "autorespawn","auto respawn","respawnbot"
)
Add-Signature "AutoXP / FastXP" "Automation" 11 "Automated experience interaction indicator." @(
    "autoxp","auto xp","fastxp","fast xp","fastexp","fast exp","xpbot","xp bot"
)
Add-Signature "FastPlace / AutoPlace" "Automation" 14 "Block-placement timing automation indicator." @(
    "fastplace","fast place","instantplace","instant place","autoplace",
    "auto place","placeassist","place assist","placeinterval"
)
Add-Signature "Scaffold / AutoBridge" "Automation" 18 "Automated block placement for bridging indicator." @(
    "scaffold","scaffoldwalk","scaffold walk","fastbridge","fast bridge",
    "autobridge","auto bridge","buildhelper","build helper","tower",
    "towerhack","tower hack"
)
Add-Signature "Macro / Key Automation" "Automation" 15 "Macro/key automation indicator." @(
    "macro","macro key","macrokey","macro keybind","keymacro","key macro",
    "autokey","auto key"
) -Lead
Add-Signature "AutoClick Timing Pattern" "Automation" 12 "Click automation terminology detected." @(
    "clickinterval","click interval","clickdelay","click delay",
    "randomclick","random click","jitterclick","jitter click"
) -Lead

# Client/package/loader indicators
Add-Signature "Fabric / Mixin Injection" "Client / Loader" 9 "Mixin/injection reference; legitimate mods can also use this." @(
    "mixin","mixinconfig","refmap","injection","inject","redirect","overwrite"
) -Lead
Add-Signature "Java Agent / Instrumentation" "Client / Loader" 13 "JVM instrumentation/debugging indicator; requires context." @(
    "javaagent","java agent","instrumentation","jdwp","virtualmachine",
    "bytebuddy","javassist"
) -Lead
Add-Signature "Native Hook Library" "Client / Loader" 8 "Native input hook library indicator; not cheat proof." @(
    "jnativehook","nativehook"
) -Lead
Add-Signature "ImGui Binding" "Client / Loader" 7 "Native UI binding indicator; not cheat proof." @(
    "imgui","imgui.binding","imgui.gl3","imgui.glfw"
) -Lead

# Suspicious client namespaces/packages supplied by the example plus broad names.
Add-Signature "ChainLibs Module Namespace" "Client / Package" 20 "Known suspicious module namespace indicator." @(
    "org.chainlibs.module.impl.modules.crystal",
    "org.chainlibs.module.impl.modules.blatant",
    "chainlibs.module"
)
Add-Signature "Doomsday Client Namespace" "Client / Package" 25 "Known suspicious client namespace indicator." @(
    "doomsdayclient","doomsday.client","doomsdayclient."
)
Add-Signature "Krypton Namespace" "Client / Package" 18 "Known suspicious namespace indicator." @(
    "dev.krypton","skid.krypton","skid/krypton"
)
Add-Signature "Greaj Namespace" "Client / Package" 18 "Known client namespace indicator." @(
    "xyz.greaj"
)
Add-Signature "CheatBreaker Namespace" "Client / Package" 14 "Known client namespace indicator." @(
    "com.cheatbreaker"
)
Add-Signature "Moonsworth Namespace" "Client / Package" 14 "Known client namespace indicator." @(
    "com.moonsworth"
)
Add-Signature "Nova Client Namespace" "Client / Package" 20 "Known client/API namespace indicator." @(
    "api.novaclient.lol","novaclient.lol","nova.client"
)
Add-Signature "Gamble Client Namespace" "Client / Package" 20 "Known client namespace indicator." @(
    "dev.gambleclient","gambleclient"
)
Add-Signature "Moonlight Namespace" "Client / Package" 18 "Known client namespace indicator." @(
    "wtf/moonlight","wtf.moonlight","moonlight.client"
)
Add-Signature "Alan Clients Namespace" "Client / Package" 18 "Known client namespace indicator." @(
    "com/alan/clients","com.alan.clients"
)
Add-Signature "KAMI Namespace" "Client / Package" 14 "Known utility-client namespace indicator." @(
    "me/zeroeightsix/kami","me.zeroeightsix.kami"
)
Add-Signature "MaxStats Namespace" "Client / Package" 14 "Known client namespace indicator." @(
    "club/maxstats","club.maxstats"
)
Add-Signature "Opai Namespace" "Client / Package" 14 "Known client namespace indicator." @(
    "today/opai","today.opai"
)
Add-Signature "Cheat / Hack Namespace" "Client / Package" 20 "Explicit cheat/hack package naming indicator." @(
    "cheatclient","cheat.client","hackclient","hack.client","cheatmod",
    "hackmod","cheat/mod","hack/mod"
) -Lead

# Obfuscation/protection
Add-Signature "SelfDestruct / Cleanup" "Obfuscation" 16 "Client self-removal/cleanup terminology." @(
    "selfdestruct","self destruct","self-destruct","cleanupclient","client cleanup"
)
Add-Signature "Obfuscated Auth" "Security" 18 "Obfuscated authentication/API indicator; review context." @(
    "authbypass","auth bypass","obfuscatedauth","obfuscated auth",
    "licensecheckmixin","license check"
)
Add-Signature "Java Obfuscator: Skidfuscator" "Obfuscation" 8 "Known Java obfuscator/protection indicator." @(
    "skidfuscator"
) -Lead
Add-Signature "Java Obfuscator: Paramorphism" "Obfuscation" 8 "Known Java obfuscator/protection indicator." @(
    "paramorphism"
) -Lead
Add-Signature "Java Obfuscator: Radon" "Obfuscation" 8 "Known Java obfuscator/protection indicator." @(
    "radon"
) -Lead
Add-Signature "Java Obfuscator: Caesium" "Obfuscation" 8 "Known Java obfuscator/protection indicator." @(
    "caesium"
) -Lead
Add-Signature "Java Obfuscator: Bozar" "Obfuscation" 8 "Known Java obfuscator/protection indicator." @(
    "bozar"
) -Lead
Add-Signature "Java Obfuscator: Branchlock" "Obfuscation" 8 "Known Java obfuscator/protection indicator." @(
    "branchlock"
) -Lead
Add-Signature "Java Obfuscator: Binscure" "Obfuscation" 8 "Known Java obfuscator/protection indicator." @(
    "binscure"
) -Lead
Add-Signature "Java Obfuscator: Qprotect" "Obfuscation" 8 "Known Java obfuscator/protection indicator." @(
    "qprotect"
) -Lead
Add-Signature "Java Obfuscator: Zelix" "Obfuscation" 8 "Known Java obfuscator/protection indicator." @(
    "zelix"
) -Lead
Add-Signature "Java Obfuscator: Stringer" "Obfuscation" 8 "Known Java obfuscator/protection indicator." @(
    "stringer"
) -Lead
Add-Signature "Native Obfuscation: JNIC" "Obfuscation" 8 "Native-code obfuscation/protection indicator." @(
    "jnic"
) -Lead
Add-Signature "Java Obfuscation / Encrypted Strings" "Obfuscation" 7 "Potential obfuscation terminology; requires context." @(
    "encryptedstrings","encrypted strings","string encryption","string decryptor",
    "string decryption","obfuscated strings","obfuscatedstrings"
) -Lead

# Security / credential / network indicators
Add-Signature "Credential / Token Access Indicator" "Security" 22 "Potential credential-access behavior; not automatically a cheat finding." @(
    "sessionstealer","session stealer","tokenlogger","token logger",
    "tokengrabber","token grabber","discordtoken","discord token",
    "keylogger","key logger","credentialstealer","credential stealer"
) -Lead
Add-Signature "Remote Access / Backdoor Indicator" "Security" 22 "Potential remote-control/backdoor behavior; requires review." @(
    "remoteaccess","remote access","reverseshell","reverse shell",
    "c2server","c2 server","commandandcontrol","command and control",
    "backdoor","remotecontrol","remote control"
) -Lead
Add-Signature "Webhook / External Endpoint Indicator" "Security" 12 "External webhook/API terminology; may be legitimate." @(
    "webhook","discord webhook","hook url","api endpoint","pastebin.com",
    "ngrok","requestbin"
) -Lead
Add-Signature "Suspicious Download / Loader Indicator" "Security" 14 "Dynamic download/loader terminology; requires context." @(
    "downloadandexecute","download and execute","urlclassloader","classloader",
    "runtime.exec","processbuilder","powershell -enc","invoke-expression",
    "downloadstring"
) -Lead

# Common log event patterns. These are lower-confidence because they can be legitimate.
Add-Signature "Repeated Authentication Failure" "Log Pattern" 10 "Authentication failure wording detected." @(
    "failed login","login failed","authentication failure","authentication failed",
    "invalid password","incorrect password","invalid user","login attempt failed"
) -Lead
Add-Signature "Privilege / Permission Event" "Log Pattern" 7 "Privilege-related wording detected; review context." @(
    "permission denied","permission level","operator","op granted","op removed",
    "privilege","admin permission"
) -Lead
Add-Signature "Connection / Packet Error" "Log Pattern" 5 "Network/packet error wording detected." @(
    "packet error","bad packet","invalid packet","connection reset",
    "connection lost","timeout","timed out"
) -Lead

# -----------------------------
# UI / state
# -----------------------------
$script:Results = @()
$script:SelectedRoot = $null
$script:CurrentFilter = "ALL"
$script:CurrentSearch = ""
$script:ScannedFiles = 0
$script:TotalLines = 0
$script:ScanSeconds = 0
$script:StartedAt = $null
$script:Cancelled = $false

function C([int]$r,[int]$g,[int]$b) {
    [System.Drawing.Color]::FromArgb($r,$g,$b)
}

$BG     = C 9 11 15
$PANEL  = C 16 19 25
$PANEL2 = C 22 26 34
$TEXT   = C 235 239 245
$MUTED  = C 145 154 170
$ACCENT = C 105 175 255
$GOOD   = C 80 215 145
$WARN   = C 255 190 70
$BAD    = C 255 85 105
$PURPLE = C 180 130 255
$LINE   = C 43 49 62

function Add-Ui {
    param($Parent,$Child,[int]$X,[int]$Y,[int]$W,[int]$H)
    $Child.Location = New-Object System.Drawing.Point($X,$Y)
    $Child.Size = New-Object System.Drawing.Size($W,$H)
    [void]$Parent.Controls.Add($Child)
    return $Child
}

function Make-Button([string]$Text) {
    $b = New-Object System.Windows.Forms.Button
    $b.Text = $Text
    $b.FlatStyle = "Flat"
    $b.FlatAppearance.BorderSize = 1
    $b.BackColor = $PANEL2
    $b.ForeColor = $TEXT_COLOR
    $b.Font = New-Object System.Drawing.Font("Segoe UI Semibold",9)
    $b.Cursor = [System.Windows.Forms.Cursors]::Hand
    return $b
}

function Get-DefaultRoots {
    $roots = @(
        (Join-Path $env:APPDATA ".minecraft"),
        (Join-Path $env:APPDATA "ModrinthApp"),
        (Join-Path $env:APPDATA "PrismLauncher"),
        (Join-Path $env:APPDATA "MultiMC"),
        (Join-Path $env:APPDATA "com.modrinth.theseus")
    )
    @($roots | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -Unique)
}

function Get-LogFiles([string]$Root) {
    if (-not $Root -or -not (Test-Path -LiteralPath $Root)) { return @() }

    try {
        Get-ChildItem -LiteralPath $Root -File -Recurse -ErrorAction SilentlyContinue |
            Where-Object {
                $_.Length -le 50MB -and (
                    $_.Extension -in @(".log",".txt",".latest",".json",".log.gz") -or
                    $_.Name -match '^(latest|debug|launcher.*|crash-.*)\.log$'
                )
            }
    } catch {
        @()
    }
}

function New-Match($Sig,[string]$File,[int]$Line,[string]$Evidence,[string]$Pattern) {
    $kind = if ($Sig.Lead) { "LEAD" } else { "DETECTION" }

    [PSCustomObject]@{
        Name     = $Sig.Name
        Category = $Sig.Category
        Weight   = [int]$Sig.Weight
        Kind     = $kind
        Reason   = $Sig.Reason
        File     = $File
        Line     = $Line
        Pattern  = $Pattern
        Evidence = $Evidence.Trim()
    }
}

function Scan-Logs([string]$Root) {
    $sw = [Diagnostics.Stopwatch]::StartNew()

    $script:Results = @()
    $script:ScannedFiles = 0
    $script:TotalLines = 0
    $script:Cancelled = $false

    $files = @(Get-LogFiles $Root)
    $fileCount = $files.Count

    if ($fileCount -eq 0) {
        $sw.Stop()
        $script:ScanSeconds = 0
        return
    }

    $fileIndex = 0

    foreach ($file in $files) {
        if ($script:Cancelled) { break }

        $fileIndex++
        $script:ScannedFiles = $fileIndex

        $pct = [int](($fileIndex / $fileCount) * 100)
        $progress.Value = [Math]::Min(100,$pct)
        $status.Text = "SCANNING  $fileIndex / $fileCount  •  $($file.Name)"
        $form.Refresh()
        [System.Windows.Forms.Application]::DoEvents()

        try {
            $lineNo = 0

            foreach ($line in [System.IO.File]::ReadLines($file.FullName)) {
                if ($script:Cancelled) { break }

                $lineNo++
                $script:TotalLines++

                # Avoid massive memory usage and preserve the exact evidence line.
                $lower = $line.ToLowerInvariant()

                foreach ($sig in $Signatures) {
                    foreach ($pattern in $sig.Patterns) {
                        if ($lower.Contains($pattern.ToLowerInvariant())) {
                            $script:Results += New-Match $sig $file.FullName $lineNo $line $pattern
                            break
                        }
                    }
                }
            }
        } catch {
            # Read-only analyzer: inaccessible/busy files are skipped.
        }
    }

    # De-duplicate identical signature/file/line hits.
    $script:Results = @(
        $script:Results |
            Group-Object Name,File,Line |
            ForEach-Object {
                $_.Group | Sort-Object Weight -Descending | Select-Object -First 1
            } |
            Sort-Object `
                @{Expression={ if ($_.Kind -eq "DETECTION") { 0 } else { 1 } }}, `
                @{Expression={ [int]$_.Weight }; Descending=$true}, `
                Name,File,Line
    )

    $sw.Stop()
    $script:ScanSeconds = [Math]::Round($sw.Elapsed.TotalSeconds,2)
}

function Get-Assessment {
    $detections = @($script:Results | Where-Object { $_.Kind -eq "DETECTION" })
    $leads = @($script:Results | Where-Object { $_.Kind -eq "LEAD" })

    $score = 0
    $script:Results |
        Where-Object { $_.Kind -eq "DETECTION" } |
        Group-Object Name |
        ForEach-Object {
            $score += [int]($_.Group | Sort-Object Weight -Descending | Select-Object -First 1).Weight
        }

    # Repeated independent hits add a little evidence without making one noisy
    # log line automatically decisive.
    $uniqueDetectionNames = @($detections | Select-Object -ExpandProperty Name -Unique).Count
    $score += [Math]::Min(25, [Math]::Max(0, $uniqueDetectionNames - 1) * 3)
    $score = [Math]::Min(100,$score)

    if ($detections.Count -eq 0 -and $leads.Count -eq 0) { return "CLEAN / NO MATCHES" }
    if ($score -ge 65 -or $uniqueDetectionNames -ge 5) { return "HIGH REVIEW" }
    if ($score -ge 35 -or $uniqueDetectionNames -ge 2) { return "MEDIUM REVIEW" }
    if ($detections.Count -gt 0) { return "LOW REVIEW" }
    return "LEADS ONLY"
}

function Get-FilteredResults {
    $items = @($script:Results)
    $q = $script:CurrentSearch.Trim().ToLowerInvariant()

    switch ($script:CurrentFilter) {
        "DETECTIONS" { $items = @($items | Where-Object Kind -eq "DETECTION") }
        "LEADS"      { $items = @($items | Where-Object Kind -eq "LEAD") }
        "HIGH"       { $items = @($items | Where-Object Weight -ge 16) }
        "COMBAT"     { $items = @($items | Where-Object Category -eq "Combat") }
        "MOVEMENT"   { $items = @($items | Where-Object Category -eq "Movement") }
        "WORLD"      { $items = @($items | Where-Object Category -eq "World") }
        "AUTOMATION" { $items = @($items | Where-Object Category -eq "Automation") }
        "SECURITY"   { $items = @($items | Where-Object Category -eq "Security") }
    }

    if ($q) {
        $items = @($items | Where-Object {
            $_.Name.ToLowerInvariant().Contains($q) -or
            $_.Category.ToLowerInvariant().Contains($q) -or
            $_.File.ToLowerInvariant().Contains($q) -or
            $_.Evidence.ToLowerInvariant().Contains($q) -or
            $_.Pattern.ToLowerInvariant().Contains($q)
        })
    }

    return @($items)
}

function Refresh-List {
    $list.BeginUpdate()
    $list.Items.Clear()

    $items = @(Get-FilteredResults)

    foreach ($r in $items) {
        $row = New-Object System.Windows.Forms.ListViewItem($r.Name)
        [void]$row.SubItems.Add($r.Kind)
        [void]$row.SubItems.Add([string]$r.Weight)
        [void]$row.SubItems.Add($r.Category)
        [void]$row.SubItems.Add([System.IO.Path]::GetFileName($r.File))
        [void]$row.SubItems.Add([string]$r.Line)
        $row.Tag = $r

        if ($r.Kind -eq "DETECTION") {
            $row.ForeColor = $BAD
        } elseif ($r.Weight -ge 16) {
            $row.ForeColor = $WARN
        } else {
            $row.ForeColor = $PURPLE
        }

        [void]$list.Items.Add($row)
    }

    $list.EndUpdate()
    $shown.Text = "SHOWING  $($items.Count) / $($script:Results.Count)"
}

function Refresh-Stats {
    $detections = @($script:Results | Where-Object Kind -eq "DETECTION")
    $leads = @($script:Results | Where-Object Kind -eq "LEAD")
    $assessment = Get-Assessment

    $filesValue.Text = [string]$script:ScannedFiles
    $linesValue.Text = [string]$script:TotalLines
    $matchValue.Text = [string]$detections.Count
    $leadValue.Text = [string]$leads.Count
    $timeValue.Text = "$($script:ScanSeconds)s"
    $assessmentValue.Text = $assessment

    switch -Regex ($assessment) {
        "^HIGH"   { $assessmentValue.ForeColor = $BAD }
        "^MEDIUM" { $assessmentValue.ForeColor = $WARN }
        "^LOW"    { $assessmentValue.ForeColor = $WARN }
        "LEADS"   { $assessmentValue.ForeColor = $PURPLE }
        default   { $assessmentValue.ForeColor = $GOOD }
    }
}

function Get-FullReportText {
    $assessment = Get-Assessment
    $det = @($script:Results | Where-Object Kind -eq "DETECTION")
    $lead = @($script:Results | Where-Object Kind -eq "LEAD")

    $out = [System.Collections.Generic.List[string]]::new()
    [void]$out.Add("============================================================")
    [void]$out.Add("LOGSWARDEN - MINECRAFT LOG ANALYSIS REPORT")
    [void]$out.Add("============================================================")
    [void]$out.Add("Assessment : $assessment")
    [void]$out.Add("Root       : $script:SelectedRoot")
    [void]$out.Add("Files      : $script:ScannedFiles")
    [void]$out.Add("Lines      : $script:TotalLines")
    [void]$out.Add("Detections : $($det.Count)")
    [void]$out.Add("Leads      : $($lead.Count)")
    [void]$out.Add("Scan time  : $script:ScanSeconds seconds")
    [void]$out.Add("Generated  : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
    [void]$out.Add("")
    [void]$out.Add("NOTE: Matches are evidence leads. Review the exact log evidence before")
    [void]$out.Add("making an enforcement decision.")
    [void]$out.Add("")
    [void]$out.Add("FINDINGS")
    [void]$out.Add("------------------------------------------------------------")

    if ($script:Results.Count -eq 0) {
        [void]$out.Add("No signatures matched the scanned logs.")
    } else {
        foreach ($r in $script:Results) {
            [void]$out.Add("")
            [void]$out.Add("[$($r.Kind)] $($r.Name)")
            [void]$out.Add("Category : $($r.Category)")
            [void]$out.Add("Weight   : $($r.Weight)")
            [void]$out.Add("Pattern  : $($r.Pattern)")
            [void]$out.Add("File     : $($r.File)")
            [void]$out.Add("Line     : $($r.Line)")
            [void]$out.Add("Reason   : $($r.Reason)")
            [void]$out.Add("Evidence : $($r.Evidence)")
        }
    }

    return ($out -join [Environment]::NewLine)
}

function Copy-Text([string]$Text,[string]$Message) {
    if ([string]::IsNullOrWhiteSpace($Text)) { return }
    try {
        [Windows.Forms.Clipboard]::SetText($Text)
        $status.Text = $Message
    } catch {
        [Windows.Forms.MessageBox]::Show(
            "Windows could not access the clipboard. Try again.",
            "LogsWarden"
        ) | Out-Null
    }
}

function Copy-AllResults {
    if ($script:Results.Count -eq 0) {
        [Windows.Forms.MessageBox]::Show(
            "Run a scan first. There are no findings to copy.",
            "LogsWarden"
        ) | Out-Null
        return
    }
    Copy-Text (Get-FullReportText) "FULL REPORT COPIED TO CLIPBOARD"
}

function Copy-SelectedEvidence {
    if ($list.SelectedItems.Count -eq 0) {
        [Windows.Forms.MessageBox]::Show(
            "Select a finding first.",
            "LogsWarden"
        ) | Out-Null
        return
    }

    $r = $list.SelectedItems[0].Tag
    $text = @"
[$($r.Kind)] $($r.Name)
Category : $($r.Category)
Weight   : $($r.Weight)
Pattern  : $($r.Pattern)
File     : $($r.File)
Line     : $($r.Line)
Reason   : $($r.Reason)
Evidence : $($r.Evidence)
"@
    Copy-Text $text "SELECTED EVIDENCE COPIED"
}

function Save-Report {
    if ($script:Results.Count -eq 0) {
        [Windows.Forms.MessageBox]::Show(
            "Run a scan first. There is no report to save.",
            "LogsWarden"
        ) | Out-Null
        return
    }

    $dlg = New-Object Windows.Forms.SaveFileDialog
    $dlg.Title = "Save LogsWarden Report"
    $dlg.Filter = "Text report (*.txt)|*.txt|CSV findings (*.csv)|*.csv"
    $dlg.FileName = "LogsWarden_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

    if ($dlg.ShowDialog() -ne "OK") { return }

    try {
        if ($dlg.FilterIndex -eq 2) {
            $script:Results |
                Select-Object Name,Kind,Category,Weight,Pattern,File,Line,Reason,Evidence |
                Export-Csv -LiteralPath $dlg.FileName -NoTypeInformation -Encoding UTF8
        } else {
            [IO.File]::WriteAllText(
                $dlg.FileName,
                (Get-FullReportText),
                (New-Object Text.UTF8Encoding($false))
            )
        }

        $status.Text = "REPORT SAVED  •  $($dlg.FileName)"
    } catch {
        [Windows.Forms.MessageBox]::Show(
            "Could not save the report.`n$($_.Exception.Message)",
            "LogsWarden"
        ) | Out-Null
    }
}

function Open-SelectedFile {
    if ($list.SelectedItems.Count -eq 0) { return }

    $r = $list.SelectedItems[0].Tag
    if (Test-Path -LiteralPath $r.File) {
        Start-Process notepad.exe -ArgumentList @($r.File)
    }
}

function Show-Selected {
    if ($list.SelectedItems.Count -eq 0) {
        $detail.Text = "Select a finding to inspect its exact evidence."
        return
    }

    $r = $list.SelectedItems[0].Tag
    $detail.Text = @"
CLASSIFICATION
$($r.Kind)

SIGNATURE
$($r.Name)

CATEGORY
$($r.Category)

WEIGHT
$($r.Weight)

PATTERN
$($r.Pattern)

FILE
$($r.File)

LINE
$($r.Line)

REASON
$($r.Reason)

EXACT EVIDENCE
$($r.Evidence)

REVIEW NOTE
A signature match is an indicator, not automatic proof.
Check surrounding log lines and other evidence before making
a moderation or enforcement decision.
"@
}

function Choose-Folder {
    $dlg = New-Object Windows.Forms.FolderBrowserDialog
    $dlg.Description = "Choose the Minecraft / launcher folder to analyze"
    $dlg.ShowNewFolderButton = $false

    if ($dlg.ShowDialog() -eq "OK") {
        $script:SelectedRoot = $dlg.SelectedPath
        $pathLabel.Text = $script:SelectedRoot
        $status.Text = "READY  •  FOLDER SELECTED"
    }
}

function Auto-Detect {
    $roots = @(Get-DefaultRoots)

    if ($roots.Count -eq 0) {
        [Windows.Forms.MessageBox]::Show(
            "LogsWarden could not find a standard Minecraft/launcher folder.`n`nUse SELECT FOLDER to choose it manually.",
            "LogsWarden"
        ) | Out-Null
        return
    }

    $script:SelectedRoot = $roots[0]
    $pathLabel.Text = $script:SelectedRoot

    if ($roots.Count -gt 1) {
        $status.Text = "AUTO-DETECTED  •  $($roots.Count) POSSIBLE LOCATIONS  •  USING FIRST"
    } else {
        $status.Text = "AUTO-DETECTED  •  READY"
    }
}

function Start-Scan {
    if (-not $script:SelectedRoot) {
        Auto-Detect
    }

    if (-not $script:SelectedRoot -or -not (Test-Path -LiteralPath $script:SelectedRoot)) {
        Choose-Folder
    }

    if (-not $script:SelectedRoot -or -not (Test-Path -LiteralPath $script:SelectedRoot)) {
        return
    }

    $files = @(Get-LogFiles $script:SelectedRoot)

    if ($files.Count -eq 0) {
        [Windows.Forms.MessageBox]::Show(
            "No supported log/text files were found under:`n`n$($script:SelectedRoot)",
            "LogsWarden"
        ) | Out-Null
        return
    }

    $scan.Enabled = $false
    $choose.Enabled = $false
    $auto.Enabled = $false
    $cancel.Enabled = $true
    $progress.Value = 0
    $status.Text = "STARTING SCAN..."
    $form.Refresh()

    Scan-Logs $script:SelectedRoot

    $scan.Enabled = $true
    $choose.Enabled = $true
    $auto.Enabled = $true
    $cancel.Enabled = $false

    Refresh-Stats
    Refresh-List

    $assessment = Get-Assessment

    if ($script:Cancelled) {
        $status.Text = "SCAN CANCELLED  •  PARTIAL RESULTS SHOWN"
    } else {
        $status.Text = "SCAN COMPLETE  •  $assessment  •  $($script:Results.Count) FINDINGS"
    }

    $resultsTab.Select()
}

function Clear-Results {
    $script:Results = @()
    $script:ScannedFiles = 0
    $script:TotalLines = 0
    $script:ScanSeconds = 0
    $detail.Text = "Select a finding to inspect its exact evidence."
    Refresh-Stats
    Refresh-List
    $status.Text = "RESULTS CLEARED"
}

# -----------------------------
# GUI
# -----------------------------
$form = New-Object Windows.Forms.Form
$form.Text = "LogsWarden — Minecraft Log Analyzer"
$form.StartPosition = "CenterScreen"
$form.Size = New-Object Drawing.Size(1280,820)
$form.MinimumSize = New-Object Drawing.Size(1080,700)
$form.BackColor = $BG
$form.ForeColor = $TEXT
$form.Font = New-Object Drawing.Font("Segoe UI",9)

$title = New-Object Windows.Forms.Label
$title.Text = "LOGSWARDEN"
$title.Font = New-Object Drawing.Font("Segoe UI Semibold",21)
$title.ForeColor = $ACCENT
Add-Ui $form $title 24 18 260 38 | Out-Null

$sub = New-Object Windows.Forms.Label
$sub.Text = "MINECRAFT LOG ANALYZER  /  EVIDENCE REVIEW"
$sub.ForeColor = $MUTED
$sub.Font = New-Object Drawing.Font("Segoe UI",9)
Add-Ui $form $sub 28 55 500 24 | Out-Null

$auto = Make-Button "AUTO-DETECT"
$auto.Add_Click({ Auto-Detect })
Add-Ui $form $auto 750 24 125 34 | Out-Null

$choose = Make-Button "SELECT FOLDER"
$choose.Add_Click({ Choose-Folder })
Add-Ui $form $choose 885 24 130 34 | Out-Null

$scan = Make-Button "SCAN LOGS"
$scan.BackColor = $ACCENT
$scan.ForeColor = $BG
$scan.Add_Click({ Start-Scan })
Add-Ui $form $scan 1025 24 145 34 | Out-Null

$pathLabel = New-Object Windows.Forms.Label
$pathLabel.Text = "AUTO-DETECTING STANDARD MINECRAFT / LAUNCHER LOCATIONS..."
$pathLabel.ForeColor = $MUTED
$pathLabel.AutoEllipsis = $true
Add-Ui $form $pathLabel 28 88 1140 24 | Out-Null

# Stats cards
$cardX = @(28,175,322,469,616,763)
$cardTitles = @("FILES","LINES","DETECTIONS","LEADS","SCAN TIME","ASSESSMENT")
$script:cardValues = @()

for ($i=0; $i -lt 6; $i++) {
    $p = New-Object Windows.Forms.Panel
    $p.BackColor = $PANEL
    Add-Ui $form $p $cardX[$i] 120 135 74 | Out-Null

    $l = New-Object Windows.Forms.Label
    $l.Text = $cardTitles[$i]
    $l.ForeColor = $MUTED
    $l.Font = New-Object Drawing.Font("Segoe UI Semibold",8)
    Add-Ui $p $l 12 10 110 20 | Out-Null

    $v = New-Object Windows.Forms.Label
    $v.Text = "0"
    $v.ForeColor = $TEXT
    $v.Font = New-Object Drawing.Font("Segoe UI Semibold",13)
    Add-Ui $p $v 12 31 118 32 | Out-Null

    $script:cardValues += $v
}

$filesValue = $script:cardValues[0]
$linesValue = $script:cardValues[1]
$matchValue = $script:cardValues[2]
$leadValue = $script:cardValues[3]
$timeValue = $script:cardValues[4]
$assessmentValue = $script:cardValues[5]

$progress = New-Object Windows.Forms.ProgressBar
$progress.Style = "Continuous"
$progress.Minimum = 0
$progress.Maximum = 100
Add-Ui $form $progress 915 140 253 18 | Out-Null

$status = New-Object Windows.Forms.Label
$status.Text = "READY"
$status.ForeColor = $MUTED
Add-Ui $form $status 915 163 253 24 | Out-Null

# Toolbar
$search = New-Object Windows.Forms.TextBox
$search.BackColor = $PANEL2
$search.ForeColor = $TEXT
$search.BorderStyle = "FixedSingle"
$search.Font = New-Object Drawing.Font("Segoe UI",9)
Add-Ui $form $search 28 210 300 32 | Out-Null

$filter = New-Object Windows.Forms.ComboBox
$filter.DropDownStyle = "DropDownList"
$filter.BackColor = $PANEL2
$filter.ForeColor = $TEXT
[void]$filter.Items.AddRange(@(
    "ALL","DETECTIONS","LEADS","HIGH","COMBAT","MOVEMENT","WORLD","AUTOMATION","SECURITY"
))
$filter.SelectedIndex = 0
Add-Ui $form $filter 340 210 150 32 | Out-Null

$clear = Make-Button "CLEAR"
$clear.Add_Click({ Clear-Results })
Add-Ui $form $clear 500 210 85 32 | Out-Null

$copyAll = Make-Button "COPY FULL REPORT"
$copyAll.Add_Click({ Copy-AllResults })
Add-Ui $form $copyAll 595 210 145 32 | Out-Null

$save = Make-Button "SAVE REPORT"
$save.Add_Click({ Save-Report })
Add-Ui $form $save 750 210 120 32 | Out-Null

$cancel = Make-Button "CANCEL"
$cancel.Enabled = $false
$cancel.Add_Click({
    $script:Cancelled = $true
    $status.Text = "CANCELLING..."
})
Add-Ui $form $cancel 880 210 95 32 | Out-Null

$shown = New-Object Windows.Forms.Label
$shown.Text = "SHOWING 0 / 0"
$shown.ForeColor = $MUTED
Add-Ui $form $shown 990 214 180 24 | Out-Null

# Main results list
$list = New-Object Windows.Forms.ListView
$list.View = "Details"
$list.FullRowSelect = $true
$list.GridLines = $true
$list.HideSelection = $false
$list.MultiSelect = $false
$list.BackColor = $PANEL
$list.ForeColor = $TEXT
$list.BorderStyle = "FixedSingle"
$list.Font = New-Object Drawing.Font("Segoe UI",9)
[void]$list.Columns.Add("SIGNATURE",235)
[void]$list.Columns.Add("TYPE",95)
[void]$list.Columns.Add("WEIGHT",65)
[void]$list.Columns.Add("CATEGORY",120)
[void]$list.Columns.Add("FILE",205)
[void]$list.Columns.Add("LINE",70)
Add-Ui $form $list 28 255 785 475 | Out-Null

# Detail panel
$detailPanel = New-Object Windows.Forms.Panel
$detailPanel.BackColor = $PANEL
Add-Ui $form $detailPanel 828 255 340 475 | Out-Null

$detailTitle = New-Object Windows.Forms.Label
$detailTitle.Text = "EVIDENCE DETAIL"
$detailTitle.Font = New-Object Drawing.Font("Segoe UI Semibold",10)
$detailTitle.ForeColor = $ACCENT
Add-Ui $detailPanel $detailTitle 16 14 300 25 | Out-Null

$detail = New-Object Windows.Forms.TextBox
$detail.Multiline = $true
$detail.ReadOnly = $true
$detail.ScrollBars = "Vertical"
$detail.BackColor = $PANEL2
$detail.ForeColor = $TEXT
$detail.BorderStyle = "None"
$detail.Font = New-Object Drawing.Font("Consolas",8.5)
$detail.Text = "Select a finding to inspect its exact evidence."
Add-Ui $detailPanel $detail 16 46 308 330 | Out-Null

$copyEvidence = Make-Button "COPY SELECTED"
$copyEvidence.Add_Click({ Copy-SelectedEvidence })
Add-Ui $detailPanel $copyEvidence 16 389 135 38 | Out-Null

$open = Make-Button "OPEN LOG"
$open.Add_Click({ Open-SelectedFile })
Add-Ui $detailPanel $open 160 389 148 38 | Out-Null

$hint = New-Object Windows.Forms.Label
$hint.Text = "Tip: double-click a row to open its log."
$hint.ForeColor = $MUTED
$hint.AutoEllipsis = $true
Add-Ui $detailPanel $hint 16 438 308 25 | Out-Null

# Search placeholder implemented as a label over the textbox.
$searchHint = New-Object Windows.Forms.Label
$searchHint.Text = "Search signature, category, file, evidence..."
$searchHint.ForeColor = $MUTED
Add-Ui $form $searchHint 36 214 280 24 | Out-Null
$search.BringToFront()

$search.Add_TextChanged({
    $script:CurrentSearch = $search.Text
    $searchHint.Visible = [string]::IsNullOrWhiteSpace($search.Text)
    Refresh-List
})

$filter.Add_SelectedIndexChanged({
    $script:CurrentFilter = [string]$filter.SelectedItem
    Refresh-List
})

$list.Add_SelectedIndexChanged({ Show-Selected })
$list.Add_DoubleClick({ Open-SelectedFile })

# Resize
$form.Add_Resize({
    $w = $form.ClientSize.Width
    $h = $form.ClientSize.Height

    if ($w -lt 1080 -or $h -lt 700) { return }

    $auto.Location = New-Object Drawing.Point($w-430,24)
    $choose.Location = New-Object Drawing.Point($w-295,24)
    $scan.Location = New-Object Drawing.Point($w-145,24)
    $pathLabel.Size = New-Object Drawing.Size($w-56,24)

    $progress.Location = New-Object Drawing.Point($w-253,140)
    $status.Location = New-Object Drawing.Point($w-253,163)

    $listW = [int]($w * 0.64)
    $detailX = [int]($w * 0.66)
    $detailW = [int]($w * 0.31)
    $mainH = [int]($h - 350)

    $list.Size = New-Object Drawing.Size($listW,$mainH)
    $detailPanel.Location = New-Object Drawing.Point($detailX,255)
    $detailPanel.Size = New-Object Drawing.Size($detailW,$mainH)

    $detail.Size = New-Object Drawing.Size($detailPanel.Width-32,$detailPanel.Height-145)
    $copyEvidence.Location = New-Object Drawing.Point(16,$detailPanel.Height-86)
    $open.Location = New-Object Drawing.Point(160,$detailPanel.Height-86)
    $hint.Location = New-Object Drawing.Point(16,$detailPanel.Height-38)
})

# Start in an immediately usable state.
Auto-Detect
Refresh-Stats
Refresh-List

# Friendly warning on close during scan.
$form.Add_FormClosing({
    if (-not $scan.Enabled) {
        $script:Cancelled = $true
    }
})

[void]$form.ShowDialog()
