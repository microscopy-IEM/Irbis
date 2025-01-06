function booleanList = isWithinFilters(storedFilters, T)

    filterTable = storedFilters.updateAllFilterTables(T, table(), 1);  % table, each column contains boolean values
    booleanList = all(table2array(filterTable), 2);

end