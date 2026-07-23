# Create and manage user-defined columns

Use the Full table view controls to add categorizations, derived columns, or editable manual columns before switching to Pivoted table view or plotting.

!!! info "Before you start"
    **Prerequisites:**

    - Data opened in ResultsViewer.
    - Desired modality selected at the top of ResultsViewer.
    - For model data, desired branch selected at the top of ResultsViewer.
    - **Full** table view selected.

    **UI location:**

    - ResultsViewer: **Full** table view selected from the drop-down menu in the upper-left corner.
    - Column actions are available from the downwards-pointing arrow above the checkbox tree on the left.

## Choose the column type

The Full table column menu includes these user-defined column actions:

- **Add categorization**: create category labels from rules based on existing columns.
- **Add merged**: combine two columns into a single identifier.
- **Add formula**: calculate a new column from a MATLAB expression.
- **Add manual**: create editable category labels and assign them directly in the table.

## Add a categorization

1. In the upper-left corner above the checkbox tree, click the downwards-pointing arrow.
2. Select **Add categorization** from the list.
3. In the dialog, enter the categorization name in **Categorization name**.
4. Define categories by combining criteria.
5. Enter each category name in its text field.
6. Press **Add criteria** in a category section to add a rule.
7. Press **Add category** to add another category.
8. Press **Save categorization**.

For numeric criteria, the dialog supports `=`, `<`, `<=`, `>`, `>=`, and not-equal operators. For categorical criteria, it shows a checkbox tree of category values. Press **Complement** in a category section to generate complementary categories from that section's current criteria.

Categories are saved as a user-defined column and appear under **user-defined** in the column tree.

## Add a merged column

Use a merged column when one identifier is not unique enough by itself. For example, after batch loading multiple datasets, combine `fileId` and `groupId` before using Pivoted table view.

1. In the upper-left corner above the checkbox tree, click the downwards-pointing arrow.
2. Select **Add merged**.
3. Select the first source column from **Option 1**.
4. Select the second source column from **Option 2**.
5. Press **OK**.

The new merged column appears in the parameter list and can be used as a row identifier in Pivoted table view.

Merged columns are built as `string(firstColumn) + "_" + string(secondColumn)`. If `fileId` and `groupId` are available, the dialog defaults to those two columns.

## Add a formula column

1. In the upper-left corner above the checkbox tree, click the downwards-pointing arrow.
2. Select **Add formula**.
3. Enter a valid MATLAB variable name for **New column name**.
4. Enter the formula using existing column names.
5. Press **OK**.

Formula columns are evaluated as MATLAB expressions against the table columns referenced in the formula. If the result is text, ResultsViewer converts it to a categorical column. The result must have one value per table row.

## Add a manual column

Use a manual column when you want editable category labels that you assign in the table.

1. In the upper-left corner above the checkbox tree, click the downwards-pointing arrow.
2. Select **Add manual**.
3. Enter the categorization name.
4. Add group names with **Add group**.
5. Optionally mark one group as **Default**.
6. Press **Finish**.
7. Select the new user-defined column in the column tree.
8. Edit its cells directly in the table.

Manual columns are stored as editable user-defined columns. Only columns marked editable by ResultsViewer can be edited directly in the table.

## Manage columns

Right-click a user-defined column to **Delete**, **Rename**, **Edit**, **Duplicate**, or **Store as template**.

Right-click a predefined column to **Delete** or **Rename** it.

!!! warning
    The context menu can delete or rename predefined columns in the ResultsViewer table store. Use this carefully, especially before saving a `.irbisRes` file.

## Use categorization templates

Templates are stored categorization rules that can be reused for multiple datasets. Templates are stored with Irbis and loaded in the **Templates** drop-down menu.

1. To use an existing template, select it from the drop-down menu and press **Use**.

To do additional actions, press **Templates** and work in the newly opened dialog window:

1. To edit an existing template, select the template from the drop-down menu and press **Edit**.
2. To create a template, press **Add a new template** and define it like a categorization.
3. To transfer templates between computers or users, press **Export templates** and later use **Import templates**.
4. To store an existing dataset categorization as a template, right-click the selected categorization in the parameter checkbox tree on the left side of ResultsViewer.

**Store as template** is implemented for Full table user-defined columns. Summarized-table templates are not documented here because the summarized helper code does not implement storing them yet.

!!! warning
    Filters and categorizations are synced between the main Irbis app and ResultsViewer, but generated data itself is not. If you change or generate data in the main app, close and reopen ResultsViewer to sync changes.

## Related

- Track categorizations are described in [Define and edit track categorizations](../tracks/categorize-tracks.md).
- Use merged identifiers in [Use ResultsViewer table views and plots](modes-plots.md).

