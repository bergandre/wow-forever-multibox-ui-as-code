# Razorfen Kraul (Horde) - quest notes

Southern Barrens / Thousand Needles border. Min levels per guides: 20-30 (sources disagree, beta vs live).

## Before you go
- **Ratchet** - Mebok Mizzyrix (Barrens 62.37,37.62): accept **Blueleaf Tubers**, then grab the 3 items
  from objects right in front of the building: **Crate With Holes**, **Snufflenose Command Stick**,
  **Snufflenose Owner's Manual** (read it). Without the crate + stick the quest can't be done.
- **Thunder Bluff** - Auld Stonespire (36.02,59.88, Lower Rise, inside building): **A Vengeful Fate**.
- **Undercity** - Master Apothecary Faranell (Apothecarium 48.81,69.30): **Going, Going, Guano!** (lvl 30).
- **Warrior only** - **Brutal Armor** chain: Sorek (Valley of Honor, Orgrimmar) -> Ruga Ragetotem
  (Camp Taurajo) -> 5 Twitching Antenna (silithids south of Taurajo) -> Thun'grim Firegaze (hills east of
  Crossroads). Needs Vial of Phlogiston from **Roogug** inside RFK, plus 10 Iron Bar, 10 Powdered Azurite
  (Hillsbrad miners), 15 Smoky Iron Ingot (Windshear kobolds, Stonetalon). Zygor skips this one.

## Inside
1. Kill **Roogug** (warrior: Vial of Phlogiston).
2. After **Overlord Ramtusk**: go SW over the bridge to the small platform between two bridges -
   use Crate With Holes (gopher), then Command Stick on it, click 6 **Blueleaf Tuber**.
3. **Kraul Bats / Greater Kraul Bats** (after Ramtusk) -> Kraul Guano.
4. **Charlga Razorflank** (last boss) -> Razorflank's Heart + **Small Scroll** (use it -> **An Unholy Alliance**).
5. **Willix the Importer** - tent left of Charlga's platform (jump down). Escort to the entrance;
   turn in to him there. Don't run ahead too far or it fails.

## After
- Ratchet: Blueleaf Tubers (bring tubers + stick + crate) -> gem container, Ratchet rep.
- Thunder Bluff: A Vengeful Fate.
- Undercity: Going, Going, Guano! (unlocks **Hearts of Zeal** for SM), An Unholy Alliance -> Varimathras (56.23,92.18).

## Quest table
| Quest | ID | Lvl | Giver | Notes |
|---|---|---|---|---|
| Blueleaf Tubers | 1221 | 20 (26?) | Mebok Mizzyrix, Ratchet | neutral, items next to NPC |
| Willix the Importer | 1144 | 22 | Willix, inside | neutral, escort |
| An Unholy Alliance | 6522 | 28 | Small Scroll (Charlga) | not shareable |
| A Vengeful Fate | 1102 | 29 | Auld Stonespire, TB | |
| Going, Going, Guano! | 1109 | 30 | Faranell, UC | -> Hearts of Zeal |
| Brutal Armor | (verify) | 20 | Thun'grim Firegaze | warrior only, long chain |

## Check what's done (paste in chat)
```
/run for _,q in ipairs({1109,1221,1102,6522,1144})do local L=C_QuestLog print(q,L.IsQuestFlaggedCompleted(q) and "done" or (L.IsOnQuest and L.IsOnQuest(q)) and "log" or "-")end
```
Blueleaf Tubers can be done on a later run if you're still in level range.

## Sources
- Local Zygor: `ZygorDungeonHordeCLASSIC.lua` "Razorfen Kraul Quests"
- [Warcraft Tavern - Forever RFK quests](https://www.warcrafttavern.com/forever/guides/razorfen-kraul-quests/)
- [Method - Forever RFK](https://www.method.gg/wow-forever/dungeons/razorfen-kraul)
- [Wowhead - Blueleaf Tubers](https://www.wowhead.com/classic/quest=1221/blueleaf-tubers)
- YouTube transcripts: attempted, HTTP 429 on 2026-11-14.
