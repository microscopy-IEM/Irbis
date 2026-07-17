# Filter available data

!!! info "Before you start"
    **Prerequisites:**

    - Data opened in ResultsViewer.
    - Desired modality selected at the top of ResultsViewer: model, tracks, or points.
    - For model data, desired branch selected at the top of ResultsViewer.

    **UI location:**

    - ResultsViewer: **Filtering** panel at the bottom right.

## Steps

1. Select the table to filter from **Table to filter** dropdown.
2. Select the parameter to filter by from the drop-down menu below it.
3. For categorical parameters, select included categories in the checkbox list.
4. For numerical parameters, set the lower and upper filter range (the edges are included in the interval).
6. Press **Filter**.
7. Existing filters appear as state buttons in the **Filtering** panel.
8. Toggle a filter button off to disable the filter (it will turn grey). Toggle it on to enable it again (it will turn blue).
9. To delete a filter, select the parameter name from the drop-down menu and press **Delete**.

Filters should sync with the main Irbis app. Changing a filter in Irbis updates ResultsViewer, and changing it in ResultsViewer updates Irbis.

## Related

- Use [Use ResultsViewer table views and plots](modes-plots.md) to inspect filtered data.
- Use [Filter by temporal development](filter-temporal-development.md) when the filter should use summarized object development rather than individual time points.

