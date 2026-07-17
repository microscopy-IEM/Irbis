# Use ResultsViewer table views and plots

!!! info "Before you start"
    **Prerequisites:**

    - Data opened in ResultsViewer.

    **UI location:**

    - **ResultsViewer** window.

## Full table view

1. Switch to **Full** table view from the drop-down menu in the upper-left corner.
2. From the checkbox list on the left, select parameters to show in the table.
3. Review the table. Each column is a parameter, and data from all time points are pooled.

## Pivoted table view

1. Switch to **Pivoted** table view from the drop-down menu in the upper-left corner.
2. Select the desired parameter from **Grouped data**.
3. Review the table. By default, each column is one time point and each row is one object connected in time by a single group ID.

!!! warning
    Only model parts connected with group ID can be shown in Pivoted table view.

## Summarized table view

1. Switch to **Pivoted** table view.
2. Press **Show summarized** in the bottom-left corner.
3. Use the summarized table to inspect values that describe the full temporal development of each connected object.

## Plot data

1. Click one or more selected table columns.
2. Select the plot type from the drop-down menu in the upper-right corner.
3. If more parameters are selected than the plot type supports, only the last selected parameters are shown.
4. In **Pivoted** table view, switch between individual lines and the average of selected lines.
5. Tick **Categorical as labels** to group plot data by categories.

Supported plot types include histograms, bar plots, scatter plots, and line plots.

In **Full** table view, plots usually use the whole table column, even if only some rows are selected. Exceptions include plot types such as `individual: line`.

## Related

- Narrow the table with [Filter available data](filter-data.md).
- Filter by object development with [Filter by temporal development](filter-temporal-development.md).
- Create groups with [Define ResultsViewer categorization](categorize-data.md).

