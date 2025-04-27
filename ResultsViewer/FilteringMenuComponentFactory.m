classdef (Sealed) FilteringMenuComponentFactory
    methods (Static)
        function component = create(tableType, container)
            % disp('In FilteringMenuComponentFactory.create()')

            switch tableType
                case 'Summarized'
                    component = summarized_filteringMenuComponent(container);
                otherwise
                    component = filteringMenuComponent(container);
            end
            % switch tableType
            %     case 'Full'
            %         component = fullTableFilteringMenuComponent(container);
            %     case 'Pivoted'
            %         component = pivotedTableFilteringMenuComponent(container);
            %     case 'Summarized'
            %         component = summarizedTableFilteringMenuComponent(container);
            % end

            % propagate the handles to the table component - done later, outside of this method
                % separate from the constructor because Matlab custom UI components do not accept constructor arguments
        end
    end 
end