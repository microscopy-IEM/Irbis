!!! info "Before you start"
    **Prerequisites:**

    - Data opened in ResultsViewer.

    **UI location:**

    - **ResultsViewer** window.

**Full table view**

1. Switch to **Full** table view from the drop-down menu in the upper-left corner.
2. From the checkbox tree on the left, select parameters to show in the table.
3. Review the table. Each column is a parameter, and data from all time points are pooled.

The Full table column tree groups predefined parameters by data type, including numerical, categorical, cell, and logical parameters. User-defined columns appear under **user-defined**.

**Pivoted table view**

1. Switch to **Pivoted** table view from the drop-down menu in the upper-left corner.
2. Select the desired parameter from **Grouped data**.
3. Select the row identifier from **Rows**.
4. Select the column identifier from **Columns**.
5. Review the table.

By default, ResultsViewer prefers `timePoint` for **Columns**, `fileId_groupId` for **Rows** when it exists, then `groupId`, and `volume` for **Grouped data** when it exists. In batch-loaded model data, `fileId_groupId` is created automatically when both `fileId` and `groupId` are available.

!!! warning
    Pivoted table view needs a row identifier that connects observations across the selected column variable. For temporal model development, this is usually `groupId` or `fileId_groupId`.

**Transform Pivoted values**

Use Pivoted transformations when you want to compare changes relative to a reference time point or smooth a row-wise trend.

1. Switch to **Pivoted** table view.
2. Tick **Apply transformation:**.
3. Select a transformation from the drop-down menu.
4. If the transformation exposes a numeric field, enter the reference column or window value.

Available transformations in the code are **Subtract first column**, **Subtract previous column**, **Difference from selected column**, **Ratio to first column**, **Ratio to selected column**, **Percent change from first column**, **Moving average**, and **Detrend**.

!!! warning
    Pivoted table transformations are not reflected in summarized data.

**Summarized table view**

1. Switch to **Pivoted** table view.
2. Press **Show summarized** in the bottom-left corner.
3. In the summarized table, select **Rows** if needed.
4. Select summarized columns from the checkbox tree.
5. Use the summarized table to inspect values that describe the full temporal development of each connected object.

For numeric parent parameters, the summarized table can create statistics such as mean, standard deviation, coefficient of variation, minimum, maximum, observation count, slope, R-squared, residual spread, and Pearson correlation over `timePoint`. For categorical parent parameters, it creates a mode summary. The default summarized columns are created only when `timePoint` is present in the parent table.

**Plot data**

1. Click one or more table cells, rows, or columns in the displayed table.
2. Select the plot type from the drop-down menu in the upper-right corner.
3. If more parameters are selected than the plot type supports, the formatter uses the last selected data blocks that satisfy the plot.
4. In **Pivoted** table view, use **individual** to switch between selected cells and whole selected rows.
5. Tick **categorical as labels** to use the last suitable categorical column as plot groups. For **two variables** and **line: individual**, a numeric extra column can be used as continuous color data.

Supported plot types are **histogram**, **histogram with cdf**, **stacked histogram**, **ratio bar plot**, **line histogram**, **two variables**, **line: individual**, **line: averaged**, and **radial density histogram**.

In **Full** table view, plots usually use the whole table column, even if only some rows are selected. Exceptions include plot types such as `individual: line`.

**Plot options**

- **xlog** and **ylog** switch the plot axes between linear and logarithmic scaling.
- **zero** sets the lower y-axis limit to `0`; turning it off returns the y-axis to automatic limits.
- The settings icon opens plot settings. Based on `PlotSettingsDialog`, settings include jitter, averaged-line error metric, averaged-line error style, line color, and error color.
- **Export plot** copies the current axes into a separate MATLAB figure. **PLACEHOLDER:** verify the final user action for saving that figure, because the callback creates a new figure but does not call a file-save dialog directly.
- **Eval plot** calls `exportEvalFigFcn` on the current axes. **PLACEHOLDER:** describe the user-visible output after confirming it in the GUI.

**Related**

- Narrow the table or filter by object development with [Filter ResultsViewer data](../step-by-step/results-viewer/filter-data.md).
- Create groups and derived columns with [Create and manage user-defined columns](../step-by-step/results-viewer/categorize-data.md).
