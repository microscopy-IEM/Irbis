!!! info "Before you start"
    **Prerequisites:**

    - Planes data loaded in Irbis.
    - Model structure created.

    **UI location:**

    - Main app: **Model** tab, **Full** subtab, **3D reconstruction** section.

**Steps**

1. Select the channel of interest from the channel drop-down menu.
2. Set the threshold that separates background from signal.
3. Press **Show** to preview the selected area highlighted in gray.
4. If required, choose **More time points** and set **First** and **Last** used time point.
5. Select reconstruction detail level from `1` to `5`. Level `1` is fastest and least detailed. Level `5` is most detailed and computationally demanding.
6. If needed, adjust **Advanced reconstruction settings**.
7. Confirm that pixel size and z-spacing are correct in the **Planes** tab.
8. Press **Generate 3D** and wait for reconstruction to finish.

**Threshold for constant signal**

1. Press **Auto** for automatic threshold estimation.
2. Or set the threshold manually in the spinner.
3. Press **Show** to check the selected area.

If signal strength is stable, define the threshold for one time point. Irbis uses the same value for the rest.

**Threshold for bleaching signal**

1. Open **Advanced reconstruction settings**.
2. Check **Bleaching compensation**.
3. Set the threshold for the first and last time point.
4. If the switch is set to **Selected range**, compensation applies only between the selected first and last time point. Only those time points have editable thresholds.
5. Check the bleaching compensation value next to the checkbox.

**Next steps**

- Continue to [Detect drift and correct it](../step-by-step/model/drift-correction.md).
- Then [Register objects across time points](../step-by-step/model/register-objects.md).
