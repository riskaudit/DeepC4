function [loss,gradients] = modelLossV2(parameters,X,ANorm,T)

    Z = model(parameters,X,ANorm);
    
    loss = crossentropy(Y,T,DataFormat="BC") ...
            + crossentropy(Yprime,Y,DataFormat="BC");


    gradients = dlgradient(loss, parameters);

end

