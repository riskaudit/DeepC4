function [netE,netD] = createAE()

layersE = [
    featureInputLayer(14) 

    fullyConnectedLayer(12)
    eluLayer
    layerNormalizationLayer

    fullyConnectedLayer(10)
    eluLayer
    layerNormalizationLayer

    fullyConnectedLayer(8)
    eluLayer
    layerNormalizationLayer

    fullyConnectedLayer(6)
    eluLayer
    layerNormalizationLayer

    fullyConnectedLayer(3)
    sigmoidLayer];

layersD = [
    featureInputLayer(3)

    fullyConnectedLayer(6)
    eluLayer
    layerNormalizationLayer

    fullyConnectedLayer(8)
    eluLayer
    layerNormalizationLayer

    fullyConnectedLayer(10) 
    eluLayer
    layerNormalizationLayer

    fullyConnectedLayer(12)
    eluLayer
    layerNormalizationLayer

    fullyConnectedLayer(14)]; 


netE = dlnetwork(layersE);
netD = dlnetwork(layersD);


end

