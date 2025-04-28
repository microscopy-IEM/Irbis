classdef (Sealed) TableComponentFactory
    methods (Static)
        function tableComponent = createComponent(componentType, container)

            switch componentType
                case 'Full'
                    tableComponent = fullTableComponent(container);
                case 'Pivoted'
                    tableComponent = pivotedTableComponent(container);
                case 'Summarized'
                    tableComponent = summarizedTableComponent(container);
            end

            % propagate the handles to the table component - done later, outside of this method
                % separate from the constructor because Matlab custom UI components do not accept constructor arguments
        end
    end
end



% changing the type of the first table shown
% full - the original view
    % rows - individual objects 
    % columns - any parameters selected from the uicheckboxtree
    % previous version - labelled as 'tp'
% pivoted - one parameter on row, one on column, table filled with summarized values of the third parameter
    % rows - any categorical/scalar/logical parameter (default for model is categorical - groupId)
    % columns - any categorical/scalar/logical parameter (default is timePoint)
    % previous version - labelled as 'par'
% summarized - needs to be defined first
    % rows - categorical parameter (default - groupId)
    % columns - any statistical summary/categorization defined for groups 
    % default - statistical summary over timePoints
