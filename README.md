# Keep In Touch with Judy

A Cyberpunk 2077 mod that adds an immersive, persistent SMS system for Judy Alvarez. After completing her questline, Judy will reach out to V organically — no quest triggers, just her keeping in touch.

---

## Features

- **Story-gated start** — Judy only starts texting after V rescues Evelyn (quest `q105_done` / "Disasterpiece")
- **Relationship awareness** — detects `judy_romance_active` and switches tone automatically between platonic and romance message pools
- **Anti-duplication** — sent message IDs are persisted in `used_messages.json`; the full pool resets only after every message has been seen
- **40 rotating TweakDB slots** — messages cycle through pre-registered journal slots to avoid engine conflicts
- **Native in-game phone integration** — messages appear as real SMS in the phone journal under Judy's contact
- **HUD popup** — each message triggers an authentic phone notification with sound (`PhoneSmsPopup`)
- **In-game settings** via NativeSettings:
  - Enable/Disable the mod
  - Enable/Disable photos (future feature)
  - Message frequency per relationship type: Rare / Normal / Frequent

---

## Requirements

| Mod | Link | Notes |
|-----|------|-------|
| Cyber Engine Tweaks (CET) | [Nexus](https://www.nexusmods.com/cyberpunk2077/mods/107) | Required — scripting engine |
| TweakXL | [Nexus](https://www.nexusmods.com/cyberpunk2077/mods/4197) | Required — journal slot definitions |
| ArchiveXL | [Nexus](https://www.nexusmods.com/cyberpunk2077/mods/4198) | Required — resource loading |
| Native Settings UI | [Nexus](https://www.nexusmods.com/cyberpunk2077/mods/3518) | Recommended — in-game settings panel |
| Judy Romance for Male V | [Nexus](https://www.nexusmods.com/cyberpunk2077/mods/24961) | Optional — enables the romance message pool for Male V |

---

## Installation

1. Install all required mods listed above.
2. Download the latest release.
3. Drop the `bin` and `archive` folders into your Cyberpunk 2077 root directory (or use Vortex/MO2).

---

## Message Frequency

Timing is randomized within configurable windows (in in-game seconds):

| Setting | Platonic | Romance |
|---------|----------|---------|
| Rare | 72 – 120 s | 24 – 48 s |
| Normal | 36 – 72 s | 12 – 24 s |
| Frequent | 20 – 36 s | 4 – 10 s |

---

## Project Structure

```
bin/x64/plugins/cyber_engine_tweaks/mods/KeepInTouchJudy/
├── init.lua          # Core logic, event loop, HUD integration
├── messages.lua      # Message pools (platonic / romance) and selection logic
├── settings.lua      # NativeSettings registration and frequency windows
├── sms_storage.lua   # Persistent tracking of sent message IDs
├── GameSession.lua   # Game session lifecycle hooks
├── GameUI.lua        # UI state helpers
└── Cron.lua          # Timer utilities

archive/pc/mod/
├── KeepInTouch.yaml       # TweakXL journal slot definitions (40 Judy slots + V reply slots)
└── KeepInTouch.archiveXL  # ArchiveXL manifest
```

---

## Development

- **Engine:** CET (Lua) + TweakXL (YAML)
- **IDE:** VS Code with the [Lua](https://marketplace.visualstudio.com/items?itemName=sumneko.lua) and [YAML](https://marketplace.visualstudio.com/items?itemName=redhat.vscode-yaml) extensions
- **Formatter:** [StyLua](https://marketplace.visualstudio.com/items?itemName=JohnnyMorganz.stylua-vscode) (config: `.stylua.toml`)
- **Debugging:** All key paths emit `[KIT] DEBUG: ...` logs to the CET console

### Known pitfalls

- If the game freezes on message interaction: check the last `[KIT]` print in the CET log for a journal sync error
- If Judy doesn't appear in the phone: verify the `parent` links in `KeepInTouch.yaml` and that TweakXL loaded correctly
- `onInit` must pre-register all 40 TweakDB slots via `SetFlat` before any message is sent

---

## Credits

- **Development:** jens-mu
- **Special thanks:** The CP77 modding community for CET, TweakXL, and ArchiveXL

## License

[MIT](LICENSE)
