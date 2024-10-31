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

monitor1 = trainingProgressMonitor;
monitor1.Metrics = ["BatchTPpropR","BatchTPpropH","BatchTPpropW",...
                    "BatchTPpropR2","BatchTPpropH2","BatchTPpropW2"];
monitor1.XLabel = "Epoch";
groupSubPlot(monitor1,"BatchTPpropR","BatchTPpropR");
groupSubPlot(monitor1,"BatchTPpropH","BatchTPpropH");
groupSubPlot(monitor1,"BatchTPpropW","BatchTPpropW");
groupSubPlot(monitor1,"BatchTPpropR2","BatchTPpropR2");
groupSubPlot(monitor1,"BatchTPpropH2","BatchTPpropH2");
groupSubPlot(monitor1,"BatchTPpropW2","BatchTPpropW2");

% Loop over epochs.
netE_history = cell(numEpochs,nBatch);
netD_history = cell(numEpochs,nBatch);
xTPpropR_history = zeros(numEpochs,nBatch);
xTPpropH_history = zeros(numEpochs,nBatch);
xTPpropW_history = zeros(numEpochs,nBatch);
xTPpropR2_history = zeros(numEpochs,nBatch);
xTPpropH2_history = zeros(numEpochs,nBatch);
xTPpropW2_history = zeros(numEpochs,nBatch);
BatchTPpropR_history = zeros(numEpochs,1);
BatchTPpropH_history = zeros(numEpochs,1);
BatchTPpropW_history = zeros(numEpochs,1);
BatchTPpropR2_history = zeros(numEpochs,1);
BatchTPpropH2_history = zeros(numEpochs,1);
BatchTPpropW2_history = zeros(numEpochs,1);
ReconstructionLoss_history = zeros(numEpochs,nBatch);
PredictionLoss_history = zeros(numEpochs,nBatch);

% Train
epoch = 0; iter = 0; xIter = 0;
[netE,netD] = createAE();

while epoch < numEpochs && ~monitor.Stop
    epoch = epoch + 1
    xBatchTPpropR = [];
    xBatchTPpropH = [];
    xBatchTPpropW = [];
    xBatchTPpropR2 = [];
    xBatchTPpropH2 = [];
    xBatchTPpropW2 = [];
    
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

        xBatchTPpropR = [xBatchTPpropR; 
                        xTPpropR.*nelem(iter)./sum(nelem(select_iter))];
        xBatchTPpropH = [xBatchTPpropH; 
                        xTPpropH.*nelem(iter)./sum(nelem(select_iter))];
        xBatchTPpropW = [xBatchTPpropW; 
                        xTPpropW.*nelem(iter)./sum(nelem(select_iter))];
        xBatchTPpropR2 = [xBatchTPpropR2; 
                        xTPpropR2.*nelem(iter)./sum(nelem(select_iter))];
        xBatchTPpropH2 = [xBatchTPpropH2; 
                        xTPpropH2.*nelem(iter)./sum(nelem(select_iter))];
        xBatchTPpropW2 = [xBatchTPpropW2; 
                        xTPpropW2.*nelem(iter)./sum(nelem(select_iter))];
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
    recordMetrics(monitor1, ...
            epoch, ...
            BatchTPpropR=sum(xBatchTPpropR), ...
            BatchTPpropH=sum(xBatchTPpropH), ...
            BatchTPpropW=sum(xBatchTPpropW), ...
            BatchTPpropR2=sum(xBatchTPpropR2), ...
            BatchTPpropH2=sum(xBatchTPpropH2), ...
            BatchTPpropW2=sum(xBatchTPpropW2));
    BatchTPpropR_history(epoch,1) = sum(xBatchTPpropR);
    BatchTPpropH_history(epoch,1) = sum(xBatchTPpropH);
    BatchTPpropW_history(epoch,1) = sum(xBatchTPpropW);
    BatchTPpropR2_history(epoch,1) = sum(xBatchTPpropR2);
    BatchTPpropH2_history(epoch,1) = sum(xBatchTPpropH2);
    BatchTPpropW2_history(epoch,1) = sum(xBatchTPpropW2);

end

% global
save("output/20241025_DeepGC4/global/outputTrainedModels.mat",... 
    "netE_history","netD_history",...
    "xTPpropR_history","xTPpropH_history","xTPpropW_history",...
    "xTPpropR2_history","xTPpropH2_history","xTPpropW2_history",...
    "BatchTPpropR_history","BatchTPpropH_history","BatchTPpropW_history",...
    "BatchTPpropR2_history","BatchTPpropH2_history","BatchTPpropW2_history",...
    "ReconstructionLoss_history","PredictionLoss_history")

%% evaluate training scores

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

%% Perform downstream


%% 
y_height = zeros(size(mask));
y_roof = zeros(size(mask));
y_macrotaxo = zeros(size(mask));
y_wall = zeros(size(mask));

for idx_rID = 1:length(label2rasterID.RASTER_ID1)

    rID = label2rasterID.RASTER_ID1(idx_rID);

    disp("start"), tic

    if rID == length(label2rasterID.RASTER_ID1)
        rID = 0;
    end
    if rID ~= 111 && ...
       string(label2rasterID.NAME_3(find(label2rasterID.RASTER_ID1 == rID))) ~= "Lac Kivu" % Rudashya Fix and Lake Kivu Fix

        province    = string(label2rasterID.NAME_1(find(label2rasterID.RASTER_ID1 == rID)));
        district    = string(label2rasterID.NAME_2(find(label2rasterID.RASTER_ID1 == rID)));
        sector      = string(label2rasterID.NAME_3(find(label2rasterID.RASTER_ID1 == rID)));

        if rID == 112 % minor fix to consider merging of two sectors
            idx =   (mask == rID | mask == (rID-1)) & (dynLabel == 6);
        else
            idx =   (mask == rID) & (dynLabel == 6);
        end

        disp(idx_rID)
        disp(rID)
        disp(province)
        disp(district)
        disp(sector)

        iQ =    Q.Province == province & ...
                Q.Distict == district & ...
                Q.Sector == sector & ...
                Q.numBuilding > 0;
        nQ =    Q(iQ,:);
        nQ =    sortrows(nQ,"HeightClass","ascend");

        % EO-derived data
        % dynProb - 2022
        x_dynProb   = sparse(double(dynProb.*idx));
        x_bldgftprnt    = sparse(double(bldgftprnt.*idx>0));

        %% create a 2d probability space of building presence
        % this will depend on the EO-derived data
        % thought process: we know that the initially computed idx considers the
        % masking (by sector) and another EO-derived data (dynLabel == 6), which is
        % is the biggest space. That resulting space, which represents a uniform
        % land class denoting urban space, has the same probability over all
        % locations. Hence, the probability of each of its pixel would be as simply
        % as uniform:
        p_initial =  idx ./ sum(idx, 'all');

        % thought process: next, between x_dynProb (real values, 0-1) and 
        % x_bldgftprnt (binary, 0 or 1), which both
        % indicate building presence and nothing about height information yet, we
        % can have a refined p_intial where we consider the spatial variation based
        % on these two EO-derived datasets. 
        % Let's talk about assumptions: upon rough inspection, x_bldgftprnt seems
        % to have a good reliability of building locations, let's combine these two
        % datasets to see their interaction:
        tmp = x_dynProb(x_bldgftprnt==1);

        % we also assumed that microsoft x_bldgftprnt is imperfect (i.e., less than
        % 100% reliability), which means it will always be less than the estimated
        % total number of buildings based on census records. hence, we can first
        % preserve the information of x_bldgftprnt or technically put an importance
        % factor of 100%.

        % another big assumption here is the law of mass conversation of buildings.
        % to address this, we can consider the average
        % area of building from bldgftprn, based on Paul's estimation
        average_area_x_bldgftprnt    =  60; %m2/bldg

        % this is interpreted as the average arae of a building in a given grid,
        % hence, the number of pixels needed for a single building would be:
        % n_bldg_per_pixel = (m2/pixel) / (m2/bldg)
        % n_bldg_per_pixel = (m2/pixel) x (bldg/m2)
        % n_bldg_per_pixel = bldg/pixel
        n_bldg_per_pixel = 100 ./ average_area_x_bldgftprnt; % number of bldg per pixel

        % this follows that the microsoft x_bldgftprnt would correspond to this 
        % number of building
        % nBldgFromBldgData = (number of pixels) x (bldg/pixel)
        % nBldgFromBldgData = number of bldgs
        nBldgFromBldgData = full(sum(x_bldgftprnt, 'all')) .* n_bldg_per_pixel;

        % as we said, microsoft EO-derived data is imperfect and may always be
        % less than what the census would give us. let's now compute for the
        % remaining nBldg that we will obtain using the values of x_dynProb
        remaining_nBldg = sum(nQ.numBuilding) - nBldgFromBldgData;

        % npixels_remaining_nBldg = bldgs ./ (bldg/pixel)
        % npixels_remaining_nBldg = bldgs x (pixel/bldg)
        % npixels_remaining_nBldg = number of pixels
        npixels_remaining_nBldg = remaining_nBldg ./ n_bldg_per_pixel;

        % let's now obtain the p_threshod of x_dynProb to meet the need of
        % n_pixels_remaining_nBlds
        if npixels_remaining_nBldg > 0
            remaining_idx = full(idx & ~x_bldgftprnt);
            p_max = max(max(full(remaining_idx) .* x_dynProb));

            p = p_max; target = 0;
            while target < double(npixels_remaining_nBldg)
                p = p - 0.001;
                target = sum(remaining_idx .* (x_dynProb >= p), 'all');
            end
            p = p + 2*0.001; 
            target = sum(remaining_idx .* (x_dynProb >= p), 'all');

            while target < double(npixels_remaining_nBldg)
                p = p - 0.0001;
                target = sum(remaining_idx .* (x_dynProb >= p), 'all');
            end
            p = p + 2*0.0001; 
            target = sum(remaining_idx .* (x_dynProb >= p), 'all');

            while target < double(npixels_remaining_nBldg)
                p = p - 0.00001;
                target = sum(remaining_idx .* (x_dynProb >= p), 'all');
            end
            p = p + 2*0.00001; 
            target = sum(remaining_idx .* (x_dynProb >= p), 'all');

            while target < double(npixels_remaining_nBldg)
                p = p - 0.000001;
                target = sum(remaining_idx .* (x_dynProb >= p), 'all');
            end
            p = p + 2*0.000001; 
            target = sum(remaining_idx .* (x_dynProb >= p), 'all');

            valid_idx = full(remaining_idx .* (x_dynProb >= p) | x_bldgftprnt);
            toc, disp("Valid Idx Obtained"), tic
        else % npixels_remaining_nBldg < 0 and often it's not == 0
            tmp = x_dynProb(x_bldgftprnt==1);
            p_min = min(tmp);

            p = p_min; target = full(sum(x_bldgftprnt, 'all'));
            while target > (sum(nQ.numBuilding).*n_bldg_per_pixel)
                p = p + 0.001;
                target = sum(x_bldgftprnt .* (x_dynProb >= p), 'all');
            end
            p = p - 2*0.001; 
            target = sum(x_bldgftprnt .* (x_dynProb >= p), 'all');

            while target > (sum(nQ.numBuilding).*n_bldg_per_pixel)
                p = p + 0.0001;
                target = sum(x_bldgftprnt .* (x_dynProb >= p), 'all');
            end
            p = p - 2*0.0001; 
            target = sum(x_bldgftprnt .* (x_dynProb >= p), 'all');

            while target > (sum(nQ.numBuilding).*n_bldg_per_pixel)
                p = p + 0.00001;
                target = sum(x_bldgftprnt .* (x_dynProb >= p), 'all');
            end
            p = p - 2*0.00001; 
            target = sum(x_bldgftprnt .* (x_dynProb >= p), 'all');

            while target > (sum(nQ.numBuilding).*n_bldg_per_pixel)
                p = p + 0.000001;
                target = sum(x_bldgftprnt .* (x_dynProb >= p), 'all');
            end
            p = p - 2*0.000001; 
            target = sum(x_bldgftprnt .* (x_dynProb >= p), 'all');

            valid_idx = full(x_bldgftprnt .* (x_dynProb >= p));
            toc, disp("Valid Idx Obtained"), tic

        end
        %% covariates: now that we identified all the valid candidate locations, 
        % let's consider the EO datasets now for possible clustering
        % EO-data:
        x_s1vv      = sparse(double(s1vv.*valid_idx));
        x_s1vh      = sparse(double(s1vh.*valid_idx));
        x_r         = sparse(double(rgb(:,:,1).*valid_idx));
        x_g         = sparse(double(rgb(:,:,2).*valid_idx));
        x_b         = sparse(double(rgb(:,:,3).*valid_idx));
        x_red1      = sparse(double(red1.*valid_idx));
        x_red2      = sparse(double(red2.*valid_idx));
        x_red3      = sparse(double(red3.*valid_idx));
        x_red4      = sparse(double(red4.*valid_idx));
        x_swir1     = sparse(double(swir1.*valid_idx));
        x_swir2     = sparse(double(swir2.*valid_idx));
        x_nir       = sparse(double(nir.*valid_idx));
        toc, disp("Covariate X Prepared"), tic

        %% model: label-agnostic training
        % we know that some of the EO bands indicate height or roof material
        % possibly jointly. we could say that the wall material is not visible to
        % be captured by the satellites. so, we gotta take the challenge that we'll
        % leverage the roof material census instead and wall height as the joint
        % labels, and then we'll post-process it with our encoded belief on the
        % relationship between roof material, wall material, and height class.

        % Check if this is a valid rID, else skip
        ind = find(x_s1vv>0);
        [rowS,colS] = find(x_s1vv>0); % incorporate spatial element
        X = full([  ...
                    normalize(log(x_s1vv(x_s1vv>0))) ...
                    normalize(log(x_s1vh(x_s1vh>0))) ...
                    normalize(log(x_r(x_r>0))) ...
                    normalize(log(x_g(x_g>0))) ...
                    normalize(log(x_b(x_b>0))) ...
                    normalize(log(x_red1(x_red1>0))) ...
                    normalize(log(x_red2(x_red2>0))) ...
                    normalize(log(x_red3(x_red3>0))) ...
                    normalize(log(x_red4(x_red4>0))) ...
                    normalize(log(x_swir1(x_swir1>0))) ...
                    normalize(log(x_swir2(x_swir2>0))) ...
                    normalize(log(x_nir(x_nir>0))) ...
                    normalize(rowS) ...
                    normalize(colS) ...
                    ...
                    ]);


        %% ground truth class representation for global clustering
        % ROOF - common to all rIDs
        uniq_RoofMaterial =     string(data((data.Sector == sector) & ...
                                (data.Province == province) & ...
                                (data.District == district), 22:25).Properties.VariableNames)';
        summary_RoofMaterial =  table2array(data((data.Sector == sector) & ...
                                (data.Province == province) & ...
                                (data.District == district), 22:25))';
        summary_RoofMaterial(isnan(summary_RoofMaterial)) = 0;
        summary_RoofMaterial = summary_RoofMaterial ./ sum(summary_RoofMaterial);
        tauR = floor(summary_RoofMaterial .* length(find(x_s1vv>0)));
        if sum(tauR) ~= length(find(x_s1vv>0))
            ttmp = find(tauR == max(tauR),1);
            tauR(ttmp) = tauR(ttmp) + (length(find(x_s1vv>0))-sum(tauR));
        end

        % HEIGHT
        uniq_HeightClass = unique(Q.HeightClass);
        jointProb_HeightClassANDMacroTaxonomy = zeros(  numel(uniq_HeightClass), ...
                                                        numel(uniq_MacroTaxonomy));
        for i = 1:numel(uniq_MacroTaxonomy)
            for j = 1:numel(uniq_HeightClass)
                jointProb_HeightClassANDMacroTaxonomy(j,i) = ...
                    sum(nQ.numBuilding( (string(nQ.HeightClass) == uniq_HeightClass(j)) & ...
                                        (string(nQ.MacroTaxonomy) == uniq_MacroTaxonomy(i))   ));
            end
        end
        jointProb_HeightClassANDMacroTaxonomy = jointProb_HeightClassANDMacroTaxonomy ./ ...
                            sum(jointProb_HeightClassANDMacroTaxonomy, 'all');
        % uniq_HeightClass = string(unique(Q.HeightClass));
        % summary_HeightClass = zeros(numel(uniq_HeightClass),1);
        % for j = 1:numel(uniq_HeightClass)
        %     summary_HeightClass(j,1) = sum(nQ.numBuilding(string(nQ.HeightClass) == uniq_HeightClass(j)));
        % end
        % summary_HeightClass(isnan(summary_HeightClass)) = 0;
        % summary_HeightClass = summary_HeightClass ./ sum(summary_HeightClass);
        % tauH = floor(summary_HeightClass .* length(find(x_s1vv>0)));
        % if sum(tauH) ~= length(find(x_s1vv>0))
        %     ttmp = find(tauH == max(tauH),1);
        %     tauH(ttmp) = tauH(ttmp) + (length(find(x_s1vv>0))-sum(tauH));
        % end

        % WALL
        uniq_WallClass = string(unique(Q.Material));
        summary_WallClass = zeros(numel(uniq_WallClass),1);
        for j = 1:numel(uniq_WallClass)
            summary_WallClass(j,1) = sum(nQ.numBuilding(string(nQ.Material) == uniq_WallClass(j)));
        end
        summary_WallClass(isnan(summary_WallClass)) = 0;
        summary_WallClass = summary_WallClass ./ sum(summary_WallClass);
        tauW = floor(summary_WallClass .* length(find(x_s1vv>0)));
        if sum(tauW) ~= length(find(x_s1vv>0))
            ttmp = find(tauW == max(tauW),1);
            tauW(ttmp) = tauW(ttmp) + (length(find(x_s1vv>0))-sum(tauW));
        end

        % MACROTAXONOMY 
        uniq_MacroTaxonomy = unique(Q.MacroTaxonomy);
        jointProb_MacroTaxonomyANDWallMaterial = zeros( numel(uniq_MacroTaxonomy), ...
                                                        numel(uniq_WallClass));
        for i = 1:numel(uniq_WallClass)
            for j = 1:numel(uniq_MacroTaxonomy)
                jointProb_MacroTaxonomyANDWallMaterial(j,i) = ...
                    sum(nQ.numBuilding( (string(nQ.MacroTaxonomy) == uniq_MacroTaxonomy(j)) & ...
                                        (string(nQ.Material) == uniq_WallClass(i))   ));
            end
        end
        jointProb_MacroTaxonomyANDWallMaterial = jointProb_MacroTaxonomyANDWallMaterial ./ ...
                            sum(jointProb_MacroTaxonomyANDWallMaterial, 'all');
        
       

        %% Predict roof, height, and wall
        Z = forward(netE_history{final_epoch,final_iter},...
                    dlarray(X, 'BC')+1e-6);

        %% ROOF
        tic, err = 1; failed = 1;
        while err > 0.01 | failed == 1
            try
                [labelsR,centroidsR] = constrainedKMeans_DEC(Z(1,:), sum(tauR > 1e-5), tauR(tauR ~= 0), 50);
                failed = 0;
            catch MyErr
                failed = 1;
            end
            if failed == 0
                err = sum(abs((tauR(tauR ~= 0))'-(histcounts(labelsR)))) ./ sum(tauR(tauR ~= 0));
            end
        end
        roof_assignment = strings(size(Z,2),1);
        nonzero_idx_tauR = find(tauR ~= 0);
        for i = 1:sum(tauR > 1e-5)
            iX = find(labelsR == i);
            roof_assignment(iX,:) = uniq_RoofMaterial(nonzero_idx_tauR(i));
        end
        roof_assignment_id = zeros(size(X,1),1);
        for i = 1:numel(uniq_RoofMaterial)
            roof_assignment_id((roof_assignment==uniq_RoofMaterial(i)),1) = i;
        end
        y_roof(valid_idx==1) = roof_assignment_id;
        toc, disp("Roof Assigned"), tic


        %% HEIGHT
        % tic, err = 1; failed = 1;
        % while err > 0.01 | failed == 1
        %     try
        %         [labelsH,centroidsH] = constrainedKMeans_DEC(Z(2,:), sum(tauH > 1e-5), tauH(tauH ~= 0), 50);
        %         failed = 0;
        %     catch MyErr
        %         failed = 1;
        %     end
        %     if failed == 0
        %         err = sum(abs((tauH(tauH ~= 0))'-(histcounts(labelsH)))) ./ sum(tauH(tauH ~= 0));
        %     end
        % end
        % height_class_assignment = strings(size(Z,2),1);
        % nonzero_idx_tauH = find(tauH ~= 0);
        % for i = 1:sum(tauH > 1e-5)
        %     iX = find(labelsH == i);
        %     height_class_assignment(iX,:) = uniq_HeightClass(nonzero_idx_tauH(i));
        % end
        % height_class_assignment_id = zeros(size(X,1),1);
        % for i = 1:numel(uniq_HeightClass)
        %     height_class_assignment_id((height_class_assignment==uniq_HeightClass(i)),1) = i;
        % end
        % y_height(valid_idx==1) = height_class_assignment_id;
        % toc, disp("Height Assigned"), tic

        %% WALL
        tic, err = 1; failed = 1;
        while err > 0.01 | failed == 1
            try
                [labelsW,centroidsW] = constrainedKMeans_DEC(Z(3,:), sum(tauW > 1e-5), tauW(tauW ~= 0), 50);
                failed = 0;
            catch MyErr
                failed = 1;
            end
            if failed == 0
                err = sum(abs((tauW(tauW ~= 0))'-(histcounts(labelsW)))) ./ sum(tauW(tauW ~= 0));
            end
        end
        wall_assignment = strings(size(Z,2),1);
        nonzero_idx_tauW = find(tauW ~= 0);
        for i = 1:sum(tauW > 1e-5)
            iX = find(labelsW == i);
            wall_assignment(iX,:) = uniq_WallClass(nonzero_idx_tauW(i));
        end
        wall_assignment_id = zeros(size(X,1),1);
        for i = 1:numel(uniq_WallClass)
            wall_assignment_id((wall_assignment==uniq_WallClass(i)),1) = i;
        end
        y_wall(valid_idx==1) = wall_assignment_id;
        toc, disp("Wall Assigned"), tic

        %% MACRO-TAXONOMY GIVEN WALL
        tic
        macro_taxonomy_assignment = strings(size(X,1),1);
        macro_taxonomy_assignment_id = zeros(size(X,1),1);
        for j = 1:numel(nonzero_idx_tauW) % per wall category

            % assign macro-taxonomy given wall material
            tmp_idx3 = find(uniq_WallClass == string(uniq_WallClass(nonzero_idx_tauW(j),1)));
            tmp_idx4 = find(wall_assignment == string(uniq_WallClass(nonzero_idx_tauW(j),1)));
            tau_XX = round(    numel(tmp_idx4) * ...
                        jointProb_MacroTaxonomyANDWallMaterial(:,tmp_idx3) ./ ...
                        sum(jointProb_MacroTaxonomyANDWallMaterial(:,tmp_idx3))) ;
            tau_XX(isnan(tau_XX)) = 0;
            if size(X(wall_assignment == string(uniq_WallClass(nonzero_idx_tauW(j),1))),1) < sum(tau_XX(tau_XX ~= 0))
                tau_XX = tau_XX - (tau_XX == max(tau_XX)) .* ...
                (sum(tau_XX(tau_XX ~= 0)) - ...
                size(X(wall_assignment == string(uniq_WallClass(nonzero_idx_tauW(j),1))) ,1));
            end
            if numel(tau_XX(tau_XX ~= 0)) == 0 && size(X( wall_assignment==string(uniq_WallClass(nonzero_idx_tauW(j),1)) ) ,1) == 1
                nelemX = size(X( wall_assignment==string(uniq_WallClass(nonzero_idx_tauW(j),1)) ),1);
                tempelem = numel(tmp_idx4) * ...
                        jointProb_MacroTaxonomyANDWallMaterial(:,tmp_idx3) ./ ...
                        sum(jointProb_MacroTaxonomyANDWallMaterial(:,tmp_idx3));
                maxelem = maxk(tempelem, nelemX);
                idxelem = find(tempelem == maxelem);
                for g = 1:nelemX
                    tau_XX(idxelem(g)) = 1;
                end
            end
            if sum(tau_XX(tau_XX ~= 0)) == 0 && ...
                    size(X( wall_assignment==string(uniq_WallClass(nonzero_idx_tauW(j),1))) ,1) == 1
               tau_XX = (numel(tmp_idx4) * ...
                        jointProb_MacroTaxonomyANDWallMaterial(:,tmp_idx3) ./ ...
                        sum(jointProb_MacroTaxonomyANDWallMaterial(:,tmp_idx3)) == max(numel(tmp_idx4) * ...
                        jointProb_MacroTaxonomyANDWallMaterial(:,tmp_idx3) ./ ...
                        sum(jointProb_MacroTaxonomyANDWallMaterial(:,tmp_idx3))));
            end
            if sum(tau_XX) ~= size(X( wall_assignment==string(uniq_WallClass(nonzero_idx_tauW(j),1)),:),1)
                ttmp = find(tau_XX == max(tau_XX),1);
                tau_XX(ttmp) = tau_XX(ttmp) + (size(X(wall_assignment==string(uniq_WallClass(nonzero_idx_tauW(j),1)),:),1)-sum(tau_XX));
            end   
            err = 1; failed = 1;
            while err > 0.01 | failed == 1
                try
                    [labelsM,centroidsM] = constrainedKMeans_DEC(Z(3,wall_assignment == string(uniq_WallClass(nonzero_idx_tauW(j),1))),...
                                                                 numel(tau_XX(tau_XX ~= 0)),...
                                                                 tau_XX(tau_XX ~= 0), 50);
                    failed = 0;
                catch MyErr
                    failed = 1;
                end
                if failed == 0
                    err = sum(abs((tau_XX(tau_XX ~= 0))'-(histcounts(labelsM)))) ./ sum(tau_XX(tau_XX ~= 0));
                end
            end
            macro_taxonomy_assignment_sub = strings(size(tmp_idx4,1),1);
            nonzero_idx_tau_XX = find(tau_XX ~= 0);
            for i = 1:sum(tau_XX > 1e-5)
                iX = find(labelsM == i);
                macro_taxonomy_assignment_sub(iX,:) = uniq_MacroTaxonomy(nonzero_idx_tau_XX(i));
            end
            macro_taxonomy_assignment(tmp_idx4) = macro_taxonomy_assignment_sub;
            for i = 1:numel(uniq_MacroTaxonomy)
                macro_taxonomy_assignment_id((macro_taxonomy_assignment==uniq_MacroTaxonomy(i)),1) = i;
            end

        end
        y_macrotaxo(valid_idx==1) = macro_taxonomy_assignment_id;
        toc, disp("Macro-Taxonomy Assigned"), tic

        %% HEIGHT GIVEN WALL
        height_class_assignment = strings(size(X,1),1);
        height_class_assignment_id = zeros(size(X,1),1);
        uniq_MacroTaxonomy_from_assignment = unique(macro_taxonomy_assignment);
        for j = 1:numel(uniq_MacroTaxonomy_from_assignment) % per macro taxo category

            % same explanation as before
            tmp_idx5 = find(uniq_MacroTaxonomy == string(uniq_MacroTaxonomy_from_assignment(j,1))   );
            tmp_idx6 = find(macro_taxonomy_assignment == string(uniq_MacroTaxonomy_from_assignment(j,1)) );

            tau_XXX = round(    numel(tmp_idx6) * ...
            jointProb_HeightClassANDMacroTaxonomy(:,tmp_idx5) ./ ...
            sum(jointProb_HeightClassANDMacroTaxonomy(:,tmp_idx5))) ;
            tau_XXX(isnan(tau_XXX)) = 0;

            if size(X(macro_taxonomy_assignment == string(uniq_MacroTaxonomy_from_assignment(j,1))) ,1) ...
                           < sum(tau_XXX(tau_XXX ~= 0))
                tau_XXX = tau_XXX - (tau_XXX == max(tau_XXX)) .* ...
                (sum(tau_XXX(tau_XXX ~= 0)) - ...
                size(X(  macro_taxonomy_assignment == string(uniq_MacroTaxonomy_from_assignment(j,1)) ),1));
            elseif size(X(macro_taxonomy_assignment == string(uniq_MacroTaxonomy_from_assignment(j,1))) ,1) == 1
                tau_XXX(jointProb_HeightClassANDMacroTaxonomy(:,tmp_idx5) == max(jointProb_HeightClassANDMacroTaxonomy(:,tmp_idx5))) = 1;
                tau_XXX(jointProb_HeightClassANDMacroTaxonomy(:,tmp_idx5) ~= max(jointProb_HeightClassANDMacroTaxonomy(:,tmp_idx5))) = 0;
                tau_XXX(isnan(tau_XXX)) = 0;
            end
            if sum(tau_XXX) ~= size(X( macro_taxonomy_assignment == string(uniq_MacroTaxonomy_from_assignment(j,1)) ,:),1)
                ttmp = find(tau_XXX == max(tau_XXX),1);
                tau_XXX(ttmp) = tau_XXX(ttmp) + (size(X( macro_taxonomy_assignment == string(uniq_MacroTaxonomy_from_assignment(j,1)) ,:),1)-sum(tau_XXX));
            end
            err = 1; failed = 1;
            while err > 0.01 | failed == 1
                try
                    [labelsH,centroidsH] = constrainedKMeans_DEC(Z(2, macro_taxonomy_assignment==string(uniq_MacroTaxonomy_from_assignment(j,1)) ),...
                                                                 numel(tau_XXX(tau_XXX ~= 0)), ...
                                                                 tau_XXX(tau_XXX ~= 0), 50);
                    failed = 0;
                catch MyErr
                    failed = 1;
                end
                if failed == 0
                    err = sum(abs((tau_XXX(tau_XXX ~= 0))'-(histcounts(labelsH)))) ./ sum(tau_XXX(tau_XXX ~= 0));
                end
            end
            height_class_assignment_sub = strings(size(tmp_idx6,1),1);
            nonzero_idx_tau_XXX = find(tau_XXX ~= 0);
            for i = 1:sum(tau_XXX > 1e-5)
                iX = find(labelsH == i);
                height_class_assignment_sub(iX,:) = uniq_HeightClass(nonzero_idx_tau_XXX(i));
            end
            height_class_assignment(tmp_idx6) = height_class_assignment_sub;
            for i = 1:numel(uniq_HeightClass)
                height_class_assignment_id((height_class_assignment==uniq_HeightClass(i)),1) = i;
            end

        end
        y_height(valid_idx==1) = height_class_assignment_id;
        toc, disp("Height Assigned"), tic
        

    end
end

%% Export
geotiffwrite("output/20241015_JointDC_RemovedHeightDependsonMacroTax/y_height.tif",(y_height),maskR)
geotiffwrite("output/20241015_JointDC_RemovedHeightDependsonMacroTax/y_roof.tif",(y_roof),maskR)
geotiffwrite("output/20241015_JointDC_RemovedHeightDependsonMacroTax/y_macrotaxo.tif",(y_macrotaxo),maskR)
geotiffwrite("output/20241015_JointDC_RemovedHeightDependsonMacroTax/y_wall.tif",(y_wall),maskR)

