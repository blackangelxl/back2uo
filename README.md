# Back2Uo - Call of Duty 2 Mod

Back2Uo brings core elements of *Call of Duty: United Offensive* to *Call of Duty 2* multiplayer:
the UO-style HUD, sprinting, ranks with artillery support, weather and war ambience, and more.

This repository holds the full source of **Back2Uo v2.1**: GSC server scripts, menus, localized
strings, effects, and graphics. The `.iwd` archives the game needs are built from these folders.

## Features

| Area | What it does |
|------|--------------|
| Sprint system | UO-style sprinting with stamina, breathing sound, and HUD stance indicator |
| Ranking system | 5 ranks from points, rank rewards, artillery strikes via binoculars at max rank |
| Weapon system | Weapon class restrictions, per-team weapon limits, grenade/smoke counts, cookable grenades, weapon damage scaling, weapon pickup |
| Player energy | Health bar, fall damage, medipacks, helmet popping, optional health regeneration |
| Weather ambience | Rain, snow, thunder and lightning per map |
| War ambience | Mortars, airplanes, anti-aircraft fire |
| Blood system | Blood splatter and blood pools |
| Anti-play | AFK detection, camper marking on the compass, spawn protection |
| HUD | UO-style HUD, binocular distance, hit distance and hit location, DM/TDM score panels |
| Messages | Clan/welcome messages, server banner, join/leave messages, next-map message |
| Menus | Server info menu, favourites entry, vote system, auto team selection |

Supported gametypes: `dm`, `tdm`, `sd`, `ctf`, `hq`.

## Repository layout

```
back2uo/                          fs_game folder contents
  back2uomod.cfg                  all mod settings (cvars), documented inline
  cod2server.cfg                  example server config
  maprotation.cfg                 example map rotation
  z_svr_back2uo_2.1/              -> z_svr_back2uo_2.1.iwd      server scripts (GSC)
    back2uo/_back2uo_*.gsc        the mod itself (entry: _back2uo_main.gsc)
    maps/mp/gametypes/*.gsc       stock gametypes with Back2Uo hooks ("Back2Uo:" comments)
    maps/mp/mp_*_fx.gsc           stock map FX scripts, adapted
  z_back2uo_2.1_client/           -> z_back2uo_2.1_client.iwd   menus, images, FX, weapons, sounds
  localized_english_iw15/         -> localized_english_iw15.iwd English strings and voice sounds
  localized_german_iw15/          -> localized_german_iw15.iwd  German strings and voice sounds
docs/                             original v2.1 ReadMe and Index (Word), code review notes
tools/
  build.py                        packs the folders into .iwd archives
  gscfmt.py                       formats GSC files (tabs, CRLF)
  gsclex.py                       checks that an edit changed only comments/whitespace
```

## Build

Requires Python 3.

```sh
python tools/build.py
```

Output: `dist/back2uo/` with the four `.iwd` archives and the config files.

## Install (server)

1. Copy `dist/back2uo/` into the Call of Duty 2 install directory, so you have `<CoD2>/back2uo/`.
2. Start the server with:

   ```
   +set fs_game back2uo +exec cod2server.cfg
   ```

3. Load your settings from `cod2server.cfg` with `exec back2uomod.cfg`.
   Without that line, the mod runs with its default settings.

Required settings in your server config:

```
set com_hunkMegs "512"
set g_logsync "1"
set logfile "1"
set g_log "back2uo_mod.log"
```

Keep both `localized_*_iw15.iwd` files on the server, so English and German clients get text and sounds in their language.
Clients download the mod through auto-download (`sv_allowDownload`). Optionally, players without auto-download are kicked (`back2uo_autodownload`).

## Configuration

All options are in [`back2uo/back2uomod.cfg`](back2uo/back2uomod.cfg). Each cvar has an inline comment with values and default.
`set back2uo_status "0"` disables the whole mod.

## Development notes

- GSC files use tabs and CRLF line endings. Comments are English, ASCII only.
- Stock Infinity Ward scripts were changed only at the hook points. Search for `Back2Uo:` to find every hook.
- After editing scripts, run `python tools/gscfmt.py <file>` to normalise formatting.
- `tools/gsclex.py file <old> <new>` verifies that a change touched only comments and whitespace.

## Known issues

- **Red compass dots for enemy fire are hidden** on purpose by `materials/compassping_enemyfiring` in the client archive. Remove that file to bring them back.
- **Custom maps** with their own scripts or many models can conflict with the mod or hit `G_ModelIndex: overflow`.
- **Weapon damage scaling** does not always apply to mounted turrets (engine limitation).

Suspected script bugs found during the code cleanup are listed in [docs/code-review-notes.md](docs/code-review-notes.md).

## Credits

- **Creator:** [ModU]Wulf
- **Assistants:** [LE|Style]Lejack, -]GCF[-Tool
- **Translation:** Tabbycat (Paul Gallagher)
- Thanks to the -]GCF[- team, the GFM Mod team, the CODW clan for the test server, and all Back2Uo players.
- In memory of RaZor.

## License

The original Back2Uo code and assets are released under the [MIT License](LICENSE).
Files derived from Infinity Ward / Activision content stay the property of their owners and are **not** covered by MIT. See [LICENSE](LICENSE) for the list.
You need a legal copy of Call of Duty 2 to use this mod.
