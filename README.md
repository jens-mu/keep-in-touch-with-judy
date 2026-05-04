# Judy Interactive Chat (JIC)

An immersive expansion for *Cyberpunk 2077* that introduces a dynamic messaging system for Judy Alvarez and Male V. This mod focuses on expanding the post-romance interaction (and platonical friendship) with a touch of melancholy inspired by *Blade Runner* and technical vibes from *WarGames*.

## 🌟 Overview

The goal of this mod is to bridge the "silence" that often occurs after finishing Judy's questline. It adapts to your relationship status:
- **Platonic Path:** Technical talk, netrunning tips, and "choomba" vibes.
- **Romance Path (Male V):** Intimate, philosophical, and deep conversations, specifically tailored for the Male V romance experience.

## 🛠 Requirements

To function correctly, this mod requires the following base mods:
1. [Cyber Engine Tweaks (CET)](https://www.nexusmods.com/cyberpunk2077/mods/107) - Scripting engine.
2. [TweakXL](https://www.nexusmods.com/cyberpunk2077/mods/4197) - Database modifications.
3. [ArchiveXL](https://www.nexusmods.com/cyberpunk2077/mods/4198) - Resource loading.
4. **Mandatory:** [Deceptious Quest Core](https://www.nexusmods.com/cyberpunk2077/mods/7831) - Time-based event handling.
5. **Mandatory:** [Judy Romance for Male V](https://www.nexusmods.com/cyberpunk2077/mods/24961) - To enable the romance flags for Male V.

## 🚀 Features

- **Dynamic Messaging:** Messages don't just "spam" you. They trigger based on in-game time and relationship milestones.
- **Relationship Sensing:** The mod detects if `judy_romance_active` is set to `1` and switches the conversation tone accordingly.
- **Immersive Writing:** Dialogue designed to fit Judy's unique voice, with an optional "Blade Runner" atmospheric touch.
- **English Language Support:** Codebase and in-game text are entirely in English.

## 📂 Project Structure

- `src/init.lua`: Core logic and event listeners.
- `resources/*.yaml`: TweakXL definitions for new Messenger threads and entries.
- `resources/*.json`: ArchiveXL localization files containing the actual chat text.
- `modules/`: Modular Lua components for better maintainability.

## 🛠 Development & Installation

### For Users:
1. Install all requirements listed above.
2. Download the latest release.
3. Drop the `bin` and `archive` folders into your Cyberpunk 2077 root directory (or use Vortex).

### For Developers:
- Clone the repository.
- Use **VS Code** with the *Lua (sumneko)* and *YAML* extensions.
- This project follows a "Zero-Loop" philosophy to ensure zero impact on game performance.

## 📜 Credits & Contributors

- **Lead Developer:** jens-mu
- **Narrative Design & Logic Support:** Gemini (AI Collaborator)
- **Special Thanks:** The CP77 Modding Community for providing the essential frameworks.

## ⚖️ License
[MIT](LICENSE)
