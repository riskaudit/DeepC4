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
k = 25; % no of nearest node to be connected with
tic, [A_batch] = createGraph(X_batch,nelem,k); toc % Elapsed time is 118.840301 seconds.

% Initialize Parameters
numInputFeatures = size(X_batch{1,1},2);
seed_random = 1;
[parameters] = initializeDL(numInputFeatures,seed_random);

% Learning Parameters
learnRate = 1e-3;
numEpochs = 200;
nBatch = 30;

% Trailing Variables
trailingAvg = [];
trailingAvgSq = [];

% Enable Monitor Window
monitor = trainingProgressMonitor;
monitor.Metrics = [ "PredictionLoss", ...
                    "IterationTPpropR", ...
                    "IterationTPpropH", ...
                    "IterationTPpropW"];
monitor.XLabel = "Iteration";
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
parameters_history = cell(numEpochs,nBatch);
xTPpropR_history = zeros(numEpochs,nBatch);
xTPpropH_history = zeros(numEpochs,nBatch);
xTPpropW_history = zeros(numEpochs,nBatch);
BatchTPpropR_history = zeros(numEpochs,1);
BatchTPpropH_history = zeros(numEpochs,1);
BatchTPpropW_history = zeros(numEpochs,1);
PredictionLoss_history = zeros(numEpochs,nBatch);

% Learning
epoch = 0; iter = 0; xIter = 0;
while epoch < numEpochs && ~monitor.Stop
    epoch = epoch + 1
    xBatchTPpropR = [];
    xBatchTPpropH = [];
    xBatchTPpropW = [];
 
    for iter = 3:3 %1:nBatch
        iter
        if epoch == 1 
            gradients_prev = [];
        end


        % Evaluate loss and gradients.
        [   loss, gradients, xTPprop, xTPpropH, xTPpropW] = ...
            ...
            dlfeval(@modelLossV2,...
                    parameters,...
                    dlarray(X_batch{iter}), ...
                    A_batch{iter, 1}, ...
                    tau_batch{iter},...
                    tauH_batch{iter},...
                    tauW_batch{iter},...
                    btype_label,...
                    label_height,...
                    ind_batch{iter},...
                    gradients_prev);
        gradients_prev = gradients;


        % Save metrics for window
        xBatchTPpropR = [xBatchTPpropR; 
                        xTPpropR.*nelem(iter)./sum(nelem)];
        xBatchTPpropH = [xBatchTPpropH; 
                        xTPpropH.*nelem(iter)./sum(nelem)];
        xBatchTPpropW = [xBatchTPpropW; 
                        xTPpropW.*nelem(iter)./sum(nelem)];
        xTPpropR_history(epoch,iter) = xTPpropR;
        xTPpropH_history(epoch,iter) = xTPpropH;
        xTPpropW_history(epoch,iter) = xTPpropW;
        PredictionLoss_history(epoch,iter) = loss;

        % Update learnable parameters.
        [parameters,trailingAvg,trailingAvgSq] = adamupdate(parameters,gradients, ...
            trailingAvg,trailingAvgSq,(epoch-1).*nBatch+iter,learnRate);
        parameters_history{epoch,iter} = parameters;

        % Record metrics
        recordMetrics(monitor, ...
            (epoch-1).*nBatch+iter, ...
            PredictionLoss=loss, ...
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