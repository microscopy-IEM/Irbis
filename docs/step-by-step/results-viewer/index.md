# ResultsViewer

ResultsViewer is part of Irbis for exploring generated data in tables and plots. It supports filtering and custom groups.

!!! info "Before you start"
    **Prerequisites:**

    - Processed model or tracks data.

    **UI location:**

    - **ResultsViewer** window.
    - Open it from the right side of the bottom panel by pressing the plot icon button.

## Layout

- Left side: parameter selection and table.
- Right side: plots, filtering, and categorization.

## Modes

- **All parameters** mode pools data from all time points; table columns are parameters.
- **Selected parameter** mode shows one parameter across time; columns are time points and rows are objects connected by group ID.

Pages:

- [Use modes and plots](modes-plots.md)
- [Filter available data](filter-data.md)
- [Define ResultsViewer categorization](categorize-data.md)
- [Use batch mode](batch-mode.md)

!!! warning
    Filters and categorizations are synced between the main Irbis app and ResultsViewer, but generated data itself is not. If you change or generate data in the main app, close and reopen ResultsViewer to sync changes.


