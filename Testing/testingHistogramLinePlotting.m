% Example data
data = randn(1000, 1);  % Normally distributed random data

% Create histogram data
[binCounts, binEdges] = histcounts(data, 20);  % 20 bins

% Convert bin edges to bin centers (for x-values)
binCenters = (binEdges(1:end-1) + binEdges(2:end)) / 2;

% Add optional jitter (set jitter to 0 if no jitter is required)
jitter = 0.5;  % Adjust jitter size as needed
jitterValues = jitter * randn(size(binCounts));  % Small random noise

% Line plot with jitter
figure;
plot(binCenters, binCounts, '-', 'LineWidth', 2);
hold("on")
plot(binCenters, binCounts + jitterValues, '-', 'LineWidth', 2);
hold("off")
xlabel('Data Bins');
ylabel('Counts');
title('Line Plot from Histogram with Jitter');