# Use ResultsViewer modes and plots

!!! info "Before you start"
    **Prerequisites:**

    - Data opened in ResultsViewer.

    **UI location:**

    - **ResultsViewer** window.

## All parameters mode

1. Switch to **All parameters** mode.
2. Select parameters from the checkbox list on the left.
3. Review the table. Each column is a parameter, and data from all time points are pooled.

## Selected parameter mode

1. Switch to **Selected parameter** mode.
2. Select the desired parameter.
3. Review the table. Each column is one time point and each row is one object connected in time by a single group ID.

!!! warning
    Only model parts connected with group ID can be shown in Selected parameter mode.

## Plot data

1. Click one or more selected table columns.
2. Select the plot type from the drop-down menu in the upper-right corner.
3. If more parameters are selected than the plot type supports, only the last selected parameters are shown.
4. In **Selected parameter** mode, switch between individual lines and the average of selected lines.
5. Tick **categorical as labels** to group plot data by categories.

Supported plot types include histograms, bar plots, scatter plots, and line plots.

In **All parameters** mode, plots usually use the whole table column, even if only some rows are selected. Exceptions include plot types such as `individual: line`.

## Related

- Narrow the table with [Filter available data](filter-data.md).
- Create groups with [Define ResultsViewer categorization](categorize-data.md).

!!! example "Screenshot placeholder"
    Add screenshots of All parameters mode, Selected parameter mode, and the plot type drop-down menu.


