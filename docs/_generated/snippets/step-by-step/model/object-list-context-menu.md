Use the **Object list** section to select objects, inspect object IDs and group IDs, track objects across time points, and apply actions to selected objects. Use the object context menu for geometry editing, manual connection corrections and object-level operations.

!!! info "Before you start"
    **Prerequisites:**

    - 3D model created.

    **UI location:**

    - Main app: **Model** tab.
    - Object-type subtab for the objects you want to manipulate.
    - **Object list** section.
    - Visualization panel context menu.

**Select objects**

1. Open the object-type subtab you want to edit.
2. Expand **Object list**.
3. Select an object by clicking its row in the object table, or by left-clicking it in the visualization panel.
4. Hold **Ctrl** while left-clicking to select multiple objects.
5. Right-click a selected object in the visualization panel to open the context menu.

Only objects of the currently selected subtab are selectable. Selected objects change color. When selected, the object ID and group ID in brackets appear next to the object. Additional object information can appear in the upper-left corner of the visualization panel.

**Object list**

The object table shows object IDs and group IDs for the current time point. The object ID identifies an object within the current table. The group ID connects corresponding objects across time points.

| Control | Use |
|---|---|
| **Object ID** | Object identifier in the current time point. |
| **Group ID** | Identifier used to connect corresponding objects across time points. |
| **Track objects** | Assigns group IDs by [connecting objects in time](../step-by-step/model/connect-objects-in-time.md). Increase **Radius limit** if matching misses objects that moved farther between time points. |
| **Radius limit (um)** | Maximum matching distance used when tracking objects across time points. |
| **Edit group IDs** | Activates manual editing of group ID values in the object list. |
| **Delete objects** | Deletes selected objects. |
| **Unassign group IDs** | Removes group ID assignments from selected objects. |
| **Plot timelapse** | Plots the selected object's development over time. The currently shown object changes when a new object is selected. |
| **Plot timelapse (all)** | Plots time-lapse data for all objects in the current object type. |

**Context menu**

Open the context menu by selecting an object and then right-clicking it in the visualization panel.

Actions labelled **Single** apply to the object that was right-clicked. Actions labelled **Multi** apply to all selected objects.

| Action | Use |
|---|---|
| **Single: Select next** | Connects the selected object with its matching object in the next time point. Irbis moves to the next time point, then you select the corresponding object. |
| **Single: Select previous** | Connects the selected object with its matching object in the previous time point. Irbis moves to the previous time point, then you select the corresponding object. |
| **Single: Divide** | Divides one merged reconstructed object using a manually positioned cutting plane. |
| **Single: Suggest division plane** | Suggests a cutting plane for separating merged objects. Move or rotate the plane if needed, then press **Enter** to apply the cut. |
| **Single: Redefine** | For spines only: redefines where the spine is separated from the dendritic shaft. |
| **Single: Show base point** | For spines only: visualize the base point belonging to the current spine. |
| **Single: Calculate base point** | For spines only: finds a base point on the surface of the shaft. This works also if the spine is not connected to the shaft. |
| **Multi: Delete** | Deletes all selected objects in the current time point. |
| **Multi: Delete in all time points** | Deletes selected objects in all time points where the corresponding group IDs exist. |
| **Multi: Attach** | Connects selected objects at the group-ID level when objects of the same type should not be separated. |
| **Single: Show details** |  |

**Manual connection correction**

Use **Single: Select next** and **Single: Select previous** when automatic object connection chose the wrong object or missed a connection.

**Single: Select next**

1. Select the object you want to connect.
2. Open the context menu.
3. Click **Single: Select next**.
4. Irbis moves to the next time point.
5. Left-click the corresponding object.

**Single: Select previous**

1. Select the object you want to connect.
2. Open the context menu.
3. Click **Single: Select previous**.
4. Irbis moves to the previous time point.
5. Left-click the corresponding object.

**Manual geometry correction**

Use context menu geometry actions when the reconstructed object shape needs correction.

**Single: Divide**

Use this when one reconstructed object contains two merged objects.

1. Select the merged object.
2. Open the context menu.
3. Click **Single: Divide**.
4. Move, rotate, and resize the cutting plane so it delineates the desired cut.
5. Press **Enter** when satisfied.
6. If **Enter** does not work, click inside the plot and press **Enter** again.
7. To cancel while the plane is visible, press **Esc**. If needed, click inside the plot first.
8. If the cut is wrong, press **Undo** in the bottom-right corner.

**Single: Suggest division plane**

Use this when Irbis should propose an initial cutting plane for a merged object.

1. Select the merged object.
2. Open the context menu.
3. Click **Single: Suggest division plane**.
4. Move or rotate the suggested plane if needed.
5. Press **Enter** when satisfied.
6. If the cut is wrong, press **Undo**.

**Single: Redefine**

This is available only for spines. It changes where a spine is separated from the dendritic shaft.

1. Select the spine.
2. Open the context menu.
3. Click **Single: Redefine**.
4. Move and rotate the cutting cylinder so it corresponds to the shaft.
5. Press **Enter** when satisfied.
6. If **Enter** does not work, click inside the plot and press **Enter** again.
7. To cancel while the cylinder is visible, press **Esc**. If needed, click inside the plot first.
8. If the result is wrong, press **Undo** in the bottom-right corner.

**Delete or attach objects**

**Multi: Delete**

1. Select one or more objects.
2. Open the context menu.
3. Click **Multi: Delete**.

Irbis deletes all selected objects in the current time point.

**Multi: Delete in all time points**

1. Select one or more objects.
2. Open the context menu.
3. Click **Multi: Delete in all time points**.

Irbis deletes selected objects in all time points where the corresponding group IDs exist.

**Multi: Attach**

Use this when objects of the same type should not be separated, such as protrusions separated from the main body by imperfect reconstruction.

1. Select the objects to attach.
2. Open the context menu.
3. Click **Multi: Attach**.
4. When prompted, click the main body to connect the selected objects to.

This does not form a geometric connection; objects are connected at the group-ID level.

**Related**

- Use [Connect objects in time](../step-by-step/model/connect-objects-in-time.md) for the main tracking workflow.
- Use [Review and correct spine separation](../step-by-step/model/review-correct-spine-separation.md) for spine base-point and separation correction.
- Use [Export model objects](../step-by-step/model/export-model-objects.md) to export meshes or masks.
