# Create animations

Use animation options to set keyframes and play transitions between saved views.

!!! info "Before you start"
    **Prerequisites:**

    - 3D model created.

    **UI location:**

    - Main app: **Viewport** tab, **Animation options** section.

## Build an animation

1. Position the view as desired.
2. Press **Add keyframe**.
3. Repeat for all views between which transitions should occur.
4. To remove keyframes, select them in the listbox and press **Delete selected**. Use **Ctrl+click** to select multiple keyframes.
5. To reorder keyframes, select them and use the up and down arrows beside the listbox.
6. To change a selected keyframe to the current view, select it and press **Change for current**.
7. To change a transition, select the first keyframe in the pair, adjust **Duration**, and press **Apply to selected**.
8. To inspect a saved keyframe view, double-click it in the listbox or click its line in the animation timeline.
9. Press **Play animation**.
10. To animate only selected keyframes, tick **Selected only**.

During playback, each keyframe first switches time point and visible components, then applies special animation if selected, then runs the transition.

## Add special animations

1. Select an effect from **Special effect**.
2. Press **Add**.

The **Expand spines** option expands spines away from the dendritic shaft.

## Save and load animation setup

1. Press **Save script** to save the keyframe setup.
2. Press **Load script**.
3. In the dialog, select the saved setup and press **Open**.

The keyframe setup can be saved and applied to another model.

## Preview spine expansion

1. Press **Expand spine view**.
2. Press **Reset view** to return to the default position.

## Related

- Save static views with [Save views](save-views.md).

!!! example "Video placeholder"
    Add a video showing Add keyframe, Duration, Play animation, and Expand spines.


