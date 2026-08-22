---
title: Console decision — PC first, console post-launch
type: decision
status: locked
---

# Console decision

**PC first (Steam/Epic); console is a post-launch project.**

Godot ships no first-party console export — it requires a licensed porting house (W4 Games, Pineapple Works,
Lone Wolf) plus NDA, devkit, platform approval and a *finished* PC build as input: months and real money.

## The project also fails baseline cert today

- **Zero joypad bindings** in `project.godot`
- `Menu.gd` accepts only `InputEventKey` when rebinding
- **No save system anywhere** — no `ConfigFile` / `user://` / `ResourceSaver`; even keybinds don't persist
- No suspend/resume
- Meta UI is mouse-and-drag: `AbilityDraftScene` uses `set_drag_forwarding`, shops use `gui_input`

**That is a UI rewrite, not a port.**

## Two cheap insurance policies

Taken in [[target]]:

1. Full gamepad navigation on every menu
2. No mouse-only interaction

**Days now against weeks later** — and they must land *before* more classes and spells are added to that UI,
since every new card multiplies the rewrite.

## External messaging

> "PC first, console under evaluation."
