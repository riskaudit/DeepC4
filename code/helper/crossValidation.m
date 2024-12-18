%% Cross-Validation

load("output/20241111_DeepC4/input.mat",... ...
    "X_batch","tau_batch","tauH_batch","tauW_batch","btype_label","label_height","ind_batch","nelem")

% Learning Parameters
learnRate = 1e-3;
numEpochs = 200;
select_iter = [2:12 14:15 18:21 24 26 28];
rng(1); cv_idx = randperm(20);

for k = 1:5

    cv_idx_test = cv_idx(4.*(k-1)+1:4*k);
    cv_idx_train = setxor(cv_idx,cv_idx_test);
    nBatch = length(cv_idx_train);
    
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
        
        for j = 1:length(cv_idx_train) %1:nBatch
            iter = select_iter(cv_idx_train(j))
    
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
                        gradientsE_prev, gradientsD_prev, ...
                        true);
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
    save("output/20241111_DeepC4/crossvalidation/outputTrainedModels_"+k+".mat",... 
        "netE_history","netD_history",...
        "cv_idx_train","cv_idx_test",...
        "xTPpropR_history","xTPpropH_history","xTPpropW_history",...
        "xTPpropR2_history","xTPpropH2_history","xTPpropW2_history",...
        "ReconstructionLoss_history","PredictionLoss_history")

end



% Evaluate test metric
numEpochs = 1;
nBatch = 20;
xTPpropR_history_test = zeros(numEpochs,nBatch);
xTPpropH_history_test = zeros(numEpochs,nBatch);
xTPpropW_history_test = zeros(numEpochs,nBatch);
xTPpropR2_history_test = zeros(numEpochs,nBatch);
xTPpropH2_history_test = zeros(numEpochs,nBatch);
xTPpropW2_history_test = zeros(numEpochs,nBatch);
iter_history_test = zeros(numEpochs,nBatch);
nelem_history_test = zeros(numEpochs,nBatch);
for k = 1:5

    % load parameter
    load("output/20241111_DeepC4/crossvalidation/outputTrainedModels_"+k+".mat",... 
        "netE_history","netD_history",...
        "cv_idx_train","cv_idx_test",...
        "xTPpropR_history","xTPpropH_history","xTPpropW_history",...
        "xTPpropR2_history","xTPpropH2_history","xTPpropW2_history",...
        "ReconstructionLoss_history","PredictionLoss_history")

    % determine optimal epch and iter
    lossR_byepoch = sum(ReconstructionLoss_history'...
        .*nelem(select_iter(cv_idx_train)'))'...
        ./sum(nelem(select_iter(cv_idx_train)'));
    plot(lossR_byepoch)
    possible_epochs_basedonlossR = (lossR_byepoch <= quantile(lossR_byepoch,0.5));

    lossP_byepoch = sum(PredictionLoss_history'...
        .*nelem(select_iter(cv_idx_train)'))'...
        ./sum(nelem(select_iter(cv_idx_train)'));
    plot(lossP_byepoch)

    possible_epochs_basedonlossR = (lossR_byepoch <= quantile(lossR_byepoch,0.5));
    possible_epochs_basedonlossP = (lossP_byepoch <= quantile(lossP_byepoch,0.5));
    joint_possible_epochs_basedonlossRP = find(possible_epochs_basedonlossR & possible_epochs_basedonlossP);

    xTPpropR_byepoch = sum(xTPpropR_history'...
        .*nelem(select_iter(cv_idx_train)'))'...
        ./sum(nelem(select_iter(cv_idx_train)'));
    % plot(xTPpropR_byepoch)
    xTPpropH_byepoch = sum(xTPpropH_history'...
        .*nelem(select_iter(cv_idx_train)'))'...
        ./sum(nelem(select_iter(cv_idx_train)'));
    % plot(xTPpropH_byepoch)
    xTPpropW_byepoch = sum(xTPpropW_history'...
        .*nelem(select_iter(cv_idx_train)'))'...
        ./sum(nelem(select_iter(cv_idx_train)'));
    % plot(xTPpropW_byepoch)

    xTPprop_byepoch = ...
        xTPpropR_byepoch(joint_possible_epochs_basedonlossRP)./3 + ...
        xTPpropH_byepoch(joint_possible_epochs_basedonlossRP)./3 + ...
        xTPpropW_byepoch(joint_possible_epochs_basedonlossRP)./3;
    joint_possible_epochs_basedonlossRP(xTPprop_byepoch==max(xTPprop_byepoch))

    xTPpropR2_byepoch = sum(xTPpropR2_history'...
        .*nelem(select_iter(cv_idx_train)'))'...
        ./sum(nelem(select_iter(cv_idx_train)'));
    % plot(xTPpropR2_byepoch)
    xTPpropH2_byepoch = sum(xTPpropH2_history'...
        .*nelem(select_iter(cv_idx_train)'))'...
        ./sum(nelem(select_iter(cv_idx_train)'));
    % plot(xTPpropH2_byepoch)
    xTPpropW2_byepoch = sum(xTPpropW2_history'...
        .*nelem(select_iter(cv_idx_train)'))'...
        ./sum(nelem(select_iter(cv_idx_train)'));
    % plot(xTPpropW2_byepoch)

    xTPprop2_byepoch = ...
        xTPpropR2_byepoch(joint_possible_epochs_basedonlossRP)./3 + ...
        xTPpropH2_byepoch(joint_possible_epochs_basedonlossRP)./3 + ...
        xTPpropW2_byepoch(joint_possible_epochs_basedonlossRP)./3;

    xTPprop_byepoch_combined = xTPprop_byepoch./2 + xTPprop2_byepoch./2;
    selected_epoch = joint_possible_epochs_basedonlossRP(xTPprop_byepoch_combined==max(xTPprop_byepoch_combined));

    % figure(1); fig = plot(lossR_byepoch); 
    % grid on; xlabel('Epoch'); ylabel('Reconstruction Loss'); 
    % title('Reconstruction Loss for CV Model '+ string(k))
    % saveas(fig, 'output/20241025_DeepGC4/crossvalidation/figure/lossR_cvModel_'+string(k)+'.png')
    
    netE = netE_history{selected_epoch,end};
    netD = netD_history{selected_epoch,end};


    for j = 1:length(cv_idx_test) %1:nBatch
        iter = select_iter(cv_idx_test(j))
    
        % Evaluate loss and gradients.
        [   ~,~,...
            xTPpropR,xTPpropH,xTPpropW,...
            xTPpropR2,xTPpropH2,xTPpropW2,...
            ~,~] = ...
            dlfeval(@modelLoss,...
                    netE,netD,...
                    dlarray(X_batch{iter}, 'BC'), ...
                    tau_batch{iter},...
                    tauH_batch{iter},...
                    tauW_batch{iter},...
                    btype_label,...
                    label_height,...
                    ind_batch{iter}, ...
                    [], [], ...
                    false);
    
        iter_history_test(1,(k-1).*4+j) = iter;
        nelem_history_test(1,(k-1).*4+j) = nelem(iter);
        xTPpropR_history_test(1,(k-1).*4+j) = xTPpropR;
        xTPpropH_history_test(1,(k-1).*4+j) = xTPpropH;
        xTPpropW_history_test(1,(k-1).*4+j) = xTPpropW;
        xTPpropR2_history_test(1,(k-1).*4+j) = xTPpropR2;
        xTPpropH2_history_test(1,(k-1).*4+j) = xTPpropH2;
        xTPpropW2_history_test(1,(k-1).*4+j) = xTPpropW2;

    end
end

% for saving
save("output/20241111_DeepC4/crossvalidation/crossvalidationTest.mat",... 
    "xTPpropR_history_test","xTPpropH_history_test","xTPpropW_history_test",...
    "xTPpropR2_history_test","xTPpropH2_history_test","xTPpropW2_history_test",...
    "iter_history_test","nelem_history_test")

% for saving
load("output/20241111_DeepC4/crossvalidation/crossvalidationTest.mat",... 
    "xTPpropR_history_test","xTPpropH_history_test","xTPpropW_history_test",...
    "xTPpropR2_history_test","xTPpropH2_history_test","xTPpropW2_history_test",...
    "iter_history_test","nelem_history_test")

a = zeros(5,1);
b = zeros(5,1);
c = zeros(5,1);
d = zeros(5,1);
e = zeros(5,1);
f = zeros(5,1);
for k = 1:5

    % load parameter
    load("output/20241111_DeepC4/crossvalidation/outputTrainedModels_"+k+".mat",... 
        "cv_idx_train","cv_idx_test")

    %
    iters = select_iter(cv_idx_test);
    [~,idx] = intersect(iter_history_test,iters);
    
    % for reporting - training scores
    a(k,1) = sum(xTPpropR_history_test(idx).*nelem_history_test(idx))./sum(nelem_history_test(idx));
    b(k,1) = sum(xTPpropH_history_test(idx).*nelem_history_test(idx))./sum(nelem_history_test(idx));
    c(k,1) = sum(xTPpropW_history_test(idx).*nelem_history_test(idx))./sum(nelem_history_test(idx));
    d(k,1) = sum(xTPpropR2_history_test(idx).*nelem_history_test(idx))./sum(nelem_history_test(idx));
    e(k,1) = sum(xTPpropH2_history_test(idx).*nelem_history_test(idx))./sum(nelem_history_test(idx));
    f(k,1) = sum(xTPpropW2_history_test(idx).*nelem_history_test(idx))./sum(nelem_history_test(idx));

end
mean(a) % 98.80
mean(b) % 95.61
mean(c) % 95.55
mean(d) % 98.62
mean(e) % 10.34
mean(f) % 56.12