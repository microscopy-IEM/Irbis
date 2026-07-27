Use model visualization controls to show or hide the whole model, adjust the appearance of individual object types, and color-code objects by stored parameters.

!!! info "Before you start"
    **Prerequisites:**

    - Model structure initialized.
    - 3D model objects generated.

    **UI location:**

    - Bottom panel: **Model** checkbox.
    - Upper-right visualization settings panel.
    - Object-type tabs: **Colorcoding** section, where available.

**Show or hide the model**

The **Model** checkbox appears in the bottom panel after the model is initialized.

1. Check **Model** to show model objects in the visualization panel.
2. Clear **Model** to hide all model objects.

This control affects the model as one unit. It does not change which individual object types are enabled inside the model.

**Adjust global visualization**

Use the upper-right visualization settings panel to change general scene display.

- **Light** turns scene lighting on or off.
- **Grid** shows or hides the grid.
- **Axes** shows or hides the axes.
- **Light** slider adjusts light intensity.
- **Shading** turns shaded surface rendering on or off.
- **Box** shows or hides the plot box.
- **Selection color** sets the color used for selected objects.
- **Background color** sets the visualization background color.

**Show or hide object types**

The visualization settings panel lists model branches such as **Full**, **Shaft**, **Dendrite**, **Spines**, and **Synapses**.

1. Open the visualization settings panel in the upper-right corner.
2. Use the checkbox next to a branch name to show or hide that object type.
3. Use the slider next to a branch name to adjust transparency.
4. Use the color button next to a branch name to change its color.

These controls affect only visualization. They do not delete objects or change stored measurements.

**Color-code individual objects**

Some object types can be color-coded from the corresponding object-type tab.

1. Open the object-type tab you want to color-code.
2. Open **Colorcoding**.
3. Check **use individual colors**.
4. Select the parameter used for color-coding from **Colorcode**.
5. Select the colormap.

Color-coding uses values stored for individual objects. Available parameters depend on the selected object type and on which measurements have been calculated.

**Related**

- Use [Select and manipulate model objects](../step-by-step/model/object-list-context-menu.md) to select, track, delete or edit objects.
- Use [Export model objects](../step-by-step/model/export-model-objects.md) to export meshes or masks.
