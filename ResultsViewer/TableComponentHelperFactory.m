classdef (Sealed) TableComponentHelperFactory
    methods (Static)
        function helper = create(componentType)

            switch componentType
                case 'Full'
                    helper = FullTableComponentHelper();
                case 'Pivoted'
                    helper = PivotedTableComponentHelper();
                case 'Summarized'
                    helper = SummarizedTableComponentHelper();
                otherwise
                    error('Unknown component type: %s', componentType);
            end
        end
    end
end