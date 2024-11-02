load("output/20240916_JointDC_Downstream1/input.mat",... ...
    "X_batch","tau_batch","tauH_batch","tauW_batch","btype_label","label_height","ind_batch","nelem")

load("output/20241025_DeepGC4/global/outputTrainedModels.mat",... 
    "netE_history","netD_history",...
    "xTPpropR_history","xTPpropH_history","xTPpropW_history",...
    "xTPpropR2_history","xTPpropH2_history","xTPpropW2_history",...
    "ReconstructionLoss_history","PredictionLoss_history")

numEpochs = 1;
select_iter = [2:12 14:15 18:21 24 26 28];
nBatch = length(select_iter);

xTPpropR_history_test = zeros(numEpochs,nBatch);
xTPpropH_history_test = zeros(numEpochs,nBatch);
xTPpropW_history_test = zeros(numEpochs,nBatch);
xTPpropR2_history_test = zeros(numEpochs,nBatch);
xTPpropH2_history_test = zeros(numEpochs,nBatch);
xTPpropW2_history_test = zeros(numEpochs,nBatch);
iter_history_test = zeros(numEpochs,nBatch);
nelem_history_test = zeros(numEpochs,nBatch);

% determine optimal epch and iter
lossR_byepoch = sum(ReconstructionLoss_history'.*nelem(select_iter))...
                ./sum(nelem(select_iter));
plot(lossR_byepoch);
figure(1); fig = plot(lossR_byepoch); 
grid on; xlabel('Epoch'); ylabel('Reconstruction Loss'); 
saveas(fig, 'output/20241025_DeepGC4/global/figure/lossR.png')
savefig('output/20241025_DeepGC4/global/figure/lossR.fig')


lossP_byepoch = sum(PredictionLoss_history'.*nelem(select_iter))...
                ./sum(nelem(select_iter));
plot(lossP_byepoch)

figure(1); fig = plot(lossP_byepoch); 
grid on; xlabel('Epoch'); ylabel('Prediction Loss'); 
saveas(fig, 'output/20241025_DeepGC4/global/figure/lossP.png')
savefig('output/20241025_DeepGC4/global/figure/lossP.fig')

possible_epochs_basedonlossR = (lossR_byepoch <= quantile(lossR_byepoch,0.5));
possible_epochs_basedonlossP = (lossP_byepoch <= quantile(lossP_byepoch,0.5));
joint_possible_epochs_basedonlossRP = find(possible_epochs_basedonlossR & possible_epochs_basedonlossP);

xTPpropR_byepoch = sum(xTPpropR_history'...
    .*nelem(select_iter'))'...
    ./sum(nelem(select_iter'));
% plot(xTPpropR_byepoch)
figure(1); fig = plot(xTPpropR_byepoch); 
grid on; xlabel('Epoch'); ylabel('Proportion of True Positives'); 
saveas(fig, 'output/20241025_DeepGC4/global/figure/xTPpropR_byepoch.png')
savefig('output/20241025_DeepGC4/global/figure/xTPpropR_byepoch.fig')


xTPpropH_byepoch = sum(xTPpropH_history'...
    .*nelem(select_iter'))'...
    ./sum(nelem(select_iter'));
% plot(xTPpropH_byepoch)
figure(1); fig = plot(xTPpropH_byepoch); 
grid on; xlabel('Epoch'); ylabel('Proportion of True Positives'); 
saveas(fig, 'output/20241025_DeepGC4/global/figure/xTPpropH_byepoch.png')
savefig('output/20241025_DeepGC4/global/figure/xTPpropH_byepoch.fig')

xTPpropW_byepoch = sum(xTPpropW_history'...
    .*nelem(select_iter'))'...
    ./sum(nelem(select_iter'));
% plot(xTPpropW_byepoch)
figure(1); fig = plot(xTPpropW_byepoch); 
grid on; xlabel('Epoch'); ylabel('Proportion of True Positives'); 
saveas(fig, 'output/20241025_DeepGC4/global/figure/xTPpropW_byepoch.png')
savefig('output/20241025_DeepGC4/global/figure/xTPpropW_byepoch.fig')

xTPprop_byepoch = ...
    xTPpropR_byepoch(joint_possible_epochs_basedonlossRP)./3 + ...
    xTPpropH_byepoch(joint_possible_epochs_basedonlossRP)./3 + ...
    xTPpropW_byepoch(joint_possible_epochs_basedonlossRP)./3;
joint_possible_epochs_basedonlossRP(xTPprop_byepoch==max(xTPprop_byepoch))

xTPpropR2_byepoch = sum(xTPpropR2_history'...
    .*nelem(select_iter'))'...
    ./sum(nelem(select_iter'));
% plot(xTPpropR2_byepoch)
figure(1); fig = plot(xTPpropR2_byepoch); 
grid on; xlabel('Epoch'); ylabel('Proportion of True Positives'); 
saveas(fig, 'output/20241025_DeepGC4/global/figure/xTPpropR2_byepoch.png')
savefig('output/20241025_DeepGC4/global/figure/xTPpropR2_byepoch.fig')


xTPpropH2_byepoch = sum(xTPpropH2_history'...
    .*nelem(select_iter'))'...
    ./sum(nelem(select_iter'));
% plot(xTPpropH2_byepoch)
figure(1); fig = plot(xTPpropH2_byepoch); 
grid on; xlabel('Epoch'); ylabel('Proportion of True Positives'); 
saveas(fig, 'output/20241025_DeepGC4/global/figure/xTPpropH2_byepoch.png')
savefig('output/20241025_DeepGC4/global/figure/xTPpropH2_byepoch.fig')



xTPpropW2_byepoch = sum(xTPpropW2_history'...
    .*nelem(select_iter'))'...
    ./sum(nelem(select_iter'));
% plot(xTPpropW2_byepoch)


figure(1); fig = plot(xTPpropW2_byepoch); 
grid on; xlabel('Epoch'); ylabel('Proportion of True Positives'); 
saveas(fig, 'output/20241025_DeepGC4/global/figure/xTPpropW2_byepoch.png')
savefig('output/20241025_DeepGC4/global/figure/xTPpropW2_byepoch.fig')


xTPprop2_byepoch = ...
    xTPpropR2_byepoch(joint_possible_epochs_basedonlossRP)./3 + ...
    xTPpropH2_byepoch(joint_possible_epochs_basedonlossRP)./3 + ...
    xTPpropW2_byepoch(joint_possible_epochs_basedonlossRP)./3;

xTPprop_byepoch_combined = xTPprop_byepoch./2 + xTPprop2_byepoch./2;
selected_epoch = joint_possible_epochs_basedonlossRP(xTPprop_byepoch_combined==max(xTPprop_byepoch_combined));


netE = netE_history{selected_epoch,end};
netD = netD_history{selected_epoch,end};


for j = 1:length(select_iter) %1:nBatch
    iter = select_iter(j)

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

% for reporting - training scores
sum(xTPpropR_history_test.*nelem_history_test)./sum(nelem_history_test) % 99.02
sum(xTPpropH_history_test.*nelem_history_test)./sum(nelem_history_test) % 94.83
sum(xTPpropW_history_test.*nelem_history_test)./sum(nelem_history_test) % 93.26
sum(xTPpropR2_history_test.*nelem_history_test)./sum(nelem_history_test) % 99.00
sum(xTPpropH2_history_test.*nelem_history_test)./sum(nelem_history_test) % 9.62
sum(xTPpropW2_history_test.*nelem_history_test)./sum(nelem_history_test) % 56.78

% from validation - just for reference
% mean(a) % 98.81
% mean(b) % 94.25
% mean(c) % 94.08
% mean(d) % 98.60
% mean(e) % 7.66
% mean(f) % 48.13

%% for saving

% DeepC4 - MinCostFlow
save("output/20241025_DeepGC4/global/trainingScore.mat",... 
    "xTPpropR_history_test","xTPpropH_history_test","xTPpropW_history_test",...
    "xTPpropR2_history_test","xTPpropH2_history_test","xTPpropW2_history_test",...
    "iter_history_test","nelem_history_test")