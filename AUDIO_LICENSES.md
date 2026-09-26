# Deliver While Hot Audio Sources

The files under `DeliverWhileHot/Audio/Source/` are preserved copies of the original MP3 files. They are not modified or used as runtime assets. The files under `DeliverWhileHot/Audio/Processed/` are derived runtime candidates.

Licensing is not verified by the filenames alone. Before distribution, record the original source URL, creator, license, attribution requirement, commercial-use permission, and download date for every source.

| Processed file | Original source filename | Processing status | License status |
| --- | --- | --- | --- |
| `molotov_glass.wav` | `11325622-glass-breaking-sound-effect-240679.mp3` | Trimmed, normalized, mono WAV | Verify source license |
| `molotov_explosion.wav` | `dragon-studio-explosion-effect-494317.mp3` | Trimmed, normalized, mono WAV | Verify source license |
| `player_scream.wav` | `universfield-male-scream-121085.mp3` | Trimmed to a short reaction, normalized, mono WAV | Verify source license |
| `cat_attack.wav` | `cartoon_music-angry-cat-meow-513483.mp3` | Trimmed, normalized, mono WAV | Verify source license |
| `cat_spawn.wav` | `freesound_community-cat-call-meow-102607.mp3` | Silence-trimmed, normalized, mono WAV | Verify source license |
| `danger_sting.wav` | `soundreality-danger-203290.mp3` | Extracted short candidate, normalized, mono WAV | Verify source license |
| `fire_loop.caf` | `dragon-studio-fire-crackling-sounds-427410.mp3` | Six-second loop candidate, crossfaded, normalized, mono CAF | Verify source license; loop needs listening review |
| `cow_moo.wav` | `dragon-studio-cow-moo-1-472361.mp3` | Trimmed/capped, normalized, mono WAV | Verify source license |
| `gunshot.wav` | `flutie8211-gun-shot-and-echo-549910.mp3` | Extracted short candidate, normalized, mono WAV | Verify source license |
| `machine_gun.wav` | `freesound_community-clean-machine-gun-burst-98224.mp3` | Extracted short candidate, normalized, mono WAV | Verify source license |
| `stage_gong.wav` | `cartoon_music-gong-hit-large-amp-resonate-504492.mp3` | Trimmed/capped, normalized, mono WAV | Verify source license |
| `bone_break.wav` | `universfield-bone-break-2-140224.mp3` | Trimmed, normalized, mono WAV | Verify source license |
| `block_impact.wav` | `yodguard-shield_impact-6-382409.mp3` | Trimmed to 0.50 seconds, normalized, mono WAV | Pixabay Content License; Pixabay Sound Effects, creator yodguard, asset 382409; direct URL: `[Recover exact Pixabay URL for asset 382409]` |
| `parry_zoom.wav` | `emircanalp-zoom-sound-effect-125029.mp3` | Trimmed to 0.80 seconds, normalized, mono WAV | Pixabay Content License; Pixabay Sound Effects, creator emircanalp, asset 125029; direct URL: `[Recover exact Pixabay URL for asset 125029]` |

## Bonus and buff feedback

These files are kept separate from hit reactions. Bonus and buff sounds must not trigger the player scream or damage feedback.

| Processed file | Original source filename | Intended use | Processing status | License status |
| --- | --- | --- | --- | --- |
| `bonus_pickup.wav` | `benkirb-shine-2-268904.mp3` | Generic bonus collection | Trimmed/capped, normalized, mono WAV | Verify source license |
| `buff_shine.wav` | `alexis_gaming_cam-anime-shine-sound-effect-346114.mp3` | Positive buff activation | Trimmed/capped, normalized, mono WAV | Verify source license |
| `health_recovery.caf` | `yodguard-healing-magic-4-378668.mp3` | Health recovery after successfully eating food | Trimmed/capped, normalized, mono CAF | Pixabay Content License; Pixabay Music/Sound Effects, creator yodguard, asset 378668; direct URL: `[Recover exact Pixabay URL for asset 378668]` |

## Temporary generated placeholders

`Audio/hit_yelp_01.wav`, `Audio/hit_yelp_02.wav`, and `Audio/hit_yelp_03.wav` were generated locally with macOS text-to-speech for development testing. They are not derived from the MP3 sources and should be replaced by final voice recordings later.

## Background music

These music files were downloaded from Pixabay Music and are treated as game assets under the Pixabay Content License. They are not labeled as CC0 or public domain. The original MP3 files are preserved unchanged under `Audio/Music/` as compressed runtime candidates.

| Filename | Title | Creator | Pixabay asset ID | Source platform | License | Direct page URL |
| --- | --- | --- | --- | --- | --- | --- |
| `kulakovka-epic-beat-278463.mp3` | Epic Beat | kulakovka | 278463 | Pixabay Music | Pixabay Content License | `[Recover exact Pixabay URL for asset 278463]` |
| `aliabbasabasov-epic-heavy-type-beat-rap-instrumental-prod5xbeatz-524490.mp3` | Epic Heavy Type Beat Rap Instrumental Prod5xbeatz | aliabbasabasov | 524490 | Pixabay Music | Pixabay Content License | `[Recover exact Pixabay URL for asset 524490]` |

## Processing notes

- Runtime WAV files are PCM 16-bit, mono, 44.1 kHz.
- The fire loop is CAF, PCM 16-bit, mono, 44.1 kHz.
- Levels were normalized with a true-peak ceiling target below 0 dBFS.
- The Molotov glass and explosion remain separate so gameplay can delay the explosion.
- The processed files are not integrated into gameplay yet.
