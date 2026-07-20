# Item Drop Resource Repair Design

## Problem

`ItemDrop.tscn` references `UI/item_drop/32207-1.png` through `32207-4.png`. Git history shows those four PNGs were renamed 100% to `速度-1.png` through `速度-4.png` in commit `6036369`, but the scene references were not updated. Loading `ItemDrop.tscn` therefore prevents `Enemy/Snake.gd` and maps containing snakes from parsing.

## Design

Point the `加速` animation at the renamed four-frame `UI/item_drop/速度-1.png` through `速度-4.png` artwork. Git blob hashes prove each new-name file is byte-for-byte identical to its corresponding historical `32207` file, so this restores the original artwork rather than substituting a placeholder.

Only the four `ext_resource` paths in `ItemDrop.tscn` change. Animation names, frame order, item behavior, scripts, and gameplay values remain unchanged.

## Verification

Add a Godot script-runner regression test that loads `ItemDrop.tscn`, `Enemy/Snake.gd`, and `assets/map/guyidaoguanai.tscn`, then actually changes to that teleport destination and confirms its gameplay nodes enter the scene tree. The test must fail before the reference repair, pass afterward, and run alongside the existing GameState, SaveManager, and scene-restore tests.
