# 🛡️ LogsWarden

[![LogsWarden](https://img.shields.io/badge/LogsWarden-PowerShell-blue)](https://github.com/albyii/LogsWarden)

**Professional Minecraft log forensic analyzer — built entirely in PowerShell.**

LogsWarden analyzes Minecraft and launcher logs for known cheat/client indicators, combat and movement modules, automation, suspicious activity, security-related artifacts, and other evidence that may help identify unauthorized clients or modifications.

> **A signature match is evidence for review, not mathematical proof of cheating.** LogsWarden separates specific detections from lower-confidence leads to reduce false positives.

## ⚡ Quick Start

[![Quick Start](https://img.shields.io/badge/Quick%20Start-Run%20LogsWarden-success)](https://github.com/albyii/LogsWarden#-quick-start)

Run LogsWarden with a single command:

```powershell
powershell -ExecutionPolicy Bypass -Command "Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/albyii/LogsWarden/main/LogsWarden.ps1')"
```

Or download/clone the repository and run:

```powershell
.\LogsWarden.ps1
```

LogsWarden automatically checks common Minecraft and launcher locations.

You can also choose a custom folder from the normal CMD interface.

## 🔎 What LogsWarden Checks

[![Checks](https://img.shields.io/badge/Analysis-Minecraft%20Logs-informational)](https://github.com/albyii/LogsWarden#-what-logswarden-checks)

LogsWarden contains a large signature database covering:

- **Combat cheats** — KillAura, AimAssist, Aimbot, TriggerBot, AutoClicker, Reach, Hitbox, Velocity, Criticals, AutoTotem, AutoArmor, AutoWeapon, AutoPotion, CrystalAura, BedAura, AnchorAura, MaceSwap and more.
- **Movement cheats** — Speed, Fly, NoFall, Jesus, Step, LongJump, HighJump, Spider, Glide, Phase, NoClip, Blink, Timer, NoSlow, InventoryMove, AirJump, BunnyHop and more.
- **World & render cheats** — XRay, ESP, Tracers, BlockESP, CaveESP, Freecam, FullBright, StorageESP, EntityRadar, search tools, seed/chunk tools and more.
- **Automation** — AutoEat, FastEat, AutoFish, ChestStealer, InventoryStealer, AutoMine, AutoRegear, AutoCraft, AutoSmelt, AutoTool, AutoRespawn, AutoXP, FastPlace, Scaffold, AutoBridge and more.
- **Client identifiers** — known Minecraft cheat/client names, namespaces and components.
- **Mod/loader indicators** — Fabric/Mixin injection, Java agents, instrumentation and suspicious client libraries.
- **Obfuscation indicators** — known obfuscators, protectors, encrypted strings and suspicious packaging.
- **Security indicators** — credential/token access, webhooks, remote endpoints, loaders and potentially malicious behavior.
- **Authentication & server activity** — suspicious authentication failures, permission events and relevant network/log patterns.

Broad or ambiguous indicators are reported as **LEADS** instead of being treated as definitive cheat detections.

## 📋 Scan Menu

[![CMD](https://img.shields.io/badge/Interface-CMD%20Only-111827)](https://github.com/albyii/LogsWarden)

LogsWarden uses a normal interactive CMD/PowerShell menu — no custom GUI required.

```text
  ┌──────────────────────────────────────────────────────────────────────────┐
  │  [1]  AUTO-DETECT & SCAN                                                 │
  │  [2]  SELECT FOLDER                                                      │
  │  [3]  SCAN SELECTED FOLDER                                               │
  │  [4]  SHOW RESULTS                                                       │
  │  [5]  COPY FULL REPORT                                                   │
  │  [6]  SAVE REPORT                                                        │
  │  [7]  CLEAR RESULTS                                                      │
  │  [8]  EXIT                                                               │
  └──────────────────────────────────────────────────────────────────────────┘
```

During a scan, press **C** or **ESC** to cancel.

### Features

- **AUTO-DETECT & SCAN** common Minecraft and launcher locations.
- **SELECT FOLDER** to scan a custom location.
- **SCAN SELECTED FOLDER** again without changing the target.
- Live scan progress in the console.
- **CHEATING: YES / NO** moderation assumption.
- **DETECTED CHEATS** listed once each.
- Separate **DETECTIONS** from lower-confidence **LEADS**.
- Show the file, line and evidence behind detections.
- **COPY FULL REPORT** to the clipboard.
- **SAVE REPORT** as a TXT report.
- Cancel long-running scans.
- Clear previous results at any time.

## 🧾 Example

[![Example](https://img.shields.io/badge/Example-Results-blueviolet)](https://github.com/albyii/LogsWarden#-example)

A clean result can look like:

```text
============================================================
  LOGSWARDEN
============================================================

  MODERATION ASSUMPTION
  CHEATING: NO
  ----------------------------------------------------------

  DETECTED CHEATS
  None

  Files analyzed : 12
  Lines analyzed : 18427
  Unique cheats  : 0
  Leads          : 1
```

A detection result can look like:

```text
============================================================
  LOGSWARDEN
============================================================

  MODERATION ASSUMPTION
  CHEATING: YES
  ----------------------------------------------------------

  DETECTED CHEATS
  ----------------------------------------------------------

  [01] AutoCrystal
  [02] Timer
  [03] TriggerBot

  Files analyzed : 18
  Lines analyzed : 26481
  Unique cheats  : 3
  Leads          : 2
```

Each specific detection is shown **once**, even when the same signature appears multiple times in the scanned logs.

## 📁 Project Structure

[![Project](https://img.shields.io/badge/Project-Single%20File-orange)](https://github.com/albyii/LogsWarden#-project-structure)

```text
LogsWarden/
├── LogsWarden.ps1
├── README.md
├── LICENSE
└── .gitignore
```

The signature database is currently contained within `LogsWarden.ps1` so the project can be distributed as a simple one-file forensic tool.

## 🧠 Signature Database

[![Signatures](https://img.shields.io/badge/Database-Signatures-purple)](https://github.com/albyii/LogsWarden#-signature-database)

LogsWarden uses structured signatures containing:

- Name
- Category
- Weight
- Explanation
- Detection patterns
- Lead/detection classification

Signatures are designed to prefer **specific identifiers** over broad everyday words.

This helps prevent normal Minecraft messages from being incorrectly interpreted as evidence of cheating.

> Internal detection weights are used by the scanner to distinguish stronger detections from lower-confidence leads. They are **not displayed as a public risk score** in the results.

## 🔐 Safety

[![Safety](https://img.shields.io/badge/Safety-Defensive%20Forensics-success)](https://github.com/albyii/LogsWarden#-safety)

LogsWarden is a **defensive forensic analysis tool**.

It:

- does not modify scanned logs;
- does not execute Minecraft mods, JARs or DLLs;
- does not execute code found inside log files;
- does not collect credentials or tokens;
- does not attempt to bypass anti-cheat systems;
- does not modify the player's Minecraft installation;
- reports suspicious security indicators for manual investigation.

> LogsWarden only analyzes text/log evidence. It does not prove what a player did in-game.

## ⚠️ Important

[![Important](https://img.shields.io/badge/Important-Review%20Before%20Moderation-yellow)](https://github.com/albyii/LogsWarden#%EF%B8%8F-important)

No static log scanner can guarantee perfect detection or zero false positives.

Minecraft logs vary between:

- Minecraft versions;
- Fabric/Forge/NeoForge environments;
- client implementations;
- server software;
- plugins;
- launcher configurations;
- logging configurations.

A LogsWarden result should therefore be combined with available server logs, staff observations, replay evidence, anti-cheat evidence and other relevant information before taking moderation action.

**Do not automatically punish a player solely because of a single signature match.**

## 🚀 One-Command Launch

[![Launch](https://img.shields.io/badge/Launch-One%20Command-brightgreen)](https://github.com/albyii/LogsWarden#-one-command-launch)

For staff or moderators who simply want to run the scanner:

```powershell
powershell -ExecutionPolicy Bypass -Command "irm 'https://raw.githubusercontent.com/albyii/LogsWarden/main/LogsWarden.ps1' | iex"
```

> This downloads and executes the current `main` version. For maximum security, inspect or clone the repository instead of blindly executing remote code.

## 👤 Contact

[![Contact](https://img.shields.io/badge/Contact-albyii-blue)](https://github.com/albyii)

**LOGSWARDEN — by albyii**

**GitHub:** `albyii`

Found a questionable detection or false positive?

Open an issue on the GitHub repository with the relevant evidence so the signature can be reviewed.

## 📄 License

[![License](https://img.shields.io/badge/License-MIT-green)](https://github.com/albyii/LogsWarden)

MIT
