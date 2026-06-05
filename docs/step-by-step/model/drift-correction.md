# Detect drift and correct it

If all time points are generated at once during 3D reconstruction, drift correction runs automatically.

!!! info "Before you start"
    **Prerequisites:**

    - Primary 3D model created for all time points.

    **UI location:**

    - Main app: **Model** tab, **Full** subtab.
    - Sections: **Drift correction** and **Position adjustment tool**.

## Detect drift

1. In **Drift correction**, press **Detect drift**.
2. By default, the first time point is used as reference.
3. If needed, select a different reference type from the reference drop-down menu.
4. After drift is detected, check **Drift correction** to apply correction.

## Manually adjust drift

1. Check **Show reference**.
2. In **Position adjustment tool**, set the switch to **Drift**.
3. Select the movement step.
4. Use the arrows to align the model with the reference for the current time point.
5. If the drift is far off, use the red reset buttons in the middle of the arrows. One resets `x-y`, and the other resets `z`.

## Next steps

- Continue to [Register objects across time points](register-objects.md).

!!! example "Video placeholder"
    Add a short clip showing Detect drift, enabling Drift correction, and manual arrow adjustment.


