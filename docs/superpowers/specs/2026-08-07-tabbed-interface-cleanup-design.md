# Tabbed Interface Cleanup Design

## Goal

Prepare the tabbed game interface for `main` by retaining intentional UI behavior while removing work-in-progress code and unrelated editor rewrites.

## Project Configuration

Remove the unused `[dotnet]` section and `project/assembly_name` setting from `project.godot`. Keep `window/handheld/orientation=0` explicitly; in Godot this selects landscape orientation.

Restore stable UID annotations on resource references wherever the referenced resource has a committed UID. Scene files must retain valid `load_steps` metadata consistent with their declared external and sub-resources.

Revert importer-default additions in `icon.svg.import` because they are unrelated to the tabbed interface. Keep deletion of `.uid` files whose corresponding scripts were already removed.

## Code Cleanup

Keep the new `GameTabs` scene and script, HUD integration, responsive layout changes, inventory presentation, and right-click context-menu dismissal. Remove commented-out implementations, redundant blank lines, and purely mechanical reformatting that obscures the behavioral change.

## Verification and Delivery

Run the complete Godot test suite in the feature worktree. Commit the cleanup separately from the existing tabbed-interface commit. Merge the resulting feature branch into the current local `main`, perform a clean Godot import, rerun the complete test suite on merged `main`, and push only after all checks pass.
