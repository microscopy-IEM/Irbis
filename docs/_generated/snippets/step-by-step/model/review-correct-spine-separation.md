After spine separation, inspect whether individual protrusions were separated correctly from the shaft and from each other. Use base-point visualization to check where each spine is connected to the shaft, and use the manual or semi-automatic cutting tools to correct merged objects.

!!! info "Before you start"
    **Prerequisites:**

    - Primary 3D model created.
    - Dendritic shaft generated.
    - Spines separated from the shaft.

    **UI location:**

    - Main app: **Model** tab, **Spines** subtab.
    - Sections: **Manual editing options** and **Object list**.
    - Visualization panel context menu.

**Show and review base points**

Base points mark the centre of the patch where spines are associated with the dendritic shaft. They are important because they are later used to calculate several descriptive parameters, such as `euclideanLength`.

1. Go to **Model** > **Spines**.
2. Open **Manual editing options**.
3. Press **Show base points** to show or hide base-point markers in the visualization panel.
4. Select a spine to inspect its position relative to the shaft and its base point.
5. For one spine, use the context menu action **Single: Show base point** when you need to focus on that spine's base point.

If the base point is not placed correctly, move it manually by right-clicking it. This opens a movement gizmo for the base point. Press **Enter** to confirm the new position, or **Escape** to cancel the change.

If a base point is missing, select the spine and use **Single: Calculate base point** from the context menu. This recalculates the spine base point on the shaft surface. If the spine is not connected to the shaft, for example because of a missing neck, the underlying signal is traced between the spine and the shaft and the new base point is placed accordingly.

**Correct the shaft-spine boundary**

Use **Single: Redefine** when a spine is separated from the shaft at the wrong position.

1. Select the spine.
2. Right-click it in the visualization panel.
3. Choose **Single: Redefine**.
4. Move and rotate the cutting cylinder until it matches the intended shaft boundary.
5. Press **Enter** to apply the correction.
6. If the result is wrong, use **Undo**.

**Separate merged spines**

If two neighbouring spines are stored as one object, split them with a cutting plane.

1. Select the merged spine object.
2. Right-click it in the visualization panel.
3. Choose **Single: Suggest division plane** to start from an automatically suggested plane.
4. Move or rotate the plane if needed.
5. Press **Enter** to apply the cut.

Use **Single: Divide** when you want to place the cutting plane manually from the start.

**Use Find cuts**

**Find cuts** provides a semi-automatic way to look for candidate cuts in separated spine objects. Use it after the initial spine separation when some spines appear merged. The algorithm looks for places where multiple spines in one time point match a single merged spine in another time point.

1. Go to **Model** > **Spines**.
2. Open **Manual editing options**.
3. Press **Find cuts**. This opens a new window with proposed cuts.
4. Review the proposed cuts in the new window.
5. Approve only cuts that match the intended separation between neighbouring spines.

**Next steps**

- Continue to [Calculate spine features](../step-by-step/model/calculate-spine-features.md).
- For the complete context menu reference, see [Select and manipulate model objects](../step-by-step/model/object-list-context-menu.md).
