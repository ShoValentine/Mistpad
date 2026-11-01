# Mistpad

A standalone handheld window interface for World of Warcraft. Development targets **Retail first**, followed by a WoW: Forever compatibility pass planned for **4 November 2026**, once its client is available. No WoWU dependency or companion application.

## Version 0.8.0 — configurable side panels

The left edge now opens **Character**, and the right edge opens **Quests** by default. **Top Menu → Settings → Side Panels** lets each edge choose Character, Quests, or World Map independently; choices persist after reload. These are the currently supported targets. Quests and map share Blizzard's native Map & Quest Log frame on Retail, so that frame is opened in the chosen mode rather than duplicated.

Side panels retain native functionality, the immediate peek, finger-following pull and snap. Touching outside dismisses them with an animation toward their originating edge. Native close buttons are hidden during a Mistpad side-panel session and restored with the original scale/anchors when it closes. Changing an assignment closes active side panels before applying the next target.

Moved captions closer to the button art, aligned text to the top of its label area, and shortened each row by another 24 UI units. The artwork stays at the same size and proportions. A one-row menu is now 192 UI units tall.

Removed the Mistpad title from the top menu and reduced outer vertical padding to 12 units on each side. A one-row menu is now 216 UI units tall instead of 292. Artwork remains at 2× scale, with the same icon clipping area, touch targets, and label space.

Micro-button artwork now copies only known button surfaces and bounded notification textures, instead of traversing arbitrary child frames. Each enlarged icon has its own clipped artwork area, preventing Customer Support alerts or other oversized regions from spilling into neighbouring buttons. Labels use shorter captions, wrapping, and more vertical space.

Pull from the top edge to reveal an enlarged version of the client's micro menu. It uses the native button artwork at 2× scale, including the character portrait and normal/pressed/highlight/disabled states, with large touch areas and labels. Entries follow the current client's micro-button list and restrictions; narrower screens wrap into additional rows. The persistent HUD micro menu is not moved or resized.

The **Settings** micro button opens **Bag Options** and **Game Menu**. All bag settings now live in this independent Settings panel, accessible without opening bags. The bag has no cog, close button, or helper text, and its header is shorter. Mistpad panels and the item context menu have no explicit Close/X buttons; touch outside or press Escape to dismiss them. Blizzard's original windows retain their controls in fallback mode.

**Max Height (rows)** caps the number of visible item rows (1–16, default 8), with scrolling for the remaining contents and a further cap to fit the screen. **Anchor** selects Left, Middle, or Right along the bottom edge (default Middle), for both normal opening and bottom-edge pulls.

Touching outside the bag closes it, including touches on other UI; options, item menus, split selectors, and drop confirmations count as part of the module. Closing slides bags down and the micro menu up to their originating edges. Blizzard's actual bag close completes immediately, including native keybind bookkeeping. Reopening cancels an unfinished slide-out; closing during combat is immediate.

The hold menu now stays open after release and ordinary bag refreshes. Its opening release (including duplicate touch-generated clicks) cannot use or pick up the original item. Choosing an action, explicitly dismissing the menu, closing the bags, entering combat, or changing the selected item/stack dismisses it.

## Bag settings and item actions

Bag Options includes **Dynamic Contents** (hide all empty slots), **Item Size** (32–80 UI units), **Search Bar** (off by default), and **Hold for menu** (0.5–3 seconds; default 1.5). These settings persist after reload. Disabling search clears the active search and reclaims its header row. Small and Medium retain 4/8 columns as item size changes; Large recalculates how many columns fit.

Hold still over an item to open a touch-sized context menu beside it. Available actions include Use, Equip, Split, Drop, Compare, Preview, Disenchant, Mill, and Prospect, based on the item, stack, and learned professions. Split opens an amount selector; Drop asks for confirmation before deleting the entire stack. A quick swipe scrolls; holding 0.45 seconds and then moving still picks up the item. Holding without moving until the configured delay opens the menu and consumes the original release.

Use/Equip and legacy processing spells use Blizzard's secure action buttons. Modern processing uses a learned salvage recipe that explicitly accepts the selected item. Some Retail processing recipes are only exposed after opening the corresponding profession; unavailable actions show an explanation. Blizzard enforces final skill, expansion, target eligibility, and reagent requirements. Context menus close in combat, and item identity/stack changes invalidate pending actions and discard confirmations.

The bag module keeps Blizzard's frame, portrait, fonts, item buttons, quality borders, search, sort, and money display. Settings → Bag Options offers three saved size choices:

- **Small:** 4 columns, vertically scrollable.
- **Medium:** 8 columns (444 UI units wide, about one third of a 1280-wide UI).
- **Large:** full available width with 24-unit side margins and as many 48-unit item columns as fit.

All carried bags, including the reagent bag, appear in one grid, ordered by bag and slot. Drag up/down over items or empty grid space to scroll; wheel and scrollbar also work. Tap retains the native item action. Hold for at least 0.45 seconds before dragging to move an item. Modified clicks and cursor-held items keep their native behaviour. The native bag portrait still provides Blizzard's filtering/sorting options. Medium is the default; settings persist after reload.

All four interaction bands are 64 UI units deep (excluding corners). Touch immediately reveals a 32-unit strip of the destination panel; dragging inward pulls it one-to-one. Release after 64 units of inward travel to snap open, or release earlier to retract. Native controls become interactive after the opening snap finishes. Escape, combat, and disabling gestures cancel an active pull. Inventory requires combined bags and enabled Inventory presentation. Retail quests and map use Blizzard's shared Map & Quest Log window, opened in the corresponding mode from opposite edges. Native window scale, clamping, and anchors are restored on close.

- Enlarged Blizzard micro menu with native artwork and a Settings entry.
- Shared opening animation and Escape-to-close menu support.
- Responsive unified bag grid presented from the bottom, using Blizzard's actual item controls.
- Existing bag keybinds continue to open Blizzard's bags with Mistpad presentation.
- Four edge gestures enabled by default: bottom → bags, top → menu, left → native quests, right → native map, with drag feedback and release-to-open.
- Saved Inventory, gesture, and animation switches; original bag presentation can be restored.
- No persistent HUD changes. Only small optional gesture handles appear at the middle of each edge.

This is the first development slice, not the complete window redesign. Other menu entries open native windows. Continuous drag-to-open and release snapping work on all four edges. Long-press tooltips, inertial scrolling, gesture remapping, controller focus navigation, and the remaining replacement windows are future work. Mouse-based swipe recognition requires hardware testing; direct multitouch input is not assumed.

## Install for Retail

1. Copy the inner `Mistpad` folder into your Retail installation's `Interface/AddOns/` folder. The resulting file must be `Interface/AddOns/Mistpad/Mistpad.toc`.
2. Disable WoWU; the addons are alternatives. Mistpad checks the addon identifier `WoWU` at login and declines to start if it is enabled.
3. Enable Mistpad in the character-selection AddOns list. If the client marks it out of date, enable “Load out of date AddOns” for this development build and report `/mistpad status` so the interface metadata can be updated.
4. Enable Blizzard's **combined bags** option. Individual bag windows are intentionally left native in this prototype.
5. Log in and type `/mistpad`. Set menu and Inventory bindings in the game's Key Bindings interface.

Commands: `/mistpad bags`, `/mistpad inventory` (toggle presentation), `/mistpad gestures`, `/mistpad animation`, `/mistpad status`, `/mistpad help`.

Gestures are enabled by default. Press in the outer 64 UI units of any edge, drag inward at least 64 UI units, and release to open. Gold handles mark each edge. Short, outward, and predominantly sideways drags cancel; the centre label shows whether release will open the window. The outer 64-unit corner squares are excluded to avoid ambiguous directions, and overlapping higher-layer HUD controls retain input priority. `/mistpad gestures` is a fallback switch for troubleshooting. Opening/repositioning Mistpad windows is blocked during combat; native bag binds remain under Blizzard's control.

## Architecture

`Core.lua` owns startup, saved settings, commands, and combat gates. `Panels.lua` owns panel styling and animation. `InventoryLayout.lua` calculates bag geometry. `Inventory.lua` reflows native combined-bag buttons into a scroll canvas and adds reagent-slot buttons from Blizzard's template. It wraps click/drag scripts to distinguish scrolling from item movement, and restores native parents, geometry, and scripts on close or fallback. Global bag functions remain intact. `NativePanels.lua` adapts native Inventory and Map & Quest Log windows to the shared gesture contract. `MicroMenu.lua` reads native micro-button entries and artwork; `Menu.lua` owns the top sliding panel; `Settings.lua` routes Bag Options and Game Menu. `Gestures.lua` handles optional edge input. `Bindings.xml` declares assignable actions.

No external libraries, copied WoWU code, or packaged Blizzard art files are required. Textures and fonts reference the installed game. Blizzard API reference checked against the [live UI source](https://github.com/Gethe/wow-ui-source/tree/live/Interface/AddOns/Blizzard_UIPanels_Game/Mainline).

## Validation

See [the in-game checklist](docs/TESTING.md). No WoW client or Steam Deck is available in this workspace, so visual layout, restricted-action behaviour, and touch/controller support are **not yet verified in game**. The TOC interface list is provisional, not a claim that each client build has been tested.



