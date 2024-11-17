load("output/20241111_DeepC4/input.mat",... ...
    "X_batch","tau_batch","tauH_batch","tauW_batch","btype_label","label_height","ind_batch","nelem")

load("output/20241111_DeepC4/global/outputTrainedModels.mat",... 
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
lossP_byepoch = sum(PredictionLoss_history'.*nelem(select_iter))...
                ./sum(nelem(select_iter));


%%
% figure(1);
% t=tiledlayout(2,1,'TileSpacing','none');
% 
% nexttile;
% plot(1:400, lossR_byepoch,'LineWidth',2.0); 
% hold on; plot(1:400, movmean(lossR_byepoch,10),'LineWidth',2.0); hold off
% xticks([0 100 200 300 400]);
% xticklabels("");
% yticks([0.6 0.7 0.8 0.9 1.0 1.1]);
% ylim([0.5 1.2])
% grid on
% ylabel('Reconstruction Loss');
% xline(184,'--k',{'x = 184'}, 'LineWidth',1.5); yline(0.6552,'--k',{'y = 0.6552'}, 'LineWidth',1.5);
% fontsize(23,"points"); ytickformat('%.1f')
% legend({'',sprintf('10-point\nAverage')},'Location','northeast');
% 
% nexttile;
% plot(lossP_byepoch,'LineWidth',2.0); 
% hold on; plot(1:400, movmean(lossP_byepoch,10),'LineWidth',2.0); hold off
% xticks([0 100 200 300 400]);
% yticks([3.35 3.4 3.45 3.5 3.55]);
% ylim([3.3 3.6])
% grid on
% ylabel('Prediction Loss');
% xline(184,'--k', 'LineWidth',1.5); 
% yline(3.376,'--k',{'y = 3.376'}, 'LineWidth',1.5,'LabelVerticalAlignment','bottom','LabelHorizontalAlignment','left');
% fontsize(23,"points"); ytickformat('%.2f')
% xlabel('Epoch')
% savefig('docs/ISPRS/figures/fig_Loss.fig')
% exportgraphics(gcf,'docs/ISPRS/figures/fig_Loss.pdf','ContentType','vector')

possible_epochs_basedonlossR = (lossR_byepoch <= quantile(lossR_byepoch,0.5));
possible_epochs_basedonlossP = (lossP_byepoch <= quantile(lossP_byepoch,0.5));
joint_possible_epochs_basedonlossRP = find(possible_epochs_basedonlossR & possible_epochs_basedonlossP);

xTPpropR_byepoch = sum(xTPpropR_history'...
    .*nelem(select_iter'))'...
    ./sum(nelem(select_iter'));
xTPpropH_byepoch = sum(xTPpropH_history'...
    .*nelem(select_iter'))'...
    ./sum(nelem(select_iter'));
xTPpropW_byepoch = sum(xTPpropW_history'...
    .*nelem(select_iter'))'...
    ./sum(nelem(select_iter'));


%%
% figure(1);
% t=tiledlayout(3,1,'TileSpacing','none');
% 
% nexttile;
% plot(1:400, 100.*xTPpropR_byepoch,'LineWidth',2.0); 
% hold on; plot(1:400, movmean(100.*xTPpropR_byepoch,10),'LineWidth',2.0); hold off
% xticks([0 100 200 300 400]);
% xticklabels("");
% yticks([98.95 99 99.05 99.1 99.15]);
% ylim([98.90 99.20])
% grid on
% ylabel('Roof');
% xline(184,'--k',{'x = 184'}, 'LineWidth',1.5); 
% yline(99.03,'--k',{'y = 99.03%'}, 'LineWidth',1.5,'LabelVerticalAlignment','bottom','LabelHorizontalAlignment','right');
% fontsize(23,"points"); ytickformat('%.2f')
% legend({'',sprintf('10-point\nAverage')},'Location','northwest');
% 
% nexttile;
% plot(1:400, 100.*xTPpropW_byepoch,'LineWidth',2.0); 
% hold on; plot(1:400, movmean(100.*xTPpropW_byepoch,10),'LineWidth',2.0); hold off
% xticks([0 100 200 300 400]);
% xticklabels("");
% grid on
% yticks([95.5 96 96.5 97]);
% ylim([95 97.5])
% ylabel('Wall');
% xline(184,'--k', 'LineWidth',1.5); 
% yline(96.45,'--k',{'y = 96.45%'}, 'LineWidth',1.5,'LabelVerticalAlignment','top','LabelHorizontalAlignment','right');
% fontsize(23,"points"); ytickformat('%.2f')
% 
% nexttile;
% plot(1:400, 100.*xTPpropH_byepoch,'LineWidth',2.0); 
% hold on; plot(1:400, movmean(100.*xTPpropH_byepoch,10),'LineWidth',2.0); hold off
% xticks([0 100 200 300 400]);
% grid on
% yticks([95.25 95.5 95.75 96 96.25]);
% ylim([95 96.5])
% ylabel('Height');
% xline(184,'--k', 'LineWidth',1.5); 
% yline(95.87,'--k',{'y = 95.87%'}, 'LineWidth',1.5,'LabelVerticalAlignment','top','LabelHorizontalAlignment','left');
% fontsize(23,"points"); ytickformat('%.2f')
% 
% 
% xlabel(t, 'Epoch'); ylabel(t, 'Proportion of True Positives')
% savefig('docs/ISPRS/figures/fig_TP.fig')
% exportgraphics(gcf,'docs/ISPRS/figures/fig_TP.pdf','ContentType','vector')

xTPprop_byepoch = ...
    xTPpropR_byepoch(joint_possible_epochs_basedonlossRP)./3 + ...
    xTPpropH_byepoch(joint_possible_epochs_basedonlossRP)./3 + ...
    xTPpropW_byepoch(joint_possible_epochs_basedonlossRP)./3;
joint_possible_epochs_basedonlossRP(xTPprop_byepoch==max(xTPprop_byepoch))

xTPpropR2_byepoch = sum(xTPpropR2_history'...
    .*nelem(select_iter'))'...
    ./sum(nelem(select_iter'));
xTPpropH2_byepoch = sum(xTPpropH2_history'...
    .*nelem(select_iter'))'...
    ./sum(nelem(select_iter'));
xTPpropW2_byepoch = sum(xTPpropW2_history'...
    .*nelem(select_iter'))'...
    ./sum(nelem(select_iter'));


%%
figure(1);
t=tiledlayout(3,1,'TileSpacing','none');

nexttile;
plot(1:400, 100.*xTPpropR2_byepoch,'LineWidth',2.0); 
hold on; plot(1:400, movmean(100.*xTPpropR2_byepoch,10),'LineWidth',2.0); hold off
xticks([0 100 200 300 400]);
xticklabels("");
yticks([98.75 99 99.25 99.5 99.75]);
ylim([98.5 100])
grid on
ylabel('Roof');
xline(184,'--k', 'LineWidth',1.5); 
yline(99.82,'--k',{'y = 99.82%'}, 'LineWidth',1.5,'LabelVerticalAlignment','bottom','LabelHorizontalAlignment','right');
fontsize(23,"points"); ytickformat('%.2f')
legend({'',sprintf('10-point\nAverage')},'Location','southwest');

nexttile;
plot(1:400, 100.*xTPpropW2_byepoch,'LineWidth',2.0); 
hold on; plot(1:400, movmean(100.*xTPpropW2_byepoch,10),'LineWidth',2.0); hold off
xticks([0 100 200 300 400]);
xticklabels("");
grid on
yticks([45 50 55 60 65]);
ylim([40 70])
ylabel('Wall');
xline(184,'--k',{'x = 184'}, 'LineWidth',1.5, 'LabelVerticalAlignment','bottom'); 
yline(60.02,'--k',{'y = 60.02%'}, 'LineWidth',1.5,'LabelVerticalAlignment','top','LabelHorizontalAlignment','right');
fontsize(23,"points"); ytickformat('%.2f')

nexttile;
plot(1:400, 100.*xTPpropH2_byepoch,'LineWidth',2.0); 
hold on; plot(1:400, movmean(100.*xTPpropH2_byepoch,10),'LineWidth',2.0); hold off
xticks([0 100 200 300 400]);
grid on
yticks([6 8 10 12 14]);
ylim([4 16])
ylabel('Height');
xline(184,'--k', 'LineWidth',1.5); 
yline(9.68,'--k',{'y = 9.68%'}, 'LineWidth',1.5,'LabelVerticalAlignment','top','LabelHorizontalAlignment','center');
fontsize(23,"points"); ytickformat('%.2f')


xlabel(t, 'Epoch'); ylabel(t, 'Weighted Proportion of True Positives')
savefig('docs/ISPRS/figures/fig_TPw.fig')
exportgraphics(gcf,'docs/ISPRS/figures/fig_TPw.pdf','ContentType','vector')


xTPprop2_byepoch = ...
    xTPpropR2_byepoch(joint_possible_epochs_basedonlossRP)./3 + ...
    xTPpropH2_byepoch(joint_possible_epochs_basedonlossRP)./3 + ...
    xTPpropW2_byepoch(joint_possible_epochs_basedonlossRP)./3;

xTPprop_byepoch_combined = xTPprop_byepoch./2 + xTPprop2_byepoch./2;
selected_epoch = joint_possible_epochs_basedonlossRP(xTPprop_byepoch_combined==max(xTPprop_byepoch_combined));


netE = netE_history{selected_epoch,end};
netD = netD_history{selected_epoch,end};

k = 1;
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
sum(xTPpropH_history_test.*nelem_history_test)./sum(nelem_history_test) % 96.03
sum(xTPpropW_history_test.*nelem_history_test)./sum(nelem_history_test) % 96.64
sum(xTPpropR2_history_test.*nelem_history_test)./sum(nelem_history_test) % 99.85
sum(xTPpropH2_history_test.*nelem_history_test)./sum(nelem_history_test) % 7.45
sum(xTPpropW2_history_test.*nelem_history_test)./sum(nelem_history_test) % 60.50

% from validation - just for reference
% mean(a) % 98.80
% mean(b) % 95.61
% mean(c) % 95.55
% mean(d) % 98.62
% mean(e) % 10.34
% mean(f) % 56.12

%% for saving

% DeepC4 - MinCostFlow
save("output/20241111_DeepC4/global/trainingScore.mat",... 
    "xTPpropR_history_test","xTPpropH_history_test","xTPpropW_history_test",...
    "xTPpropR2_history_test","xTPpropH2_history_test","xTPpropW2_history_test",...
    "iter_history_test","nelem_history_test")