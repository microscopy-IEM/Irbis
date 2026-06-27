# ResultsViewer

ResultsViewer is part of Irbis for exploring generated data in tables and plots. It supports filtering, custom categories, stored views, and combined datasets.

!!! info "Before you start"
    **Prerequisites:**

    - Processed model or tracks data.

    **UI location:**

    - **ResultsViewer** window.
    - Open it from the right side of the bottom panel by pressing the plot icon button.

## Layout

- Left side: parameter selection and table.
- Right side: plots.
- Bottom-right panels: filtering and categorization.

## Table views

- **Full** table view pools data from all time points; table columns are parameters.
- **Pivoted** table view shows one parameter across time; columns are time points and rows are objects connected by group ID.
- **Summarized** table view contains values that describe the full temporal development of each connected object.

Pages:

- [Use table views and plots](modes-plots.md)
- [Filter available data](filter-data.md)
- [Filter by temporal development](filter-temporal-development.md)
- [Define ResultsViewer categorization](categorize-data.md)
- [Edit columns in Full table view](edit-columns-full.md)
- [Store a view](store-view.md)
- [Use batch mode](batch-mode.md)

!!! warning
    Filters and categorizations are synced between the main Irbis app and ResultsViewer, but generated data itself is not. If you change or generate data in the main app, close and reopen ResultsViewer to sync changes.
