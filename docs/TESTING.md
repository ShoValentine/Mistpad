# Retail acceptance checklist

Record `/mistpad status`, screen resolution, UI scale, bag sizes, and other enabled addons with each test. Test at 1280×800 first. Enable Lua errors with `/console scriptErrors 1`.

## Startup and menu

- Version 0.7.1: inspect Customer Support with and without a pending support alert, hover/press it, open/close the top menu, and verify no red/oversized artwork covers the title or adjacent buttons. Its native Help action must still work. Check all captions for truncation. The automated micro-menu regression includes oversized root and child support textures and verifies they are excluded while the native support icon is retained.

- Version 0.7 supersedes earlier X/cog checks: bags must have no close button, cog, or helper text. Micro menu, Settings, Bag Options, item context menu, and split selector must have no Close/X control. Touch outside and Escape must dismiss each; fallback Blizzard windows keep their native controls.
- Inspect the top panel at 1280×800: native micro-button artwork is enlarged, labels fit, and native button order/availability match the client's menu. Check character portrait/mask, pressed/highlight/disabled states, guild emblem, notification artwork, and wrapped layouts on narrower screens. Confirm HUD button size, parent, placement and bindings remain unchanged.
- Try every available micro action. Check level/faction/account restrictions, disabled buttons, and first-use lazy-loaded windows. The Settings tile opens Mistpad Settings; Bag Options must be accessible with bags closed, retain every saved option, and dismiss by touching outside. Game Menu opens Blizzard's own game menu.
- Pull down slowly: initial peek, finger tracking and release snap must remain unchanged. Tap a tile during a drag/snap: it must not activate. Close by outside touch, Escape, the menu bind, or selecting a tile; the panel must slide upward. Reopen mid-close and verify no ghost or invisible click area remains.

- Install with only Mistpad enabled. Login and reload without Lua errors.
- `/mistpad` opens a readable menu; all buttons fit and work; Escape closes it.
- Assign both Mistpad keybinds. Confirm existing bag bindings still work.
- Test all six shortcuts, including the lazy-loaded Spellbook on first use.
- Enable WoWU alongside Mistpad and confirm Mistpad declines to initialize (verify the installed WoWU folder identifier).

## Native Inventory adapter

- Version 0.6: set Max Height to 1, 3, 8 and 16. Count visible rows in every bag size and at multiple item scales; overflow must remain scrollable. A high cap must still fit the screen. Reload to verify persistence.
- Select Left, Middle, Right. Test both normal bag binds and a bottom-edge pull: the bag must use the selected horizontal alignment throughout peek/drag/snap. Check both narrow and full-width layouts.
- Verify the larger X and cog do not overlap each other or the title/search. Touch the world, HUD, another native window, options, and item-menu buttons. Outside touches close the bag; touches inside any bag sub-panel must leave it open.
- Close with X, outside touch, Escape, the native bag bind, and the Mistpad Inventory bind. Verify slide-down from the current anchored position, no flash of the original layout, no invisible hit boxes, and immediate logical closure. Reopen before the close animation finishes. Repeat with animations disabled and during combat.
- Open the hold menu and release, including dragging slightly after the menu appears and any duplicate touch-generated release events. It must remain open without using/picking up the item. Wait through cooldown/money/search refreshes; the menu must stay open if the selected item/stack is unchanged.

- Version 0.5: verify Dynamic Contents hides every empty slot, including reagent-bag slots, and compacts remaining items without changing their bag/slot identity. Remove the last item and verify an empty grid. Toggle back to show all empty slots.
- Adjust Item Size from 32 to 80 in each layout. Check icon, border, count, cooldown, pointer hit box, scrolling, and Large column fitting. Confirm the options stay stationary as the bag resizes underneath them.
- Search must start off, with a shorter header. Enable it, search, then disable it: search text/filter clears and all items return. Reload to verify all options persist.
- Hold still for 1.5 seconds: the context menu appears beside the item with large buttons. The release must not activate any action or pick up the item. Change hold time and repeat. Quick scrolling, diagonal motion, and item movement must cancel the menu timer.
- Test consumables, equippable gear, single items, stacks, locked items, quest items, herbs, ore, and stones. Check profession actions with and without the matching profession, sufficient stacks, and relevant expansion skills/recipes. Open the profession first if Retail has not loaded its recipes. Disabled actions must explain the missing requirement.
- Use, Equip, Compare, and Preview must target the selected item. Split must allow a touch-selected amount and leave the result on the cursor. Drop must show a stack-deletion confirmation; cancel it and verify nothing is deleted.
- Move/replace/split a stack while its menu or drop confirmation is open; stale actions must refuse to act on its replacement. Enter combat with both the context menu and split selector open, close bags, and press Escape. No protected-action errors or lingering menus should occur.

- Open the top-right cog and select Small, Medium, Large. Verify exactly 4 and 8 columns for the first two; Large must span the available width with the maximum fitting columns. Change sizes while scrolled and confirm scroll resets safely. Reload and verify the choice persists.
- Test native portrait, close, search, sort, quality borders, stack counts, cooldowns, money and tracked currencies in each size. Test with 0 slots, full bags, upgraded backpack slots, and reagent bags equipped/unequipped/replaced.
- Drag quickly over an item to scroll without picking it up. Hold 0.45 seconds then drag to move it. Tap, right-click, shift-click, split stacks, and drop cursor-held items after scrolling. Check a fast press/move/release between frames, and drag at the start/end of the scroll range.
- Verify reagent slots appear once in the unified grid; the native reagent window must not leave an invisible input-blocking rectangle. Switch back to individual bags and verify reagent window visibility and input return.

- Enable combined bags, open through the bag binding, bag HUD button, and menu.
- Verify opening animation and final position with empty and full bags, reagent bag, different bag sizes, and screen/UI-scale changes.
- Search, sort, hover tooltips, use an item, equip, drag between slots, split a stack, and link an item into chat.
- Test vendor selling/buyback, mail attachments, bank transfers, and trade using low-value items.
- Toggle `/mistpad inventory` while bags are open and closed. Original scale/placement must return; re-enabling must fit correctly.
- Disable combined bags: original individual windows must remain usable.
- Open bags during combat and enter combat during an opening animation. Confirm no blocked-action warnings, continuing anchor animation, or item interaction regressions.

## Gestures and input

- Version 0.8 defaults supersede the old map/quest mappings: left opens Character, right opens Quests. Verify the quest tracker stays untouched. Use Settings → Side Panels to assign Character, Quests, or Map to either side, including the same target on both sides. Reload and verify persistence and updated gesture feedback.
- Change assignments after opening/closing a side panel repeatedly. Confirm the new target has a working input shield during the drag and normal interaction after snapping open. Test swapping Character and Map on one edge, then opening the other edge; closing an old frame must not affect the new target.
- Native side-window close controls must disappear while gesture-managed, outside touches must close the panel, and its closing animation must travel to the correct side. Open each window through its normal binding afterwards and verify original controls, scale and positioning return.

- Version 0.3: repeat the top-menu drag tests for bottom Inventory, left quests, and right map. Each edge has a 64-unit input band with 64-unit corner exclusions. Confirm a 32-unit initial peek, continuous movement, and correct snap direction.
- Close each native window after a committed pull, then reopen with its normal binding. Confirm original scale/anchors return. Try both minimized and maximized map modes, quest selections, map markers, and map zoom after snapping open.
- During native-window drag/snap, clicks and scroll input must not activate underlying window controls. After snapping open, native controls must work normally.

- Top menu: touch anywhere in the top 64 UI units where HUD controls do not overlap. A 32-unit menu strip must appear immediately. Drag down slowly: the menu must follow continuously, stop at its open position, and have no clickable buttons while dragging.
- Release before 64 units of travel: retract and hide. Release after 64: snap open and enable buttons. Reverse before releasing, drag sideways, press Escape, disable gestures, and enter combat during a pull; confirm cancellation and no stuck menu.
- Test with animations disabled: finger tracking must still work, and release must resolve immediately.

- Gestures start enabled on a fresh install. Drag inward from each edge and release. Verify the four intended destinations and live release/cancel feedback.
- Short drags, outward drags, diagonal motion, and ordinary clicks must not open windows.
- Release outside a handle, disable gestures mid-drag, and enter combat mid-drag. No delayed action should fire.
- Disable gestures; confirm all four handles vanish and the HUD remains unchanged.
- On Steam Deck, test physical touch, mouse emulation, and gamepad cursor separately. Record which input modes deliver press-and-drag events. Custom directional focus navigation is not implemented yet.

## Persistence and migration

- Toggle all settings and reload; verify they persist.
- Retest with the normal addon set and record any bag/layout conflicts.
- On 4 November, capture Forever's `GetBuildInfo()` output and API/frame availability before changing the adapter or TOC. Repeat this checklist against that client; do not infer compatibility from the release name.

## Automated checks

`tests/test_gestures.py` runs the actual gesture module in a Lua runtime with simulated WoW input. It checks four directions, release-to-commit, single firing, short/outward/sideways cancellation, combat cancellation, disabling mid-drag, and UI scaling. It also compiles every addon Lua file. These checks pass; they do not substitute for native input or in-game validation. The development runtime is not shipped with the addon.

`tests/test_inventory.py` checks the actual layout calculations at multiple widths and exercises the bag module with simulated frames: unified slots, cog choices, scrolling, tap/hold/fast-release handling, cursor-held drops, and restoration/reopening. `tests/test_native_panels.py` checks the three native drag adapters. These pass locally; game restrictions, appearance, and physical touch input still require Retail testing.

`tests/test_item_context.py` checks action selection, profession gating, secure button attributes/handler preservation, split controls, compare/preview dispatch, discard confirmation, stale GUID/stack protection, and hold-release suppression. The inventory tests also cover dynamic compaction, search visibility, item scaling, and configurable hold detection. These use simulated APIs; they cannot validate secure execution or profession casts inside WoW.

The version 0.6 checks add row caps, all three opening anchors, larger X, outside-touch routing, and menu persistence across release and ordinary refreshes. `tests/test_bag_closing.py` checks the close renderer's trajectory, scroll clipping, input passthrough, object reuse, and cancellation/combat gates. Visual fidelity and actual input routing remain in-game checks.
