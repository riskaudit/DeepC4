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
[  X_batch, tau_batch, tauH_batch, tauW_batch, ...
    btype_label, label_height, ind_batch, nelem] = ...
    loadTrainData(optloadTrainData, ...
    mask, label2rasterID, sub_label2rasterID,...
    s1vv, s1vh, rgb, red1, red2, red3, red4, swir1, swir2, nir,...
    dynProb, dynLabel, btype_label, label_height, bldgftprnt,...
    Q,data);


%% Graph Convolutional Autoencoder

% Create Graph
tic, [A_batch] = createGraph(X_batch,nelem); toc % Elapsed time is 118.840301 seconds.

% Initialize Parameters
numInputFeatures = size(X_batch{1,1},2);
seed_random = 24;
[parameters] = initializeDL(numInputFeatures,labelsTrain,seed_random);

% Learning Parameters
learnRate = 1e-3;
numEpochs = 200;
nBatch = 30;
gradDecay = 0.8;
sqGradDecay = 0.95;

% Trailing Variables
trailingAvgE = [];
trailingAvgSqE = [];
trailingAvgD = [];
trailingAvgSqD = [];

% Enable Monitor Window
monitor = trainingProgressMonitor;
monitor.Metrics = [ "ReconstructionLoss", ...
                    "PredictionLoss", ...
                    "IterationTPpropR", ...
                    "IterationTPpropH", ...
                    "IterationTPpropW"];
monitor.XLabel = "Iteration";
groupSubPlot(monitor,"ReconstructionLoss","ReconstructionLoss");
groupSubPlot(monitor,"PredictionLoss","PredictionLoss");
groupSubPlot(monitor,"IterationTPpropR","IterationTPpropR");
groupSubPlot(monitor,"IterationTPpropH","IterationTPpropH");
groupSubPlot(monitor,"IterationTPpropW","IterationTPpropW");
monitor1 = trainingProgressMonitor;
monitor1.Metrics = ["BatchTPpropR","BatchTPpropH","BatchTPpropW"];
monitor1.XLabel = "Epoch";
groupSubPlot(monitor1,"BatchTPpropR","BatchTPpropR");
groupSubPlot(monitor1,"BatchTPpropH","BatchTPpropH");
groupSubPlot(monitor1,"BatchTPpropW","BatchTPpropW");

% Initialize Learning History
netE_history = cell(numEpochs,nBatch);
netD_history = cell(numEpochs,nBatch);
xTPpropR_history = zeros(numEpochs,nBatch);
xTPpropH_history = zeros(numEpochs,nBatch);
xTPpropW_history = zeros(numEpochs,nBatch);
BatchTPpropR_history = zeros(numEpochs,1);
BatchTPpropH_history = zeros(numEpochs,1);
BatchTPpropW_history = zeros(numEpochs,1);
ReconstructionLoss_history = zeros(numEpochs,nBatch);
PredictionLoss_history = zeros(numEpochs,nBatch);

% Learning
epoch = 0; iter = 0; xIter = 0;
while epoch < numEpochs && ~monitor.Stop
    epoch = epoch + 1
    xBatchTPpropR = [];
    xBatchTPpropH = [];
    xBatchTPpropW = [];
    if epoch == 1
        loss2_prev = ones(nBatch,1);
        loss3_prev = ones(nBatch,1);
    end
 
    for iter = 1:nBatch
        iter, j = iter;
        if epoch == 1 && iter == 1
            gradientsE_prev = [];
            gradientsD_prev = [];
        elseif epoch == 1
            labelsLocal_prev = [];
            labelsLocalH_prev = [];
            labelsLocalW_prev = [];
        end

        % Normalize A
        ANorm = normalizeAdjacency(A_batch{iter, 1});
        
        % Evaluate loss and gradients.
        [loss2,loss3,...
            xTPpropR,xTPpropH,xTPpropW,...
            gradientsE,gradientsD,...
            labelsLocal_prev,labelsLocalH_prev,labelsLocalW_prev] = ...
            dlfeval(@modelLossV2,...
                    parameters,...
                    dlarray(X_batch{iter}, 'BC'), ...
                    ANorm, ...
                    tau_batch{iter},...
                    tauH_batch{iter},...
                    tauW_batch{iter},...
                    btype_label,...
                    label_height,...
                    ind_batch{iter}, ...
                    nelem,...
                    nelem(iter));





        
        loss2_prev(iter,1) = loss2;
        loss3_prev(iter,1) = loss3;
        gradientsE_prev = gradientsE;
        gradientsD_prev = gradientsD;
        xBatchTPpropR = [xBatchTPpropR; 
                        xTPpropR.*nelem(iter)./sum(nelem)];
        xBatchTPpropH = [xBatchTPpropH; 
                        xTPpropH.*nelem(iter)./sum(nelem)];
        xBatchTPpropW = [xBatchTPpropW; 
                        xTPpropW.*nelem(iter)./sum(nelem)];
        xTPpropR_history(epoch,iter) = xTPpropR;
        xTPpropH_history(epoch,iter) = xTPpropH;
        xTPpropW_history(epoch,iter) = xTPpropW;
        ReconstructionLoss_history(epoch,iter) = loss2;
        PredictionLoss_history(epoch,iter) = loss3;

        % Update learnable parameters.
        [netE,trailingAvgE,trailingAvgSqE] = adamupdate(netE, ...
            gradientsE,trailingAvgE,trailingAvgSqE,...
            (epoch-1).*nBatch+j,learnRate,gradDecay,sqGradDecay);
        netE_history{epoch,iter} = netE;

        [netD, trailingAvgD, trailingAvgSqD] = adamupdate(netD, ...
            gradientsD,trailingAvgD,trailingAvgSqD,...
            (epoch-1).*nBatch+j,learnRate,gradDecay,sqGradDecay);
        netD_history{epoch,iter} = netD;

        recordMetrics(monitor, ...
            (epoch-1).*nBatch+j, ...
            ReconstructionLoss=loss2, ...
            PredictionLoss=loss3, ...
            IterationTPpropR=xTPpropR, ...
            IterationTPpropH=xTPpropH, ...
            IterationTPpropW=xTPpropW);

    end
    recordMetrics(monitor1, ...
            epoch, ...
            BatchTPpropR=sum(xBatchTPpropR), ...
            BatchTPpropH=sum(xBatchTPpropH), ...
            BatchTPpropW=sum(xBatchTPpropW));
    BatchTPpropR_history(epoch,1) = sum(xBatchTPpropR);
    BatchTPpropH_history(epoch,1) = sum(xBatchTPpropH);
    BatchTPpropW_history(epoch,1) = sum(xBatchTPpropW);

end


save("output/20241017_JointDC_WeightedLossAcrossClasses/outputTrainedModels.mat",... 
    "netE_history","netD_history",...
    "xTPpropR_history","xTPpropH_history","xTPpropW_history",...
    "BatchTPpropR_history","BatchTPpropH_history","BatchTPpropW_history",...
    "ReconstructionLoss_history","PredictionLoss_history")

%% Determine the optimal iter and epoch

% Upon inspection, desirable reconstruction loss <= 5 (MSE)
target_epochs = find(sum(ReconstructionLoss_history<=0.9,2)>0 ...
                & sum(PredictionLoss_history<=0.5,2)>0);
target_epochs = target_epochs(target_epochs >= 150);

% Refine selection using TPprop for Roof, Height, and Wall
averageTPprop = BatchTPpropR_history(target_epochs,1)./3 + ... 
                BatchTPpropH_history(target_epochs,1)./3 + ...
                BatchTPpropW_history(target_epochs,1)./3;
final_epoch   = target_epochs(averageTPprop==max(averageTPprop));
target_iters  = 1:30;
averageXTPprop = xTPpropR_history(final_epoch,:)./3 + ... 
                 xTPpropH_history(final_epoch,:)./3 + ...
                 xTPpropW_history(final_epoch,:)./3;
final_iter    = target_iters(averageXTPprop==max(averageXTPprop));