function randomSentence = generateRandomText()
    % Predefined lists of words
    subjects = {'The cat', 'A dog', 'This tool', 'That idea', 'A person', 'The car'};
    verbs = {'jumps', 'runs', 'flies', 'drives', 'walks', 'dances'};
    adjectives = {'quickly', 'slowly', 'beautifully', 'awkwardly', 'elegantly'};
    objects = {'over the fence', 'through the field', 'in the house', 'with grace', 'on the road'};
    
    % Generate a random sentence length between 4 to 6 words
    sentenceLength = randi([4,6]);
    numberOfSentences = randi([1,4]);
    
    randomSentence = '';

    for i=1:numberOfSentences
        % Initialize randomText
        randomText = '';
    
        % Depending on the sentence length, assemble a sentence
        switch sentenceLength
            case 4 % Subject, Verb, Adjective, Object
                randomText = sprintf('%s %s %s %s.', subjects{randi(numel(subjects))}, ...
                    verbs{randi(numel(verbs))}, adjectives{randi(numel(adjectives))}, ...
                    objects{randi(numel(objects))});
            case 5 % Subject, Verb, Adverb, Adjective, Object
                adverbs = {'very', 'somewhat', 'extremely', 'barely', 'not'};
                randomText = sprintf('%s %s %s %s %s.', subjects{randi(numel(subjects))}, ...
                    verbs{randi(numel(verbs))}, adverbs{randi(numel(adverbs))}, ...
                    adjectives{randi(numel(adjectives))}, objects{randi(numel(objects))});
            otherwise % Subject, Verb, Object (simpler structure)
                randomText = sprintf('%s %s %s.', subjects{randi(numel(subjects))}, ...
                    verbs{randi(numel(verbs))}, objects{randi(numel(objects))});
        end

        randomSentence = [randomSentence ' ' randomText];
        % disp(randomSentence)
    end
end