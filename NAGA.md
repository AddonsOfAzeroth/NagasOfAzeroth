# Razer Naga V2 Pro with Nagas of Azeroth

Source text for the manual. Nagas of Azeroth by DinX.

Nagas of Azeroth works on its own. Casters of Azeroth (rotation hint) and
Healers of Azeroth (hover keys) are optional: when they are loaded, Nagas works with them.

## 1. Pick the plate

`/naga` (or Esc > Options > AddOns > **Razer Naga**) > **Side plate**: None, 12 buttons, 6 buttons or 2 buttons.
The Naga bar, its keys and its pages change at once (after combat if you are fighting).
Type `/naga unlock` to drag the bar, `/naga lock` when done. Drag spells onto it like any action bar.

The panel shows a small picture of the plate with its keys. Commands: `/naga` or `/noa`
(settings), `/naga map` (the Naga map), `/naga test` (the test screen). `/coa naga` in
Casters of Azeroth still opens the test screen.

## 2. Keys Synapse should send per plate

Keep Synapse's defaults. As your thumb sees the plate:

| Plate | Row 1 | Row 2 | Row 3 | Row 4 |
|---|---|---|---|---|
| 12 buttons (3 wide, 4 high) | 1 2 3 | 4 5 6 | 7 8 9 | 0 - = |
| 6 buttons (2 wide, 3 high) | 5 1 | 6 2 | 7 3 | |
| 2 buttons | Mouse button 4 | Mouse button 5 | | |

Healers of Azeroth's click editor uses the same shapes and order.

Each button sends exactly one key. Do not map a button to a macro or a key sequence.

Note: the keyboard keys 1 to = and the Naga send the same keys. While the Naga bar
is on, those keys press the Naga bar, not your main action bar. The add-on tells you
in chat which keys it takes over; turn the Naga bar off and they go back.

## 3. Hypershift: Shift, Ctrl and Alt pages

In Synapse, set a Hypershift layer where each button sends **Shift + the same key**
(for example Shift + 7). Add more layers with **Ctrl +** and **Alt +** the same key if you want.

In the panel, **Shift, Ctrl and Alt: extra pages** must be on. Then:

- no modifier = page 1
- Shift = page 2
- Ctrl = page 3
- Alt = page 4

The labels on the Naga bar show the page you are on (S7, C7, A7).

### Blizzard's bar paging

Blizzard binds **Shift + 1 to 6** to its action bar pages (and Shift + mouse wheel to the
next/previous page). Pressed on the Naga, Shift + a side button would then switch your
main bar to another page. **Block bar-page switching on plate keys** (on by default) stops that
on the keys of your plate:

- Naga bar on with pages: Shift + key presses the Naga bar's Shift page.
- Pages off, or the Naga bar off: Shift + key does nothing.
- Keys that are not on your plate keep Blizzard's paging. Plate "None" or the option off: everything is as before.

The test screen and the Naga map show such keys in red: "Shift+1 switches your action bar page".

## 4. Healers of Azeroth: hover keys

With Healers of Azeroth loaded, the panel also shows its hover plate and its
**Shift, Ctrl and Alt** check. They are saved in Healers of Azeroth itself.
**Same plate for Healers** (on by default) keeps both plates the same: change one and the other follows.

## 5. Let Synapse switch to the WoW profile by itself

In Synapse, open the profile for WoW and link it to the game:
**Linked program: Wow.exe** (the WoW Forever client's executable).
Synapse then switches to this profile when the game window is active and back when you leave it.

## 6. Turn off repeat and turbo

For every button in the WoW profile: **Turbo off**, and no key repeat.
One press must send one key, once.

## 7. Never use multi-key macros

Do **not** use Synapse macros that send more than one key per press,
and no timed sequences. One press = one action. Anything else can count as
automation and put your account at risk of a ban. Nagas of Azeroth itself
never casts anything for you: it only shows which key to press.

## 8. Check the setup with /naga test

Type `/naga test` (or **Test screen** in the panel or on the Naga map). You see the grid of your plate.

- Press each Naga button: its cell lights up and shows the key that arrived (with Shift, Ctrl or Alt)
  and what it does now (the spell on the Naga bar, a Blizzard key binding, or "nothing").
- Mouse buttons 4 and 5: click them over the test window.
- A **red** cell: that key also has a Blizzard key binding (the Naga bar wins while it is on),
  or Shift/Ctrl/Alt + that key switches Blizzard's action bar page.
- **Not on the plate**: a key arrived that does not belong to your plate. Check Synapse's mapping for that button.
- Your keys keep working while the screen is open; it never casts anything. Esc or X closes it.
- The test screen opens out of combat only.

## 9. The Naga map

Type `/naga map` (or **Naga map** in the panel or the test screen). It shows your plate as a grid,
with a tab per layer: Plain, Shift, Ctrl, Alt. Each cell shows the key, an icon and what the key does:

- **blue**: the Naga bar slot (spell, item or macro);
- **green**: the Healers of Azeroth hover spell (while your mouse is on a group frame);
- **grey**: Blizzard's own key binding, when neither of the above applies;
- **red** edge: a clash (a Blizzard binding under a Naga bar key, or bar paging).

The map only shows; it never casts and can be opened at any time, also in combat.
Without Healers of Azeroth it shows the Naga bar and Blizzard's bindings only.

## 10. The rotation hint (Casters of Azeroth)

When the spell Casters' rotation helper suggests is on the Naga bar, the hint shows its Naga key big
under the icon (for example `7` or `Shift 7`) and that Naga button glows.
Turn it off with **Naga key in the rotation hint**.

## 11. Export for the website and printing

The same map is saved per character, so the Windows uploader can read it after `/reload` or logout:
`WTF\Account\<account>\<realm>\<character>\SavedVariables\NagasOfAzeroth.lua`, variable
`NagasOfAzerothCharDB.map`. It is refreshed out of combat when the bar, the bindings or the plate
change, and at logout.

```lua
NagasOfAzerothCharDB.map = {
  plate = "12",              -- "none", "12", "6" or "2"
  updated = 1763820000,      -- time() of the last refresh
  class = "SHAMAN",          -- class token
  layers = {                 -- [""] = plain, shift, ctrl, alt; only layers with cells
    [""] = {
      ["1"] = {              -- plate key: "1".."9", "0", "-", "=", "BUTTON4", "BUTTON5"
        bar = "Healing Wave", barIcon = 136052,             -- Naga bar slot
        hover = "Lesser Healing Wave", hoverIcon = 136043,  -- Healers of Azeroth hover key
        bind = "ACTIONBUTTON1",                             -- Blizzard's own binding
        clash = true,                                       -- only with a clash
        note = "Shift+1 switches your action bar page",     -- only with a paging clash
      },
    },
    shift = { ... }, ctrl = { ... }, alt = { ... },
  },
}
```

All cell fields are optional; empty cells and empty layers are left out; icons are fileIDs.
The grid position of a key follows from the plate (section 2): walk the keys row by row.

## 12. Coming from Casters of Azeroth

The Naga bar used to be part of Casters of Azeroth. Turn on **Nagas of Azeroth** in the AddOns list;
on its first start for a character it takes over the plate, the bar settings and the bar position
from Casters. Spells stay where they were (the same action slots).
