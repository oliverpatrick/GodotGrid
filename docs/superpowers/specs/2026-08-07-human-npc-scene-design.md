# Human NPC Scene Design

## Goal

Visually distinguish human NPCs from players by rendering canonical NPCs with the new `human_man.tscn` scene while retaining the shared player movement and animation behavior.

## Design

`PlayerRegistry` continues to select character scenes from the server-provided entity type. Type-0 player entities use `player.tscn`; type-1 NPC entities whose canonical presentation is `model.player` use `human_man.tscn`. Both scenes use `player.gd`, which inherits `remote_player.gd`, so movement interpolation and animation handling remain shared.

This first version deliberately uses one scene for every human NPC, including Man and Merchant Aldric. Per-definition scene selection is deferred until a second NPC appearance requires it.

The existing NPC registry test will assert that a type-1 `npc.man` spawn instantiates `human_man.tscn`. The full headless Godot suite and a clean startup check must pass before the branch is pushed.

## Repository Scope

Only the new NPC scene, its necessary player-scene UID update, the registry scene selection, its test, and this design are included. Godot-generated changes to `icon.svg.import` and `project.godot` are excluded.
