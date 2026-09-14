# 🛡️ LogsWarden

**Professional Minecraft log forensic analyzer — built entirely in PowerShell.**

LogsWarden analyzes Minecraft and launcher logs for known cheat/client indicators, combat and movement modules, automation, suspicious activity, security-related artifacts, and other evidence that may help identify unauthorized clients or modifications.

> **A signature match is evidence for review, not mathematical proof of cheating.** LogsWarden deliberately separates stronger detections from lower-confidence leads to reduce false positives.

## ⚡ Quick Start

Run LogsWarden with a single command:

```powershell
powershell -ExecutionPolicy Bypass -Command "Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/albyii/LogsWarden/main/LogsWarden.ps1')"
```

Or download/clone the repository and run:

```powershell
.\LogsWarden.ps1
```

LogsWarden automatically checks common Minecraft and launcher locations.

You can also choose a custom folder from the interactive interface.

## 🔎 What LogsWarden Checks

LogsWarden contains a large signature database covering:

* **Combat cheats** — KillAura, AimAssist, Aimbot, TriggerBot, AutoClicker, Reach, Hitbox, Velocity, Criticals, AutoTotem, AutoArmor, AutoWeapon, AutoPotion, CrystalAura, BedAura, AnchorAura, MaceSwap and more.
* **Movement cheats** — Speed, Fly, NoFall, Jesus, Step, LongJump, HighJump, Spider, Glide, Phase, NoClip, Blink, Timer, NoSlow, InventoryMove, AirJump, BunnyHop and more.
* **World & render cheats** — XRay, ESP, Tracers, BlockESP, CaveESP, Freecam, FullBright, StorageESP, EntityRadar, Search tools, seed/chunk tools and more.
* **Automation** — AutoEat, FastEat, AutoFish, ChestStealer, InventoryStealer, AutoMine, AutoRegear, AutoCraft, AutoSmelt, AutoTool, AutoRespawn, AutoXP, FastPlace, Scaffold, AutoBridge and more.
* **Client identifiers** — known Minecraft cheat/client names, namespaces and components.
* **Mod/loader indicators** — Fabric/Mixin injection, Java agents, instrumentation and suspicious client libraries.
* **Obfuscation indicators** — known obfuscators, protectors, encrypted strings and suspicious packaging.
* **Security indicators** — credential/token access, webhooks, remote endpoints, loaders and potentially malicious behavior.
* **Authentication & server activity** — suspicious authentication failures, permission events and relevant network/log patterns.

Broad or ambiguous indicators are reported as **LEADS** instead of being treated as definitive detections.

## 📊 Risk Assessment

LogsWarden combines detection weights, evidence diversity and corroborating indicators to produce an overall assessment.

| **Assessment**     | **Meaning**                                     |
| ------------------ | ----------------------------------------------- |
| CLEAN / NO MATCHES | No configured indicators found                  |
| LEADS ONLY         | Low-confidence indicators require investigation |
| LOW REVIEW         | Limited evidence detected                       |
| MEDIUM REVIEW      | Multiple indicators detected                    |
| HIGH REVIEW        | Strong or diverse evidence detected             |

The score is intentionally an **investigation aid**, not an automatic punishment system.

Generic indicators receive lower weights, while more specific client or cheat identifiers receive higher weights.

## 🧾 Example

```text
  LOGSWARDEN RISK ASSESSMENT

                         87 / 100
                 ███████████████████████████████████░░░
                         HIGH REVIEW

  DETECTIONS

  [01] DOOMSDAY CLIENT                    +35
       ├─ CATEGORY              CLIENTS
       ├─ FILE                  latest.log
       └─ EVIDENCE              doomsday

  [02] AUTOCRYSTAL                       +16
       ├─ CATEGORY              COMBAT
       ├─ FILE                  latest.log
       └─ EVIDENCE              autoCrystal

  [03] TIMER                              +12
       ├─ CATEGORY              MOVEMENT
       ├─ FILE                  debug.log
       └─ EVIDENCE              timer

  ASSESSMENT

                         HIGH REVIEW

       Static evidence detected.
       Review surrounding log activity before moderation.
```

## 🖥️ Interactive GUI

LogsWarden includes an interactive Windows interface designed for quick moderation and investigation.

### Features

* **AUTO-DETECT** common Minecraft installations.
* **SELECT FOLDER** to scan a custom location.
* **SCAN LOGS** with live progress.
* Search results instantly.
* Filter by detection type and category.
* Separate **DETECTIONS** from **LEADS**.
* View the exact evidence that triggered a signature.
* Open the source log directly.
* Copy an individual result.
* **COPY FULL REPORT** to the clipboard.
* Save reports as **TXT** or **CSV**.
* Cancel long-running scans.
* View files, lines, detections, leads and assessment statistics.

## 📁 Project Structure

```text
LogsWarden/
├── LogsWarden.ps1
├── README.md
├── LICENSE
└── .gitignore
```

The signature database is currently contained within `LogsWarden.ps1` so the project can be distributed as a simple one-file forensic tool.

## 🧠 Signature Database

LogsWarden uses structured signatures containing:

* Name
* Category
* Weight
* Explanation
* Detection patterns
* Lead/detection classification

Signatures are designed to prefer **specific identifiers** over broad everyday words.

This helps prevent normal Minecraft messages from being incorrectly interpreted as evidence of cheating.

## 🔐 Safety

LogsWarden is a **defensive forensic analysis tool**.

It:

* does not modify scanned logs;
* does not execute Minecraft mods, JARs or DLLs;
* does not execute code found inside log files;
* does not collect credentials or tokens;
* does not attempt to bypass anti-cheat systems;
* does not modify the player's Minecraft installation;
* reports suspicious security indicators for manual investigation.

> LogsWarden only analyzes text/log evidence. It does not prove what a player did in-game.

## ⚠️ Important

No static log scanner can guarantee perfect detection or zero false positives.

Minecraft logs vary between:

* Minecraft versions;
* Fabric/Forge/NeoForge environments;
* client implementations;
* server software;
* plugins;
* launcher configurations;
* logging configurations.

A LogsWarden result should therefore be combined with available server logs, staff observations, replay evidence, anti-cheat evidence and other relevant information before taking moderation action.

**Do not automatically punish a player solely because of a single signature match.**

## 🚀 One-Command Launch

For staff or moderators who simply want to run the scanner:

```powershell
powershell -ExecutionPolicy Bypass -Command "irm 'https://raw.githubusercontent.com/albyii/LogsWarden/main/LogsWarden.ps1' | iex"
```

> This downloads and executes the current `main` version. For maximum security, inspect or clone the repository instead of blindly executing remote code.

## 👤 Contact

**LOGSWARDEN — by albyii**

**GitHub:** `albyii`

Found a questionable detection or false positive?

Open an issue on the GitHub repository with the relevant evidence so the signature can be reviewed.

## 📄 License

MIT
