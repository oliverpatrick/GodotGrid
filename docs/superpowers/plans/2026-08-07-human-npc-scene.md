# Human NPC Scene Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Render every canonical human NPC with the differently coloured `human_man.tscn` scene while players continue using `player.tscn`.

**Architecture:** `PlayerRegistry` keeps its existing entity-type split. Type-0 players instantiate `PLAYER_SCENE`; supported type-1 NPCs instantiate one shared `NPC_HUMAN_MAN_SCENE`. Both scenes retain `player.gd` and therefore share `remote_player.gd` movement and animation behavior.

**Tech Stack:** Godot 4.7, GDScript, existing headless test runner.

## Global Constraints

- Work directly in the normal `GodotGrid` checkout on `feature/human-npc-scene`; do not create `.worktrees`.
- Use `human_man.tscn` for every canonical NPC whose presentation is `model.player`, including Man and Merchant Aldric.
- Defer per-definition scene mapping until another NPC appearance requires it.
- Exclude `icon.svg.import` and `project.godot` from the branch.
- Preserve the user-authored NPC scene and its colour changes.

---

### Task 1: Verify and integrate the shared human NPC scene

**Files:**

- Create: `assets/mobs/human/human_man.tscn`
- Modify: `assets/player/player.tscn`
- Modify: `world/player_registry.gd`
- Modify: `tests/player_registry_test.gd`

**Interfaces:**

- Consumes: canonical type-1 spawn messages with `definition_id` and `presentation.model_id == "model.player"`.
- Produces: a configured NPC node instantiated from `res://assets/mobs/human/human_man.tscn` and stored in `PlayerRegistry.npcs`.

- [ ] **Step 1: Run the existing registry test to verify the scene change is red**

Run:

```bash
GAME_CONTENT_ROOT="$PWD/../Server/game_content" /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --log-file /private/tmp/godotgrid-human-npc-red.log --script res://tests/test_runner.gd
```

Expected: `player_registry_test.gd` fails because it still expects the NPC instance path to be `res://assets/player/player.tscn` while the registry now instantiates `human_man.tscn`.

- [ ] **Step 2: Update the acceptance assertion**

In `tests/player_registry_test.gd`, replace:

```gdscript
if npc.scene_file_path != "res://assets/player/player.tscn" or npc.display_name != "Man" \
```

with:

```gdscript
if npc.scene_file_path != "res://assets/mobs/human/human_man.tscn" or npc.display_name != "Man" \
```

Keep the existing canonical name, metadata, position, movement, and despawn assertions unchanged.

- [ ] **Step 3: Remove excluded generated changes from the working tree**

Restore only `icon.svg.import` and `project.godot` to `HEAD`. Do not restore or rewrite the user-authored scene files or registry change.

- [ ] **Step 4: Run full verification**

Run:

```bash
GAME_CONTENT_ROOT="$PWD/../Server/game_content" /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --log-file /private/tmp/godotgrid-human-npc-green.log --script res://tests/test_runner.gd
GAME_CONTENT_ROOT="$PWD/../Server/game_content" /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --log-file /private/tmp/godotgrid-human-npc-startup.log --quit-after 3
git diff --check
```

Expected: `GODOT_TESTS_OK`, clean startup with no parse or content errors, and no whitespace errors.

- [ ] **Step 5: Commit and push the implementation**

```bash
git status --short
git add assets/mobs/human/human_man.tscn assets/player/player.tscn world/player_registry.gd tests/player_registry_test.gd docs/superpowers/plans/2026-08-07-human-npc-scene.md
git diff --cached --stat
git commit -m "feat: distinguish human npcs from players"
git push -u origin feature/human-npc-scene
```

Confirm the branch is synchronized with upstream and that `icon.svg.import` and `project.godot` are absent from the commit.
