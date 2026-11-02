# Mistpad

A standalone handheld window interface for World of Warcraft, targeting the Steam Deck's 1280×800 touchscreen. Development targets Retail first, followed by a WoW: Forever compatibility pass after its planned 4 November 2026 release. No WoWU dependency, companion application or external art package. Disable WoWU when using Mistpad.

## Version 1.0.1

Fixed CurseForge packaging: addon files and Mistpad.toc now live at the repository root, and `.pkgmeta` packages them directly as `Mistpad`. No addon behavior changes. No tests run.

## Version 1.0.0

Retail v1.0 build with the established fixed window scales, edge gestures, single-row menu and touch-friendly bags. The Bags title is centered inside the top bar, and cleanup is at the upper left above the item grid. No tests run; live testing is handled by the user.

## Version 0.10.29 — Professions, Contacts and clean gestures

Fixed Professions scaling is 105%; Contacts (FriendsFrame) is 130%. Removed the center-screen gesture prompts, yellow edge guide lines and temporary gesture tint. Invisible touch areas and slide interactions remain active. No tests run.

## Version 0.10.28 — scale before side gestures

Side windows now finish fixed scaling before their gesture captures dimensions, then retain that viewport-fitted scale throughout the slide and while open. This removes the post-slide resize. The right-side map inset is reduced to 24 scaled units plus four units of clearance, without measuring tabs against transient frame positions. Map/Quests remains 110%. No tests run.

## Version 0.10.27 — fit Talents and expose map tabs

The Spells/Talents outer window now limits its 110% preference to the available viewport, with room for the bottom tabs; its initial native scale can be captured before Blizzard fits the window to the screen. Size changes reapply this limit. The talent canvas remains 200% and internal touch layouts remain unchanged. Map/Quests is 110%. A right-edge map slide reserves space for the protruding quest tabs plus an eight-unit gap. No tests run.

## Version 0.10.26 — fixed window scales

Removed the Scaling settings interface and retired saved developer overrides. Fixed defaults are centralized in `Mistpad/ScaleDefaults.lua`: Spells and Talents 110%, talent canvas 200%, Character 145%, Map/Quests 115%, Guild and Communities 125%, Group Finder 130%, Collections 115%, Adventure Guide 115%. Unlisted native windows use their original scale. Talent scrolling and separate class/spec pages are enabled; Ctrl-wheel no longer changes the fixed canvas size. The finished Spellbook/Talents artwork, internal touch sizing and layout remain unchanged. No tests run.

## Version 0.10.25 — menu hover and Contacts artwork

Menu buttons retain their normal artwork on mouseover and show a separate yellow glow. Contacts uses Blizzard's blue Battlenet portrait silhouettes over the same native micro-button background as the other buttons, without the circular gold portrait border. No tests run.

## Version 0.10.24 — menu and side-panel options

Customer Support becomes Contacts in Mistpad's menu, with a Friends icon and the native Friends window. Side Panels now offers all menu destinations except Settings and Shop, plus World Map, in scrollable Left/Right columns. Scaling opens Blizz Frames directly; the deferred custom Professions category is removed. Game Menu opens through a secure call to Blizzard's GameMenuFrame_Show instead of the direct ToggleGameMenu path. No tests run; the reported blocked-action popup needs live rechecking.

## Version 0.10.23 — single-row menu

Top-menu buttons always occupy a single row. Tiles scale uniformly when needed to fit the available screen width, preserving artwork proportions. Includes the return to Blizzard's original Character panel. No tests run.

## Version 0.10.22 — restore Blizzard Character

Removed the custom Character panel and its dedicated scaling controls. Character opens Blizzard's original window from the left-edge gesture, Mistpad menu and slash commands; the standard Character keybind uses Blizzard's own handler. Overall Character scaling remains under Scaling → Blizz Frames. Retired custom scaling values are cleared on login. No tests run.

## Version 0.10.21 — header finishing adjustments

Moved the unchanged-size X five units right, increased the centered title font from 20 to 23, and extended the native nine-slice's left boundary by 16 root-frame units to cover the content edge. Content dimensions and talent positioning remain unchanged. No tests run.

## Version 0.10.20 — consistent chrome and centered talent actions

The native non-portrait nine-slice now scales as one complete layout instead of separately stretched top pieces, keeping the side/corner joins consistent. Header height is derived from the unchanged X size plus 12 units. The X is centered on a fixed-size, non-interactive target inset from the root's top-right corner. Apply Changes and reset/undo share a centered footer group; the left search field fits before that group. Content dimensions remain unchanged. No tests run.

## Header alignment

The Spells window title now has equal left/right insets, centering it on the whole window. The unchanged-size red X anchors to that same title area's vertical centre instead of duplicating a vertical offset in a differently scaled button. Content dimensions and window scale remain unchanged. No tests run.

## Plain Spells window corner

Removed the Spells window's portrait and replaced its nine-slice portrait corner with Blizzard's normal metal top-left corner. Both top corners use the enlarged header treatment. The existing-size red X is anchored by its right edge eight units inside the window, rather than using a scale-divided centre offset that let it escape. Native content dimensions and the 110% window default remain unchanged. No tests run.

## Header thickness and portrait alignment

Added 12 UI units to the native header height while preserving the existing red X and maximize/minimize sizes. The portrait container scales its icon and mask together; the native portrait corner uses the same proportional size and anchor offsets. The outer window accommodates the additional height without shrinking content. No tests run.

## Native enlarged header, preserved content

Removed the added title-bar frame. The original PlayerSpells nine-slice top edge and top-right corner are enlarged in place, with the larger native close/maximize controls retained. The outer window gains the extra header height; Specialization, Talents and Spellbook keep their native content dimensions rather than being shortened. The 110% default and swipe changes remain. No tests run.

## Spells window finishing adjustments

The outer Spells and Talents default is now 110%; upgrading selects that default once, and future manual overrides remain available. The title bar is portrait-height, with larger title text, close and maximize/minimize controls, while the content shifts down to leave room. Spellbook swipes now detect the parchment by its screen rectangle and accept outer-window background focus, instead of requiring focus on the paged grid. Mouse-up detection has a held-button fallback, without prematurely cancelling touch inputs that do not report a held button. No tests run.

## Specialization and Spellbook touch sizing

Talent-page centering now measures the rendered visible nodes against the viewport after layout, correcting their actual on-screen offset rather than relying only on trait coordinates. Specialization yellow text, role/sample icons and Activate buttons are enlarged. Spellbook pages scale their native contents 1.35× inside the same parchment area and reflow to two columns with native pagination. Mage/General category tabs and page controls are enlarged. Horizontal swipes over parchment/text change pages, while icons retain native casting and action-bar dragging. No tests run.

## Talent positioning and touch controls

Resets the saved outer Spells and Talents window scale to native 100% once, preserving canvas zoom. Selected-page centering now ignores nodes hidden by Blizzard, with a centered horizontal starting position when scrolling is needed. The first node reserves space for the top selectors, a gap and its enlarged radius. Removed the added bottom-right navigation pad; wheel and empty-space dragging remain. Enlarged bottom-left native tabs and the loadout/search/apply/reset/undo controls, with footer anchors adjusted for the larger sizes. No tests run.

## Separate class/spec talent pages

The native Talents tab now has class and current-specialization page buttons (for example Mage / Arcane). One branch is visible and centered at a time; the current talent canvas zoom and scrolling work within the selected branch. Native talent data, purchase and commit handlers remain intact. Scaling → Blizz Frames → Spells and Talents includes a Separate class / specialization pages toggle to return to the original side-by-side layout. Inspection remains native. No tests run.

## Talent canvas scale and scrolling

Scaling → Blizz Frames now includes Talent canvas size and Talent scrolling/panning beneath Spells and Talents. Canvas scaling covers 50–200% separately from the surrounding window, using Blizzard's native talent zoom/pan methods. Wheel scrolls vertically, Shift-wheel horizontally, Ctrl-wheel adjusts the saved canvas scale, and dragging empty tree space pans. Native-art directional controls and a return-to-origin button are provided inside the tree. Node purchase, choice and commit handlers remain native. Settings persist; combat defers changes. No tests run.

## Native Blizzard window scale experiment

Settings → Scaling → Blizz Frames adds independent whole-window percentages for Character, Professions, Spells and Talents, Achievements, Quests, Guild and Communities, Group Finder, Collections and Adventure Guide. Controls cover 50–200% in 5% steps, with numerical inputs, individual resets and a category reset. Saved values apply to loaded native windows, reapply on opening, and wait until combat/gestures finish. Quests shares its native frame with World Map. Use `/mistpad character original` to preview native Character, since ordinary Character bindings open Mistpad's replacement. Blizzard scaling refusals appear beside the relevant control. No tests run.

## Scaling categories

Settings → Scaling now opens category buttons for Character and Professions. Character retains its existing controls. Professions contains one saved Frame size preference (75–150%, 5% increments, numerical input and Reset), reserved for the future Professions module; it does not change Blizzard's native profession window. Back buttons return to the category menu. `/mistpad scaling` opens this same menu. No tests run.

## Equipment alignment and Reputation layout

Equipment columns now anchor symmetrically to the model inset, including their decorative borders, and the two weapon slots are centered as a pair. Reputation/Currency categories use plain bordered rows rather than stat-header ornaments. Reputation factions are indented, with standing text inside right-aligned progress bars instead of thin underlines. No tests run.

## Border rendering correction

Removed the nine-slice layout that produced oversized black/metal strips in game. All owned Character frames now use a consistent fixed-size Blizzard tooltip-border backdrop. Corrected stat-header atlases, restored bottom buttons and the raised portrait layer are retained. No tests run.

## Header art, corners and layering

Restored the previous bottom-tab buttons. Atlas textures now use the native coordinate-reset option instead of applying sheet coordinates twice. Native nine-slice layouts replace the hand-cropped frame borders, and the portrait/ring render on a separate non-interactive layer above the title bar. No tests run, per the user's preference.

## Confirmed opening error corrected

The in-game error identified `SetNormalTexture(nil)` during sidebar creation. Sidebar and model buttons now hide unwanted existing texture regions with alpha instead of passing nil to button texture setters. Opening diagnostics remain enabled. No tests run, per the user's preference.

## Opening diagnostics and safe artwork fallback

Character opening now catches and reports the exact failing stage and Lua error in chat, including repeated attempts after an incomplete build. Invalid/missing atlas metadata falls back to ordinary textures instead of blocking construction. Native binding, menu and gesture entry points share the same guarded opening path. No automated or in-game tests were run for this build.

## Character opening correction

Removed the native bottom-tab template and selection-helper dependency introduced in 0.10.2. Plain Mistpad-owned buttons now display the same native active/inactive tab artwork, without Blizzard mixin/parent assumptions. This build has not been tested; replace the addon folder and reload before checking it in game.

## Closer native Character styling

Corrected the stat-header atlas crop, centered white category captions and item-level number, white stat values, native bottom-tab artwork, image-based model controls and sidebar icons without red button faces. The character backdrop now uses Blizzard's original quadrant proportions/crops and racial dimming. These changes follow the in-game screenshot comparison; another Retail visual pass is still needed.

## Character interaction and artwork polish

Scroll arrows now use Blizzard textures with pressed/disabled states, and hide when unnecessary. Equipment slots are inert outside Equipment Manager. In Equipment Manager, every occupied slot offers **Unequip** first; it moves the item to an empty regular bag slot and refuses when bags are full or the item/cursor state changed. The panel also uses native metal edging, a portrait bezel/mask, paper-doll slot ornaments and the native ornate stat-header art. See [art references](docs/CHARACTER-ART.md).

## Custom Character panel

Character is now a Mistpad-owned window, following the supplied Blizzard screenshots: a live player model with surrounding equipment, Stats/Titles/Equipment Manager on the right, and Character/Reputation/Currency tabs below. Native APIs provide data, inventory actions, comparisons, titles, equipment sets, reputations and currencies. Protected Blizzard Character frames are not resized or reparented.

The Character-assigned edge, top-menu Character tile and recognised native Character bindings open the replacement. Use `/mistpad character original` for Blizzard's fallback. Touch outside or press Escape to close; the panel slides back toward its edge. The persistent gameplay HUD remains unchanged.

The old Developer Scaling editor and native-frame scaling framework have been removed. **Settings → Character Scaling** now contains ten focused controls for this custom panel: overall size, equipment slots, model area, general text, buttons, tabs, tab text, stat text, row height and tooltips. Values apply live, reflow layout and persist between sessions. See [Character behavior and known differences](docs/CHARACTER.md) and [scaling controls](docs/SCALING.md).

This is the first custom Character build. Model framing, texture alignment, restricted actions and physical touch still require Retail testing. Advanced native features not yet recreated are documented; use the original fallback for them.

## Existing modules

- Four 64-unit edge interaction bands, excluding corners. Touch reveals a 32-unit peek; pull inward and release after 64 units to snap open. Short pulls retract. The user has confirmed these gestures work on Steam Deck.
- Bottom: unified carried bags using native combined-bag item buttons. Small/Medium/Large layouts, dynamic contents, item size, optional search, row caps and opening anchor.
- Stationary item holds open a persistent touch context menu. Native Use/Equip, Split, Drop confirmation, Compare, Preview and eligible processing actions are supported. Quick swipes scroll; a shorter hold followed by movement drags an item.
- Top: enlarged native micro-menu artwork and labels, with Settings routing to Mistpad's options.
- Left/right: choose Character, Quests or World Map under Settings → Side Panels. Character defaults left; Quests defaults right. Map and quests retain Blizzard's actual shared map frame and functionality.
- Touch outside and Escape dismiss windows. No custom close buttons. Native fallback geometry is restored when a native managed window closes. Combat closes custom panels and gates window/item changes.

## Install

Copy the inner `Mistpad` folder from the ZIP into Retail's `Interface/AddOns/`. The resulting path must be `Interface/AddOns/Mistpad/Mistpad.toc`. Disable WoWU and enable Mistpad. Combined bags must be enabled for the inventory module. Interface metadata is provisional; report `/mistpad status` if the client marks the addon out of date.

Commands: `/mistpad`, `/mistpad character`, `/mistpad character original`, `/mistpad scaling`, `/mistpad bags`, `/mistpad inventory`, `/mistpad gestures`, `/mistpad animation`, `/mistpad status`.

## Development and validation

`CharacterData.lua` reads native data and item alternatives. `CharacterPanel.lua` owns the Character UI, actions, native binding routing and event-driven refresh. `CharacterSettings.lua` centralises its defaults and scaling controls. The panel never searches every Blizzard window or exposes per-object frame trees.

`NativePanels.lua` and `Gestures.lua` share edge movement across native bags/maps and the owned Character panel. `Inventory.lua` adapts native combined bags; `MicroMenu.lua` copies bounded native button art. Textures and fonts reference the installed client.

Automated Lua mocks cover gestures, native restoration, bags, item actions, close animations, micro-menu routing, and the new Character panel's data/actions, bounded rows, mixed scaling extremes, combat deferral and native binding semantics. They pass locally, but do not substitute for Retail visual/protected-action checks. See [the testing checklist](docs/TESTING.md).
