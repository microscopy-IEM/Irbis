# Define ResultsViewer categorization in Full table view

Irbis-generated data can be further categorized in ResultsViewer.

!!! info "Before you start"
    **Prerequisites:**

    - Data opened in ResultsViewer.
    - Desired modality selected at the top of ResultsViewer: model, tracks, or points.
    - For model data, desired branch selected at the top of ResultsViewer.
    - **Full** table view selected.

    **UI location:**

    - ResultsViewer: **Categorization** panel at the bottom right.

## Define a new categorization

1. In the upper-left corner above the checkbox list, click the downwards-pointing arrow.
2. Select **add categorization** from the list.
3. In the dialog, enter the categorization name in **Categorization name**.
4. Define categories by combining criteria.
5. Enter each category name in its text field.
6. Press **Add criteria** in a category section to add a rule.
7. Press **Add category** to add another category.
8. Press **Save categorization**.

## Use categorization templates

Templates are stored categorization rules that can be reused for multiple datasets. Templates are stored with Irbis and loaded in the **Templates** drop-down menu.

1. To use an existing template, select it from the drop-down menu and press **Use**.

To do additional actions, press **Templates** and work in the newly opened dialog window:

1. To edit an existing template, select the template from the drop-down menu and press **Edit**.
2. To create a template, press **Add a new template** and define it like a categorization.
3. To transfer templates between computers or users, press **Export templates** and later use **Import templates**.
4. To store an existing dataset categorization as a template, right-click the selected categorization in the parameter checkbox list on the left side of ResultsViewer.

!!! warning
    Filters and categorizations are synced between the main Irbis app and ResultsViewer, but generated data itself is not. If you change or generate data in the main app, close and reopen ResultsViewer to sync changes.

## Related

- Track categorizations are described in [Define and edit track categorizations](../tracks/categorize-tracks.md).

