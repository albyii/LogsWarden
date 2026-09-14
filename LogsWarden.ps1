#requires -Version 5.1
<#
    LogsWarden
    Defensive Minecraft log-analysis / screenshare evidence tool.

    IMPORTANT:
      - This script only READS text/log files.
      - It never executes Minecraft mods, jars, DLLs, or log contents.
      - Matches are evidence leads. A string match alone is NOT proof that a player cheated.
      - Designed to work as a single-file PowerShell 5.1+ CMD/console tool.

    One-line launcher:
      powershell -ExecutionPolicy Bypass -Command "irm 'https://raw.githubusercontent.com/albyii/LogsWarden/main/LogsWarden.ps1' | iex"
#>

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'


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
# Console UI / state
# -----------------------------
$script:Results = @()
$script:SelectedRoot = $null
$script:ScannedFiles = 0
$script:TotalLines = 0
$script:ScanSeconds = 0
$script:Cancelled = $false
    $script:CheatingAssumption = 'NO'

function Write-Color([string]$Text,[ConsoleColor]$Color = [ConsoleColor]::Gray,[switch]$NoNewLine) {
    $old = [Console]::ForegroundColor
    [Console]::ForegroundColor = $Color
    if ($NoNewLine) { [Console]::Write($Text) } else { [Console]::WriteLine($Text) }
    [Console]::ForegroundColor = $old
}

function Clear-Screen { Clear-Host }

function Write-Line([string]$Text = "", [ConsoleColor]$Color = [ConsoleColor]::Gray) {
    Write-Color $Text $Color
}

function Write-Rule {
    Write-Color ("─" * 76) DarkGray
}

function Write-Header([string]$Subtitle = "MINECRAFT LOG FORENSIC ANALYZER") {
    Clear-Screen
    Write-Color "" DarkGray
    Write-Color "  ╔══════════════════════════════════════════════════════════════════════════╗" Cyan
    Write-Color "  ║                         L O G S W A R D E N                            ║" Cyan
    Write-Color "  ║                 MINECRAFT FORENSIC ANALYZER                            ║" DarkCyan
    Write-Color "  ╚══════════════════════════════════════════════════════════════════════════╝" Cyan
    Write-Color ("  " + $Subtitle) Gray
    Write-Color ""
}

function Pause-Console {
    Write-Color "" DarkGray
    Write-Color "  Press ENTER to continue..." DarkGray
    [void](Read-Host)
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
                    $_.Extension -in @('.log','.txt','.latest','.json','.log.gz') -or
                    $_.Name -match '^(latest|debug|launcher.*|crash-.*)\.log$'
                )
            }
    } catch { @() }
}

function New-Match($Sig,[string]$File,[int]$Line,[string]$Evidence,[string]$Pattern) {
    $kind = if ($Sig.Lead) { 'LEAD' } else { 'DETECTION' }
    [PSCustomObject]@{
        Name=$Sig.Name; Category=$Sig.Category; Weight=[int]$Sig.Weight; Kind=$kind
        Reason=$Sig.Reason; File=$File; Line=$Line; Pattern=$Pattern; Evidence=$Evidence.Trim()
    }
}

function Test-CancelKey {
    if ([Console]::KeyAvailable) {
        $key = [Console]::ReadKey($true)
        if ($key.Key -eq [ConsoleKey]::C) { return $true }
        if ($key.Key -eq [ConsoleKey]::Escape) { return $true }
    }
    return $false
}

function Get-Spinner([int]$Index) {
    $chars = @('|','/','-','\\')
    return $chars[$Index % $chars.Count]
}

function Scan-Logs([string]$Root) {
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $script:Results = @()
    $script:ScannedFiles = 0
    $script:TotalLines = 0
    $script:Cancelled = $false
    $script:CheatingAssumption = 'NO'

    $files = @(Get-LogFiles $Root)
    $fileCount = $files.Count
    if ($fileCount -eq 0) { $sw.Stop(); return }

    Clear-Screen
    Write-Color "" DarkGray
    Write-Color "  ┌──────────────────────────────────────────────────────────────────────────┐" Cyan
    Write-Color "  │                         LIVE FORENSIC SCAN                               │" Cyan
    Write-Color "  └──────────────────────────────────────────────────────────────────────────┘" Cyan
    Write-Color "  Target   : $Root" Gray
    Write-Color "  Files    : $fileCount" Gray
    Write-Color "  Cancel   : press C or ESC at any time" DarkYellow
    Write-Color ""

    $i=0
    foreach ($file in $files) {
        if (Test-CancelKey) { $script:Cancelled=$true; break }
        $i++
        $script:ScannedFiles=$i
        $pct=[int](($i/$fileCount)*100)
        $barWidth=48
        $filled=[int][Math]::Floor(($pct/100)*$barWidth)
        $bar=('█'*$filled)+('░'*($barWidth-$filled))
        $spinner=Get-Spinner $i
        $detCount=@($script:Results | Where-Object Kind -eq 'DETECTION').Count
        $leadCount=@($script:Results | Where-Object Kind -eq 'LEAD').Count
        Write-Host ("`r  [{0}] {1,3}%  {2}  {3}/{4} files  |  detections: {5}  leads: {6}" -f $spinner,$pct,$bar,$i,$fileCount,$detCount,$leadCount) -NoNewline
        Write-Host ""
        Write-Color ("      CURRENT FILE: " + $file.FullName) DarkGray

        try {
            $lineNo=0
            foreach ($line in [System.IO.File]::ReadLines($file.FullName)) {
                if (Test-CancelKey) { $script:Cancelled=$true; break }
                $lineNo++; $script:TotalLines++
                $lower=$line.ToLowerInvariant()
                foreach ($sig in $Signatures) {
                    foreach ($pattern in $sig.Patterns) {
                        if ($lower.Contains($pattern.ToLowerInvariant())) {
                            $script:Results += New-Match $sig $file.FullName $lineNo $line $pattern
                            break
                        }
                    }
                }
            }
        } catch { }
        if ($script:Cancelled) { break }
    }

    $script:Results=@(
        $script:Results |
        Group-Object Name,File,Line |
        ForEach-Object { $_.Group | Sort-Object Weight -Descending | Select-Object -First 1 } |
        Sort-Object @{Expression={if($_.Kind -eq 'DETECTION'){0}else{1}}}, @{Expression={[int]$_.Weight};Descending=$true}, Name,File,Line
    )
    $sw.Stop(); $script:ScanSeconds=[Math]::Round($sw.Elapsed.TotalSeconds,2)
    $finalDet=@($script:Results | Where-Object Kind -eq 'DETECTION').Count
    $finalLead=@($script:Results | Where-Object Kind -eq 'LEAD').Count
    Write-Color ""
    if ($script:Cancelled) { Write-Color "  ■ SCAN CANCELLED — PARTIAL RESULTS RETAINED" Yellow }
    else { Write-Color "  ✓ SCAN COMPLETE — $fileCount files analyzed" Green }
    Write-Color "  Detections: $finalDet   Leads: $finalLead   Lines: $($script:TotalLines)   Time: $($script:ScanSeconds)s" Gray
}

function Get-CheatingAssumption {
    # Simple moderation assumption: YES or NO only.
    # This is an automated evidence-based estimate, not proof of player behavior.
    $detections=@($script:Results | Where-Object Kind -eq 'DETECTION')
    $unique=@($detections | Select-Object -ExpandProperty Name -Unique)
    $cheating = ($unique.Count -ge 2 -or $detections.Count -ge 1 -and @($detections | Where-Object Weight -ge 16).Count -ge 1)
    $script:CheatingAssumption = if($cheating){'YES'}else{'NO'}
    return $script:CheatingAssumption
}
function Get-CheatSummary {
    $detections=@($script:Results|Where-Object Kind -eq 'DETECTION')
    $leads=@($script:Results|Where-Object Kind -eq 'LEAD')
    $uniqueDet=@($detections | Group-Object Name | ForEach-Object { $_.Group | Sort-Object Weight -Descending | Select-Object -First 1 })

    if($uniqueDet.Count -eq 0 -and $leads.Count -eq 0){
        return 'No specific cheats detected.'
    }

    $names=@($uniqueDet | Select-Object -ExpandProperty Name -Unique)
    if($names.Count -gt 0){
        return ($names -join ', ')
    }
    return 'No specific cheat signature detected; review the security/behavior leads.'
}

function Get-FullReportText {
    $cheating=Get-CheatingAssumption
    $cheats=Get-CheatSummary
    $det=@($script:Results|Where-Object Kind -eq 'DETECTION')
    $lead=@($script:Results|Where-Object Kind -eq 'LEAD')
    $uniqueDet=@($det | Group-Object Name | ForEach-Object { $_.Group | Sort-Object Weight -Descending | Select-Object -First 1 })
    $out=[System.Collections.Generic.List[string]]::new()
    [void]$out.Add('============================================================')
    [void]$out.Add('LOGSWARDEN - MINECRAFT LOG ANALYSIS REPORT')
    [void]$out.Add('============================================================')
    [void]$out.Add("CHEATING ASSUMPTION : $cheating")
    [void]$out.Add("LIKELY CHEATS       : $cheats")
    [void]$out.Add("Root                 : $script:SelectedRoot")
    [void]$out.Add("Files                : $script:ScannedFiles")
    [void]$out.Add("Lines                : $script:TotalLines")
    [void]$out.Add("Unique Detections    : $($(@($det|Select-Object -ExpandProperty Name -Unique)).Count)")
    [void]$out.Add("Detection Matches    : $($det.Count)")
    [void]$out.Add("Leads                : $($lead.Count)")
    [void]$out.Add("Scan time            : $script:ScanSeconds seconds")
    [void]$out.Add("Generated            : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
    [void]$out.Add('')
    [void]$out.Add('NOTE: CHEATING ASSUMPTION is an automated moderation estimate based on')
    [void]$out.Add('configured signatures. It is not proof of player behavior.')
    [void]$out.Add('')
    [void]$out.Add('FINDINGS')
    [void]$out.Add('------------------------------------------------------------')
    if($script:Results.Count -eq 0){[void]$out.Add('No signatures matched the scanned logs.')}
    else {
        # Keep the report compact: each unique detection is listed once.
        foreach($r in $uniqueDet){
            [void]$out.Add('')
            [void]$out.Add("[$($r.Kind)] $($r.Name)")
            [void]$out.Add("Category : $($r.Category)")
                    [void]$out.Add("Pattern  : $($r.Pattern)")
            [void]$out.Add("File     : $($r.File)")
            [void]$out.Add("Line     : $($r.Line)")
            [void]$out.Add("Reason   : $($r.Reason)")
            [void]$out.Add("Evidence : $($r.Evidence)")
        }
        if($leads.Count -gt 0){
            [void]$out.Add('')
            [void]$out.Add("ADDITIONAL LEADS: $(@($leads|Select-Object -ExpandProperty Name -Unique) -join ', ')")
        }
    }
    return ($out -join [Environment]::NewLine)
}

function Copy-Report {
    if($script:Results.Count -eq 0){Write-Color '  No results to copy. Run a scan first.' Yellow; return}
    $text=Get-FullReportText
    try { Set-Clipboard -Value $text; Write-Color '  ✓ FULL REPORT COPIED TO CLIPBOARD' Green }
    catch { $text | clip.exe; Write-Color '  ✓ FULL REPORT COPIED TO CLIPBOARD' Green }
}

function Save-Report {
    if($script:Results.Count -eq 0){Write-Color '  No report available. Run a scan first.' Yellow; return}
    $path=Read-Host '  Save report to (full path, or ENTER for desktop)'
    if([string]::IsNullOrWhiteSpace($path)){ $path=Join-Path ([Environment]::GetFolderPath('Desktop')) ("LogsWarden_Report_{0}.txt" -f (Get-Date -Format 'yyyyMMdd_HHmmss')) }
    try { [IO.File]::WriteAllText($path,(Get-FullReportText),(New-Object Text.UTF8Encoding($false))); Write-Color "  ✓ REPORT SAVED: $path" Green }
    catch { Write-Color "  ✗ Could not save report: $($_.Exception.Message)" Red }
}

function Show-Summary {
    Write-Header 'SCAN RESULTS / EVIDENCE REVIEW'
    $cheating=Get-CheatingAssumption
    $cheats=Get-CheatSummary
    $det=@($script:Results|Where-Object Kind -eq 'DETECTION')
    $lead=@($script:Results|Where-Object Kind -eq 'LEAD')

    Write-Color '  MODERATION ASSUMPTION' DarkGray
    if($cheating -eq 'YES'){Write-Color '  CHEATING: YES' Red}
    else {Write-Color '  CHEATING: NO' Green}
    Write-Rule

    Write-Color '  WHAT CHEATS MAY HE USE?' Cyan
    Write-Color "  $cheats" White
    Write-Rule

    Write-Color "  Files analyzed : $script:ScannedFiles" Gray
    Write-Color "  Lines analyzed : $script:TotalLines" Gray
    Write-Color "  Unique cheats  : $(@($det|Select-Object -ExpandProperty Name -Unique).Count)" Gray
    Write-Color "  Leads          : $($lead.Count)" Gray
    Write-Color "  Scan time      : $script:ScanSeconds seconds" Gray
    Write-Color ''

    if($script:Results.Count -eq 0){Write-Color '  No signature matches found.' DarkGray; return}
    Write-Color '  DETECTIONS (each shown once)' Cyan
    Write-Rule
    $n=0
    $unique=@($det | Group-Object Name | ForEach-Object { $_.Group | Sort-Object Weight -Descending | Select-Object -First 1 })
    foreach($r in $unique){
        $n++
        $col=[ConsoleColor]::Red
        Write-Color ("  [{0:00}] {1}" -f $n,$r.Name) $col
    }
    if($lead.Count -gt 0){
        Write-Color ''
        Write-Color ("  ADDITIONAL LEADS (not counted as specific cheats): " + (@($lead|Select-Object -ExpandProperty Name -Unique) -join ', ')) DarkGray
    }
}

function Choose-Folder {
    $path=Read-Host '  Enter Minecraft / launcher log root path'
    if(-not [string]::IsNullOrWhiteSpace($path) -and (Test-Path -LiteralPath $path)){$script:SelectedRoot=(Resolve-Path -LiteralPath $path).Path;return $true}
    Write-Color '  Invalid path.' Red; return $false
}

function Auto-Detect {
    $roots=@(Get-DefaultRoots)
    if($roots.Count -eq 0){Write-Color '  No standard Minecraft/launcher locations found.' Yellow;return $false}
    if($roots.Count -eq 1){$script:SelectedRoot=$roots[0];Write-Color "  ✓ AUTO-DETECTED: $($script:SelectedRoot)" Green;return $true}
    Write-Color '  DETECTED LOCATIONS' Cyan
    for($i=0;$i -lt $roots.Count;$i++){Write-Color ("  [{0}] {1}" -f ($i+1),$roots[$i]) Gray}
    $choice=Read-Host '  Select location number (ENTER = 1)'
    if([string]::IsNullOrWhiteSpace($choice)){$choice=1}
    $num=0
    if([int]::TryParse($choice,[ref]$num) -and $num -ge 1 -and $num -le $roots.Count){$script:SelectedRoot=$roots[$num-1];Write-Color "  ✓ SELECTED: $($script:SelectedRoot)" Green;return $true}
    Write-Color '  Invalid selection.' Red;return $false
}

function Start-Scan {
    if(-not $script:SelectedRoot){ if(-not (Auto-Detect)){return} }
    if(-not (Test-Path -LiteralPath $script:SelectedRoot)){ if(-not (Choose-Folder)){return} }
    $files=@(Get-LogFiles $script:SelectedRoot)
    if($files.Count -eq 0){Write-Color "  No supported log/text files found under: $script:SelectedRoot" Yellow;return}
    Scan-Logs $script:SelectedRoot
}

function Clear-Results {
    $script:Results=@();$script:ScannedFiles=0;$script:TotalLines=0;$script:ScanSeconds=0;$script:CheatingAssumption='NO'
    Write-Color '  ✓ RESULTS CLEARED' Green
}

function Show-Menu {
    Write-Header
    $root=if($script:SelectedRoot){$script:SelectedRoot}else{'NOT SELECTED'}
    Write-Color "  TARGET: $root" Gray
    Write-Color ""
    Write-Color "  ┌──────────────────────────────────────────────────────────────────────────┐" DarkCyan
    Write-Color "  │  [1]  AUTO-DETECT & SCAN                                                 │" White
    Write-Color "  │  [2]  SELECT FOLDER                                                      │" White
    Write-Color "  │  [3]  SCAN SELECTED FOLDER                                               │" White
    Write-Color "  │  [4]  SHOW RESULTS                                                       │" White
    Write-Color "  │  [5]  COPY FULL REPORT                                                   │" White
    Write-Color "  │  [6]  SAVE REPORT                                                        │" White
    Write-Color "  │  [7]  CLEAR RESULTS                                                      │" White
    Write-Color "  │  [8]  EXIT                                                               │" White
    Write-Color "  └──────────────────────────────────────────────────────────────────────────┘" DarkCyan
    Write-Color ""
    Write-Color "  During a scan: press C or ESC to cancel." DarkYellow
    Write-Color ""
}

while($true){
    Show-Menu
    $choice=Read-Host '  LOGSWARDEN >'
    switch($choice.Trim().ToUpperInvariant()){
        '1'{Auto-Detect|Out-Null;Start-Scan;Pause-Console}
        '2'{Choose-Folder|Out-Null;Pause-Console}
        '3'{Start-Scan;Pause-Console}
        '4'{Show-Summary;Pause-Console}
        '5'{Copy-Report;Pause-Console}
        '6'{Save-Report;Pause-Console}
        '7'{Clear-Results;Pause-Console}
        '8'{Clear-Screen;Write-Color '  LogsWarden closed.' DarkGray;break}
        default{Write-Color '  Invalid option. Choose 1-8.' Red;Start-Sleep -Milliseconds 700}
    }
}
