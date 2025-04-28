classdef (Sealed) TableProcessorFactory
    methods (Static)
        function processor = createProcessor(componentType)

            % disp('Creating table processor...');
            % componentType
            % dataStoreObject

            switch componentType
                case 'Full'
                    processor = FullTableProcessor();
                case 'Pivoted'
                    processor = PivotedTableProcessor();
                case 'Summarized'
                    processor = SummarizedTableProcessor();
                otherwise
                    error('Unknown component type: %s', componentType);
            end
        end
    end
end
