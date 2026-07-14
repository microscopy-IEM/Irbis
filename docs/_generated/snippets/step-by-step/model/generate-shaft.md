!!! info "Before you start"
    **Prerequisites:**

    - Primary 3D model created for all time points.
    - Time drift corrected.
    - Primary 3D model registered in time.
    - Dendrite tracked.

    **UI location:**

    - Main app: **Model** tab, **Dendrite** subtab.
    - Sections: **Shaft generation and adjustment** and, if used, **Adaptive shaft settings**.

**Steps**

1. Select the shaft generation method from the drop-down menu.
2. Use **Constant diameter** to approximate the shaft as a tube with circular cross-section, or elliptical cross-section when z scale is not `1`.
3. If desired, check **Parallel computing**. This can speed calculations, but startup may take some time.
4. Press **Generate shaft**.
5. If **All time points** is checked in **Dendrite tracking**, the shaft is generated for all time points. Otherwise, it is generated only for the current time point.
6. Adjust shaft diameter with the **Radius** slider.
7. To apply the diameter to all time points, check **Same radius for all time points**.
8. For the Constant diameter model, adjust **z scale** if needed. A value of `1` is circular; higher values make the cross-section more rectangular.
9. For the Adaptive shaft model, tune parameters in **Adaptive shaft settings**.
10. Press **Test one plane** to check adaptive model accuracy before applying settings broadly.

**Next steps**

- Continue to [Separate spines from the shaft](../step-by-step/model/separate-spines.md).
