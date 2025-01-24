classdef test_hello_world < matlab.unittest.TestCase
    methods(Test)
        function testHelloWorld(testCase)
            expectedOutput = 'Hello, World!';
            actualOutput = helloWorldFunction(); % Assuming helloWorldFunction is defined elsewhere
            testCase.verifyEqual(actualOutput, expectedOutput);
        end
    end
end