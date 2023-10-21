clc;

tracks

x = [];
y = [];
z = [];



for tr = 1:size(tracks.tracksList,1)

x = [x; tracks.tracksList(1,:).xyz{1}(:,1)];
y = [y; tracks.tracksList(1,:).xyz{1}(:,2)];
z = [z; tracks.tracksList(1,:).xyz{1}(:,3)];

end

storm.x = x;
storm.y = y;
storm.z = z;
