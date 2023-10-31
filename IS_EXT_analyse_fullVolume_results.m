
selpath = uigetdir();
disp(selpath)

cd(selpath)
listFiles = dir('*.csv');

num_csv = size(listFiles,1);
for i=1:num_csv
    disp(listFiles(i).name)
    disp(size(listFiles))
    
    
    T = readtable(listFiles(i).name);
    
    
    scatter(T.timePoint,T.volume,'filled')
    hold on
end

hold off

path_with_mmpack = uigetdir();

cd(path_with_mmpack)
