# View raw planes data

!!! info "Before you start"
    **Prerequisites:**

    - Raw data or preprocessed `.irbis` data loaded in Irbis.

    **UI location:**

    - Main app: **Planes** tab.

## Scroll through the z-stack

1. Change the number in the **Plane** spinner.
2. Alternatively, hold **Shift** and use the scroll wheel.

## Create a z-projection

1. Change the switch to **Projection**.
2. Set **Depth**. Depth `1` includes the selected plane plus one plane above and one below.
3. Select the projection mode from the drop-down menu. The default is maximum intensity projection.

## Select channels to view

1. Tick the checkboxes for the channels you want to show.

## Select the editable channel

1. In **Channels**, press the button with the channel name.
2. The greyed-out channel button marks the currently editable channel.

## Check pixel size and z-step

1. In **Tools**, check **pixel size** and **z step**.
2. Correct these values if needed. They should load from image metadata, but checking them is recommended.
3. Adjust **z step** if you need to correct spherical aberration in the raw data.

## Show helper elements

1. Tick **Scale bar** in **Tools** to show a scale bar.
2. Tick **Box** to show a red bounding box around the planes plot. This helps confirm whether planes are visible.

## Next steps

- Improve alignment with [Align planes across time points](align-planes.md).
- Reduce the region with [Crop planes](crop-planes.md).
- Continue to [Create a new model](../model/create-model.md).

