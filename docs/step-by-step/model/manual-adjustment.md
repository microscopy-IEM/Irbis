# Manually adjust selected objects

Use object context menus to correct registration, divide merged objects, redefine spines, delete objects, or attach objects at the registration level.

!!! info "Before you start"
    **UI location:**

    - Visualization panel.
    - Open the context menu by left-clicking an object, then right-clicking it.

## Select objects

1. Go to the tab for the object type you want to edit.
2. Left-click an object to select it.
3. Hold **Ctrl** while left-clicking to select multiple objects.
4. Right-click a selected object to open the context menu.

Only objects of the currently selected tab are selectable. Selected objects change color.

Context menu actions labelled **Single** apply only to the right-clicked object. Actions labelled **Multi** apply to all selected objects.

## Single: select next

Use this to connect an object with its match in the next time point.

1. Click **Single: Select next**.
2. Irbis moves to the next time point.
3. Left-click the corresponding object.

## Single: select previous

Use this to connect an object with its match in the previous time point.

1. Click **Single: Select previous**.
2. Irbis moves to the previous time point.
3. Left-click the corresponding object.

## Single: divide

Use this when one reconstructed object contains two merged objects.

1. Click **Single: Divide**.
2. Move, rotate, and resize the cutting plane so it delineates the desired cut.
3. Press **Enter** when satisfied.
4. If Enter does not work, click inside the plot and press **Enter** again.
5. To cancel while the plane is visible, press **Esc**. If needed, click inside the plot first.
6. If the cut is wrong, press **Undo** in the bottom-right corner.

## Single: redefine

This is available only for spines. It changes where a spine is separated from the dendritic shaft.

1. Click **Single: Redefine**.
2. Move and rotate the cutting cylinder so it corresponds to the shaft.
3. Press **Enter** when satisfied.
4. If Enter does not work, click inside the plot and press **Enter** again.
5. To cancel while the cylinder is visible, press **Esc**. If needed, click inside the plot first.
6. If the result is wrong, press **Undo** in the bottom-right corner.

## Multi: delete

1. Click **Multi: Delete**.
2. Irbis deletes all selected objects in the current time point.

## Multi: delete in all time points

1. Click **Multi: Delete in all time points**.
2. Irbis deletes selected objects in all time points where the corresponding group IDs exist.

## Multi: attach

Use this when objects of the same type should not be separated, such as protrusions separated from the main body by imperfect reconstruction.

1. Click **Multi: Attach**.
2. When prompted, click the main body to connect the selected objects to.

This does not form a geometric connection; objects are connected at the registration level.

## Related

- Use [Register objects across time points](register-objects.md) before manual registration corrections.
- Use [Separate spines from the shaft](separate-spines.md) before redefining spine separation.

!!! example "Video placeholder"
    Add clips for Divide, Redefine, Delete, and Attach context-menu actions.


