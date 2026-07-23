Store a ResultsViewer view if you often return to the same modality, table view, selected columns, selected rows, plot type, and plot settings.

!!! info "Before you start"
    **Prerequisites:**

    - Data opened in ResultsViewer.
    - ResultsViewer set to the state you want to store.

    **UI location:**

    - ResultsViewer: view controls in the upper-middle part of the window.

**Store a view**

1. Set ResultsViewer to the state you want to store.
2. Press **Store view**.
3. Enter a view name.
4. Press **OK**.

The stored view includes the active modality and branch, the top table type, table processor state, plot type, grouping and individual-line settings, jitter and averaged-line settings, plot colors, and the log-axis checkbox state. If a summarized bottom table is shown, its table state is stored too.

**Load a stored view**

1. Select the view name from the drop-down menu in the upper-middle part of the window.
2. Press **Use view**.

ResultsViewer updates to the stored state.

If the stored view refers to columns that do not exist in the current dataset, ResultsViewer shows an invalid-view warning and ignores unavailable summarized columns where the processor supports that fallback.

**Delete a stored view**

1. Select the view name from the drop-down menu in the upper-middle part of the window.
2. Press **Delete view**.

**Export or import stored views**

1. To export the selected view, select it from the stored-view drop-down menu and press the export icon.
2. Choose `.mat` or `.json`.
3. To import a view, press the import icon and select a `.mat` or `.json` view file.

The code supports exporting one selected view as `.mat` or `.json`, and importing either a single exported view or a `.mat` file containing a `viewsStruct`.

!!! note
    Stored views are saved in ResultsViewer settings when the window closes.

**Related**

- Use [Use ResultsViewer table views and plots](../step-by-step/results-viewer/modes-plots.md) before storing a view.
