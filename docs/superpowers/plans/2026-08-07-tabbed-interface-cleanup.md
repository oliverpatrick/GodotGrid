# Tabbed Interface Cleanup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prepare the tabbed game interface for `main` by retaining intentional behavior and removing work-in-progress or unrelated editor changes.

**Architecture:** Treat the current passing feature commit as a characterized baseline. Apply a focused configuration/resource/code cleanup without changing runtime interfaces, verify both the active feature worktree and a clean imported `main` worktree, then push the merged result.

**Tech Stack:** Godot 4.7.1, GDScript, `.godot` and `.tscn` resource formats, Git

## Global Constraints

- Remove the unused `[dotnet]` section and `project/assembly_name` setting.
- Keep `window/handheld/orientation=0` explicitly for landscape orientation.
- Keep stable UID annotations wherever the referenced resource has a committed UID.
- Keep valid `load_steps` metadata consistent with declared scene resources.
- Preserve the `GameTabs` UI, HUD integration, responsive layout, inventory presentation, and right-click context-menu dismissal.
- Keep deletion of UID files whose corresponding scripts no longer exist.

---

### Task 1: Clean the tabbed-interface change set

**Files:**
- Modify: `project.godot`
- Modify: `icon.svg.import`
- Modify: `terrain_generator.tscn`
- Modify: `ui/context_menu/context_menu.gd`
- Test: `tests/context_menu_test.gd`
- Test: `tests/run_toggle_test.gd`
- Test: `tests/ui_scale_test.gd`

**Interfaces:**
- Consumes: committed `.uid` files for login and HUD scenes, existing `GameContextMenu.open()` and `popup_rect_for()` behavior, and the existing complete Godot test runner.
- Produces: a focused feature branch whose runtime behavior matches commit `6196314`, with explicit landscape configuration and valid UID-based scene references.

- [ ] **Step 1: Confirm the characterized baseline**

Run:

```sh
GAME_CONTENT_ROOT="$PWD/../Server/game_content" /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --log-file /private/tmp/godotgrid-tabbed-cleanup-baseline.log --script res://tests/test_runner.gd
```

Expected: `GODOT_TESTS_OK`.

- [ ] **Step 2: Apply the focused cleanup**

In `project.godot`, delete the `[dotnet]` section and retain:

```ini
[display]

window/size/viewport_width=1280
window/size/viewport_height=720
window/stretch/mode="canvas_items"
window/stretch/aspect="expand"
window/handheld/orientation=0
```

In `icon.svg.import`, remove only the six newly generated importer-default lines for `compress/uastc_level`, `compress/rdo_quality_loss`, and `process/channel_remap/*`.

In `terrain_generator.tscn`, restore `load_steps=15` and the committed UIDs `uid://lqxvsowpmkyp` for the login scene and `uid://01ughi8s4iax` for the HUD scene.

In `ui/context_menu/context_menu.gd`, keep root-viewport clamping and right-click dismissal while deleting the commented-out implementations, redundant blank lines, and expanded formatting-only rewrites.

- [ ] **Step 3: Verify feature behavior and resource integrity**

Run:

```sh
GAME_CONTENT_ROOT="$PWD/../Server/game_content" /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --log-file /private/tmp/godotgrid-tabbed-cleanup-feature.log --script res://tests/test_runner.gd
git diff --check
```

Expected: `GODOT_TESTS_OK` and no diff errors.

- [ ] **Step 4: Commit the cleanup**

Run:

```sh
git add project.godot icon.svg.import terrain_generator.tscn ui/context_menu/context_menu.gd docs/superpowers/plans/2026-08-07-tabbed-interface-cleanup.md
git commit -m "chore: clean tabbed interface changes"
```

- [ ] **Step 5: Merge and verify clean main**

Merge `feature/online-mvp` into the existing temporary `main` worktree at `/private/tmp/godot-main-push.hFKvN0`. Run Godot with `--import`, then run `res://tests/test_runner.gd` using `../Server/game_content`. Expected: `GODOT_TESTS_OK` and a clean tracked worktree after reverting any import-only metadata regeneration.

- [ ] **Step 6: Push and verify origin**

Run:

```sh
git push origin main
git fetch origin
test "$(git rev-parse main)" = "$(git rev-parse origin/main)"
```

Expected: `origin/main` equals local `main`.
