%% Initialize
clear, clc, close
cd '/Users/joshuadimasaka/Desktop/PhD/GitHub/DeepC4'

%% Load Full Country Data
[   mask, maskR,...
    label2rasterID, sub_label2rasterID,...
    s1vv, s1vh, rgb, red1, red2, red3, red4, swir1, swir2, nir,...
    dynProb, dynLabel, btype_label, label_height, bldgftprnt,...
    Q,data...
    ] = loadCountryData();

%% Run [1] or Load [2] Training Data (30 sectors)
optloadTrainData = 2;
[   X_batch, tau_batch, tauH_batch, tauW_batch, ...
    btype_label, label_height, ind_batch, nelem] = ...
    loadTrainData(optloadTrainData, ...
    mask, label2rasterID, sub_label2rasterID,...
    s1vv, s1vh, rgb, red1, red2, red3, red4, swir1, swir2, nir,...
    dynProb, dynLabel, btype_label, label_height, bldgftprnt,...
    Q,data);

%% Deep Representation Learning

% Learning Parameters
learnRate = 1e-3;
numEpochs = 500;

% removed upon inspection to see if, at the sector level, learning exists
select_iter = [2:12 14:15 18:21 24 26 28];
nBatch = length(select_iter);

% Trailing Variables

trailingAvgE = [];
trailingAvgSqE = [];
trailingAvgD = [];
trailingAvgSqD = [];
gradientsE_prev = [];
gradientsD_prev = [];

% Enable Monitor Window
monitor = trainingProgressMonitor;
monitor.Metrics = [ "ReconstructionLoss", ...
                    "PredictionLoss", ...
                    "IterationTPpropR", ...
                    "IterationTPpropH", ...
                    "IterationTPpropW",...
                    "IterationTPpropR2", ...
                    "IterationTPpropH2", ...
                    "IterationTPpropW2"];
monitor.XLabel = "Iteration";
groupSubPlot(monitor,"ReconstructionLoss","ReconstructionLoss");
groupSubPlot(monitor,"PredictionLoss","PredictionLoss");
groupSubPlot(monitor,"IterationTPpropR","IterationTPpropR");
groupSubPlot(monitor,"IterationTPpropH","IterationTPpropH");
groupSubPlot(monitor,"IterationTPpropW","IterationTPpropW");
groupSubPlot(monitor,"IterationTPpropR2","IterationTPpropR2");
groupSubPlot(monitor,"IterationTPpropH2","IterationTPpropH2");
groupSubPlot(monitor,"IterationTPpropW2","IterationTPpropW2")

% Loop over epochs.
netE_history = cell(numEpochs,nBatch);
netD_history = cell(numEpochs,nBatch);
xTPpropR_history = zeros(numEpochs,nBatch);
xTPpropH_history = zeros(numEpochs,nBatch);
xTPpropW_history = zeros(numEpochs,nBatch);
xTPpropR2_history = zeros(numEpochs,nBatch);
xTPpropH2_history = zeros(numEpochs,nBatch);
xTPpropW2_history = zeros(numEpochs,nBatch);
ReconstructionLoss_history = zeros(numEpochs,nBatch);
PredictionLoss_history = zeros(numEpochs,nBatch);

% Train
epoch = 0; iter = 0; xIter = 0;
[netE,netD] = createAE();

while epoch < numEpochs && ~monitor.Stop
    epoch = epoch + 1
    
    for j = 1:length(select_iter) %1:nBatch
        iter = select_iter(j)

        % Evaluate loss and gradients.
        [   lossP,lossR,...
            xTPpropR,xTPpropH,xTPpropW,...
            xTPpropR2,xTPpropH2,xTPpropW2,...
            gradientsE,gradientsD] = ...
            dlfeval(@modelLoss,...
                    netE,netD,...
                    dlarray(X_batch{iter}, 'BC'), ...
                    tau_batch{iter},...
                    tauH_batch{iter},...
                    tauW_batch{iter},...
                    btype_label,...
                    label_height,...
                    ind_batch{iter}, ...
                    gradientsE_prev, gradientsD_prev);
        gradientsE_prev = gradientsE;
        gradientsD_prev = gradientsD;


        xTPpropR_history(epoch,j) = xTPpropR;
        xTPpropH_history(epoch,j) = xTPpropH;
        xTPpropW_history(epoch,j) = xTPpropW;
        xTPpropR2_history(epoch,j) = xTPpropR2;
        xTPpropH2_history(epoch,j) = xTPpropH2;
        xTPpropW2_history(epoch,j) = xTPpropW2;
        ReconstructionLoss_history(epoch,j) = lossR;
        PredictionLoss_history(epoch,j) = lossP;

        % Update learnable parameters.
        [netE,trailingAvgE,trailingAvgSqE] = adamupdate(netE, ...
            gradientsE,trailingAvgE,trailingAvgSqE,...
            (epoch-1).*nBatch+j,learnRate,gradDecay,sqGradDecay);
        netE_history{epoch,j} = netE;

        [netD, trailingAvgD, trailingAvgSqD] = adamupdate(netD, ...
            gradientsD,trailingAvgD,trailingAvgSqD,...
            (epoch-1).*nBatch+j,learnRate,gradDecay,sqGradDecay);
        netD_history{epoch,j} = netD;

        recordMetrics(monitor, ...
            (epoch-1).*nBatch+j, ...
            ReconstructionLoss=lossR, ...
            PredictionLoss=lossP, ...
            IterationTPpropR=xTPpropR, ...
            IterationTPpropH=xTPpropH, ...
            IterationTPpropW=xTPpropW, ...
            IterationTPpropR2=xTPpropR2, ...
            IterationTPpropH2=xTPpropH2, ...
            IterationTPpropW2=xTPpropW2);

    end
end

% global
save("output/20241025_DeepGC4/global/outputTrainedModels.mat",... 
    "netE_history","netD_history",...
    "xTPpropR_history","xTPpropH_history","xTPpropW_history",...
    "xTPpropR2_history","xTPpropH2_history","xTPpropW2_history",...
    "ReconstructionLoss_history","PredictionLoss_history")

