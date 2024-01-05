closeall; clear all 


data = randn(100);
[counts,edges] = histcounts(data);

max(edges)
app.UIObjectFilter_spines.XLim = [min(edges) max(edges)];

histogram('BinEdges',edges,'BinCounts',counts,'Normalization','probability');


sizeSelectorRoi.DrawingArea = [min(edges),-0.1,max(edges),0.7];
sizeSelectorRoi.Position = [min(edges),-0.1,max(edges),0.7];