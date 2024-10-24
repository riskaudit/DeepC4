function [parameters] = initializeDL(numInputFeatures,seed_random)

    parameters = struct;

    % 14 - > 12
    numIn = numInputFeatures; % 14
    numOut = 12;
    sz = [numInputFeatures numOut];
    parameters.mult1.Weights = initializeGlorot(sz,seed_random,numOut,numIn,"double");
    
    % 12 -> 10
    numIn = 12;
    numOut = 10;
    sz = [numIn numOut];
    parameters.mult2.Weights = initializeGlorot(sz,seed_random,numOut,numIn,"double");
    
    % 10 -> 8
    numIn = 10;
    numOut = 8;
    sz = [numIn numOut];
    parameters.mult3.Weights = initializeGlorot(sz,seed_random,numOut,numIn,"double");
    
    % 8 -> 6
    numIn = 8;
    numOut = 6;
    sz = [numIn numOut];
    parameters.mult4.Weights = initializeGlorot(sz,seed_random,numOut,numIn,"double");
    
    % 6 -> 3
    numIn = 6;
    numOut = 3;
    sz = [numIn numOut];
    parameters.mult5.Weights = initializeGlorot(sz,seed_random,numOut,numIn,"double");

end

