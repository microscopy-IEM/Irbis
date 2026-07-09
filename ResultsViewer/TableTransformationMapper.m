classdef (Sealed) TableTransformationMapper
    methods (Static)
        function transform = getTransformation(transformationName, parameterValue)

            arguments
                transformationName
                parameterValue = []  % Optional parameter for transformations that require it
            end

            disp(['Getting transformation for: ', transformationName]);

            switch transformationName
                case 'none'
                    transform.dataFcn = @(A) A;
                    transform.nameFcn = @(names) names;

                case 'detrend'
                    transform.dataFcn = @(A) detrend(A')';  % transformation added because detrend operates on columns, so we transpose twice to apply it to rows
                    transform.nameFcn = @(names) "detrended_" + names;

                case 'percChangeToFirst'
                    transform.dataFcn = @(A) (A - A(:, 1)) ./ A(:, 1) * 100;
                    transform.nameFcn = @(names) "percChange_" + names + "_to_" + names(1);

                case 'ratioToBaselineMean'
                    transform.dataFcn = @(A) A ./ mean(A(:, 1), 'omitnan');
                    transform.nameFcn = @(names) "ratio_" + names + "_to_baselineMean";

                case 'ratioToFirst'
                    transform.dataFcn = @(A) A ./ A(:, 1);
                    transform.nameFcn = @(names) "ratio_" + names + "_to_" + names(1);

                case 'subtractFirst'
                    transform.dataFcn = @(A) A - A(:, 1);
                    transform.nameFcn = @(names) names + "_minus_" + names(1);

                case 'subtractPrevious'
                    transform.dataFcn = @(A) diff(A, 1, 2);
                    transform.nameFcn = @(names) names(2:end) + "_minus_" + names(1:end-1);

                case 'spec_differenceFromSelected'
                    if isempty(parameterValue)
                        parameterValue = 2;
                    end
                    transform.dataFcn = @(A) A - A(:, parameterValue);
                    transform.nameFcn = @(names) names + "_minus_" + names(parameterValue);
                
                case 'spec_movingMean'
                    if isempty(parameterValue)
                        parameterValue = 3; % Default window size
                    end
                    disp(parameterValue)
                    transform.dataFcn = @(A) movmean(A, parameterValue, 2);
                    transform.nameFcn = @(names) "movingMean_" + names;

                case 'spec_ratioToSelected'
                    if isempty(parameterValue)
                        parameterValue = 2; % Default to the second column if no parameter is provided
                    end
                    transform.dataFcn = @(A) A ./ A(:, parameterValue);
                    transform.nameFcn = @(names) "ratio_" + names + "_to_" + names(parameterValue);

                otherwise
                    error('Unknown transformation name: %s', transformationName);
            end
        end
    end
end
