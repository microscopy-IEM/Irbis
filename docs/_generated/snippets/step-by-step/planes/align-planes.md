!!! info "Before you start"
    **Prerequisites:**

    - Planes data loaded in Irbis.

    **UI location:**

    - Main app: **Planes** tab, **Pre-processing** section.

**Steps**

1. In **Pre-processing**, click **Pre-register**.
2. Review the window showing the calculated shift between each time point and the corresponding reference time point.
3. Press **Register** to calculate the xy shift for each time point.
4. Press **Accept** to apply the shifts.

Irbis shifts each time point in xy and crops the hanging edges.

If the registration is not optimal, adjust these parameters and run the registration again:

- Reference time point: select either **previous** (default) or **first** from the drop-down menu.
- Registration method: select either **Cross-correlation** (default) or **Intensity** from the drop-down menu. If needed, adjust **sigma**.

**Related**

- Check raw data first with [View raw planes data](../step-by-step/planes/view-raw-data.md).
- Continue cleanup with [Crop planes](../step-by-step/planes/crop-planes.md) or [Preprocess planes](../step-by-step/planes/preprocess-data.md).
