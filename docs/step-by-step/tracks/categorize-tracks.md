# Define and edit track categorizations

!!! info "Before you start"
    **Prerequisites:**

    - TrackMate `.xml` data loaded in Irbis.

    **UI location:**

    - Main app: **Tracks** tab, **Categorization** section.

## Define a simple categorization

Simple categorization is based on one numerical parameter.

1. Select the parameter from the first drop-down menu in **Categorization**.
2. Fill thresholds into **th1**, **th2**, and **th3**.
3. Use up to three thresholds to create up to four categories.
4. If you need fewer categories, fill unused threshold fields with values outside the parameter range.
5. Press **Apply**.

## Define a complex categorization

Complex categorizations can combine multiple numerical and categorical parameters.

1. Press **Add categorization**.
2. In the dialog, enter the categorization name.
3. Define each category in its own box. Two boxes appear by default.
4. Press **Add category** to add more categories.
5. Rename each category in its category-name field.
6. Add conditions inside each category box. Each condition line contains a parameter, relation, value, and delete button.
7. Use relations such as **equals**, **lessThan**, and **greaterThan**.
8. Press **Add criteria** to add more conditions.
9. Press **Save categorization**.

## Delete a categorization

1. Select the categorization from the drop-down menu.
2. Press **Delete grouping**.

## Related

- ResultsViewer has a separate [Define ResultsViewer categorization](../results-viewer/categorize-data.md) workflow.

!!! example "Screenshot placeholder"
    Add screenshots of simple thresholds and the Add categorization dialog.


