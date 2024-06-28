clc

testStruct = struct();

testStruct.a = [0,10];
testStruct.b = [10,20];

disp(testStruct)
whos("testStruct")

% testTwo = @testStruct;
% disp(testTwo)
% whos("testTwo")

testStructHandle = StructHandle(testStruct);

disp(testStruct)
whos("testStructHandle")
testStructHandle.data


% testStruct.c = 'testing';
% 
% disp(testStruct)
% disp(testTwo)

% test3 = cast(testStruct,"handle") % not possible



