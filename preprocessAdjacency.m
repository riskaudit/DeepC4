function [ANorm] = preprocessAdjacency(An,Aa,)


    ATrain = (Aa.Aattribute_cosine(idxTrain,idxTrain)>0.5) ...
        & An.Aspatial{iN,1}(idxTrain,idxTrain);

    % Compute inverse square root of degree.
    degree = sum(ATrain, 2);
    degreeInvSqrt = sparse(sqrt(1./degree));
    
    % Normalize adjacency matrix.
    ANorm = diag(degreeInvSqrt) * ATrain * diag(degreeInvSqrt);


end

