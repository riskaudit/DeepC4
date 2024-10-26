function [Z] = model(parameters,X,ANorm)
    
    % autoencoder neural network
    Z1 = X;
    Z2 = ANorm * Z1 * parameters.mult1.Weights;
    Z2 = relu(Z2); 
    Z3 = ANorm * Z2 * parameters.mult2.Weights;
    Z3 = relu(Z3);
    Z4 = ANorm * Z3 * parameters.mult3.Weights;
    Z4 = relu(Z4);
    Z5 = ANorm * Z4 * parameters.mult4.Weights;
    Z5 = relu(Z5); 
    Z = ANorm * Z5 * parameters.mult5.Weights; 
  
end