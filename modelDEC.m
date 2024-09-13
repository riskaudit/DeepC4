clear, clc, close
cd '/Users/joshuadimasaka/Desktop/PhD/GitHub/rwa'

%% load mask
[mask, maskR] = readgeoraster("data/MASK/rasterized_vector.tif");
label2rasterID = readtable("data/MASK/MAPPING_RASTER_ID_AND_LABEL.xlsx");

%% load EO and EO-derived data
[s1vv, ~] = readgeoraster("data/VV/2022_VV_LEVEL0_RWANDA_WHOLE_10M.tif");
[s1vh, ~] = readgeoraster("data/VH/2022_VH_LEVEL0_RWANDA_WHOLE_10M.tif");
[rgb, ~] = readgeoraster("data/RGB/2022_RGB_LEVEL0_RWANDA_WHOLE_10M.tif");
[red1, ~] = readgeoraster("data/RED1234/RED1/2022_RED1_LEVEL0_RWANDA_WHOLE_10M.tif");
[red2, ~] = readgeoraster("data/RED1234/RED2/2022_RED2_LEVEL0_RWANDA_WHOLE_10M.tif");
[red3, ~] = readgeoraster("data/RED1234/RED3/2022_RED3_LEVEL0_RWANDA_WHOLE_10M.tif");
[red4, ~] = readgeoraster("data/RED1234/RED4/2022_RED4_LEVEL0_RWANDA_WHOLE_10M.tif");
[swir1, ~] = readgeoraster("data/SWIR12NIR/SWIR1/2022_SWIR1_LEVEL0_RWANDA_WHOLE_10M.tif");
[swir2, ~] = readgeoraster("data/SWIR12NIR/SWIR2/2022_SWIR2_LEVEL0_RWANDA_WHOLE_10M.tif");
[nir, ~] = readgeoraster("data/SWIR12NIR/NIR/2022_NIR_LEVEL0_RWANDA_WHOLE_10M.tif");
[dynProb, ~] = readgeoraster("data/DYNAMIC/builtAveProb/2022_DYNNAMICWORLD_builtAveProb_LEVEL0_RWANDA_WHOLE_10M.tif");
[dynLabel, ~] = readgeoraster("data/DYNAMIC/labelModeCat/2022_DYNNAMICWORLD_labelModeCat_LEVEL0_RWANDA_WHOLE_10M.tif");
[bldgftprnt_osm, ~] = readgeoraster("data/BLDG/OPENSTREETMAP/rasterized_OSM.tif");
[bldgftprnt_ove, ~] = readgeoraster("data/BLDG/OVERTURE/rasterized_Overture.tif");
[bldgftprnt_goo, ~] = readgeoraster("data/BLDG/GOOGLE 042021-052023/rasterized_googleOpenBldg.tif");
[bldgftprnt_mic, ~] = readgeoraster("data/BLDG/MICROSOFT 2014-2021/rasterized_microsoftbldg.tif");
[btype_label, ~] = readgeoraster("data/BLDG/BACHOFER DLR/EO4Kigali_2015_btype.tif");
bldgftprnt = (bldgftprnt_osm > 0) | (bldgftprnt_ove > 0) | (bldgftprnt_goo > 0) | (bldgftprnt_mic > 0);
% geotiffwrite("data/BLDG/bldgcombined.tif",single(bldgftprnt),maskR)

%% load census records
census_fpath = "data/CENSUS 2022/census2022.csv";
macro_taxonomy_table_fpath = "data/CENSUS 2022/macro_taxonomy_table.csv";
height_table_fpath= "data/CENSUS 2022/height_table.csv";
dwelling_table_fpath = "data/CENSUS 2022/dwelling_table.csv";
[Q, data] = preprocessCensus(   census_fpath, ...
                                macro_taxonomy_table_fpath, ...
                                height_table_fpath, ...
                                dwelling_table_fpath);
clear   census_fpath macro_taxonomy_table_fpath ... 
        height_table_fpath dwelling_table_fpath

%% 
y_height = zeros(size(mask));
y_roof = zeros(size(mask));
y_macrotaxo = zeros(size(mask));
y_wall = zeros(size(mask));

%% 
% rID = 403, Sanity Check 1: Case of Gatenga (sector), City of Kigali
% rID = 412, Sanity Check 2: Case of Gitega (sector), City of Kigali
% rID = 404, Sanity Check 3: Case of Gikondon
% rID = 411, DEC Check 1: Case of 'Nyarugunga'
% rID = 414, DEC Check 1: Case of 'Kigali'
% subset
sub_label2rasterID = readtable("data/BLDG/BACHOFER DLR/rID_coverage.csv");

X = [];
row = [];
col = [];
ind = [];
tau = zeros(4,1);

ind_batch = cell(length(sub_label2rasterID.RASTER_ID1),1);
X_batch = cell(length(sub_label2rasterID.RASTER_ID1),1);
tau_batch = cell(length(sub_label2rasterID.RASTER_ID1),1);
n_class_batch = cell(length(sub_label2rasterID.RASTER_ID1),1);
indtemp_batch = cell(length(sub_label2rasterID.RASTER_ID1),1);

for idx_rID = 1:length(sub_label2rasterID.RASTER_ID1)

    rID = sub_label2rasterID.RASTER_ID1(idx_rID);

    disp("start"), tic

    if rID == length(label2rasterID.RASTER_ID1)
        rID = 0;
    end
    if rID ~= 111 && ...
       string(label2rasterID.NAME_3(find(label2rasterID.RASTER_ID1 == rID))) ~= "Lac Kivu" % Rudashya Fix and Lake Kivu Fix

        province = string(label2rasterID.NAME_1(find(label2rasterID.RASTER_ID1 == rID)));
        district = string(label2rasterID.NAME_2(find(label2rasterID.RASTER_ID1 == rID)));
        sector = string(label2rasterID.NAME_3(find(label2rasterID.RASTER_ID1 == rID)));
        
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
        sub_label_roof  = sparse(double(btype_label(find(x_s1vv>0))));
        temp = sub_label_roof;
        indtemp = find(temp>0 & temp<=7);
        indtemp_batch{idx_rID,1} = indtemp;

        if ~isempty(indtemp)

            ind_batch{idx_rID,1} = find(x_s1vv>0);
            ind = [ind; ind_batch{idx_rID,1}];
    
            
            [rowS,colS] = find(x_s1vv>0); % incorporate spatial element
            row = [row; rowS];
            col = [col; colS];
    
    
            X_batch{idx_rID,1} = full([  ...
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
                        % normalize(rowS) ...
                        % normalize(colS) ...
                        ...
                        ]);
            X = [X; full([  ...
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
                        % normalize(rowS) ...
                        % normalize(colS) ...
                        ...
                        ])];
    
    
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
            tauS = floor(summary_RoofMaterial .* length(find(x_s1vv>0)));
            if sum(tauS) ~= length(find(x_s1vv>0))
                ttmp = find(tauS == max(tauS),1);
                tauS(ttmp) = tauS(ttmp) + (length(find(x_s1vv>0))-sum(tauS));
            end
            tau = tau + tauS;
            n_class = sum(tau > 1e-5);
            tau_batch{idx_rID,1} = tauS;
            n_class_batch{idx_rID,1} = sum(tauS > 1e-5);
        end

    end
end


% Remove empty batches
nelem = zeros(length(n_class_batch),1);
for i = 1:length(n_class_batch)
    nelem(i,1) = length(indtemp_batch{i});
end 
idx_removed = [];
for i = 1:length(n_class_batch)
    if isempty(n_class_batch{i}) | nelem(i) < 100 %found out that a small data worsens the learning
        idx_removed = [idx_removed i];
    end
end
if ~isempty(idx_removed)
    X_batch(idx_removed,:) = [];
    ind_batch(idx_removed,:) = [];
    tau_batch(idx_removed,:) = [];
    n_class_batch(idx_removed,:) = [];
    indtemp_batch(idx_removed,:) = [];
end
nelem = zeros(length(n_class_batch),1);
for i = 1:length(n_class_batch)
    nelem(i,1) = length(indtemp_batch{i});
end 


        
% WALL - common to all rIDs
% uniq_WallMaterial = string(data((data.Sector == sector) & ...
%                     (data.Province == province) & ...
%                     (data.District == district), 14:21).Properties.VariableNames)';
% summary_WallMaterial =  table2array(data((data.Sector == sector) & ...
%                         (data.Province == province) & ...
%                         (data.District == district), 14:21))';
% summary_WallMaterial(isnan(summary_WallMaterial)) = 0;
% summary_WallMaterial = summary_WallMaterial ./ sum(summary_WallMaterial);
% 
% % MACROTAXONOMY 
% uniq_MacroTaxonomy = unique(Q.MacroTaxonomy);
% jointProb_MacroTaxonomyANDWallMaterial = zeros( numel(uniq_MacroTaxonomy), ...
%                                                 numel(uniq_WallMaterial));
% for i = 1:numel(uniq_WallMaterial)
%     for j = 1:numel(uniq_MacroTaxonomy)
%         jointProb_MacroTaxonomyANDWallMaterial(j,i) = ...
%             sum(nQ.numBuilding( (string(nQ.MacroTaxonomy) == uniq_MacroTaxonomy(j)) & ...
%                                 (string(nQ.Material) == uniq_WallMaterial(i))   ));
%     end
% end
% jointProb_MacroTaxonomyANDWallMaterial = jointProb_MacroTaxonomyANDWallMaterial ./ ...
%                     sum(jointProb_MacroTaxonomyANDWallMaterial, 'all');
% 
% 
% % HEIGHT - that is unique to given rID
% uniq_HeightClass = unique(Q.HeightClass);
% jointProb_HeightClassANDMacroTaxonomy = zeros(  numel(uniq_HeightClass), ...
%                                                 numel(uniq_MacroTaxonomy));
% for i = 1:numel(uniq_MacroTaxonomy)
%     for j = 1:numel(uniq_HeightClass)
%         jointProb_HeightClassANDMacroTaxonomy(j,i) = ...
%             sum(nQ.numBuilding( (string(nQ.HeightClass) == uniq_HeightClass(j)) & ...
%                                 (string(nQ.MacroTaxonomy) == uniq_MacroTaxonomy(i))   ));
%     end
% end
% jointProb_HeightClassANDMacroTaxonomy = jointProb_HeightClassANDMacroTaxonomy ./ ...
%                     sum(jointProb_HeightClassANDMacroTaxonomy, 'all');

%% DR autoencoder - deep & nonlinear, probabilistic via variational,
% image-applicable via convolutional, 
numFeatures = size(X,2);
numLatentChannels = 1;

layersE = [
    featureInputLayer(numFeatures) 
    fullyConnectedLayer(10)
    reluLayer
    layerNormalizationLayer
    fullyConnectedLayer(6)
    reluLayer
    layerNormalizationLayer
    fullyConnectedLayer(3)
    fullyConnectedLayer(1)
    sigmoidLayer]; %5 %to avoid NAN, occurred to Z when encoded, must be related to the weights

layersD = [
    featureInputLayer(1)
    fullyConnectedLayer(3) 
    layerNormalizationLayer
    reluLayer
    fullyConnectedLayer(6)  
    layerNormalizationLayer
    reluLayer
    fullyConnectedLayer(10)
    fullyConnectedLayer(numFeatures)]; %14

gradDecay = 0.8;
sqGradDecay = 0.95;
learnRate = 1e-4;

netE = dlnetwork(layersE);
netD = dlnetwork(layersD);

numEpochs = 300;
nBatch = length(ind_batch);
regularization = 0.05;

trailingAvgE = [];
trailingAvgSqE = [];
trailingAvgD = [];
trailingAvgSqD = [];

monitor = trainingProgressMonitor;
monitor.Metrics = [ "ReconstructionLoss", ...
                    "PredictionLoss", ...
                    "IterationTPprop"];
monitor.XLabel = "Iteration";
groupSubPlot(monitor,"ReconstructionLoss","ReconstructionLoss");
groupSubPlot(monitor,"PredictionLoss","PredictionLoss");
groupSubPlot(monitor,"IterationTPprop","IterationTPprop");

monitor1 = trainingProgressMonitor;
monitor1.Metrics = ["BatchTPprop"];
monitor1.XLabel = "Epoch";
groupSubPlot(monitor1,"BatchTPprop","BatchTPprop");

% Loop over epochs.
epoch = 0; iter = 0;
while epoch < numEpochs && ~monitor.Stop
    epoch = epoch + 1
    xBatchTPprop = [];
    if epoch == 1
        loss2_prev = 1;
        loss3_prev = 1;
    end
    % shuffle_indexes = randperm(nBatch);
    % 26, 29, 12, 6, 7
    for iter = 1:nBatch
        j = iter;
        % iter = shuffle_indexes(j);
        % Evaluate loss and gradients.
        [loss2,loss3,...
            xTPprop,...
            gradientsE,gradientsD] = ...
            dlfeval(@modelLoss,...
                    netE,netD,...
                    dlarray(X_batch{iter}, 'BC'), ...
                    tau_batch{iter},...
                    n_class_batch{iter},...
                    btype_label,...
                    ind_batch{iter}, ...
                    loss2_prev,...
                    loss3_prev,...
                    sum(nelem),...
                    nelem(iter));
        loss2_prev = loss2;
        loss3_prev = loss3;
        xBatchTPprop = [xBatchTPprop; 
                        xTPprop.*nelem(iter)./sum(nelem)];
    
        % Update learnable parameters.
        [netE,trailingAvgE,trailingAvgSqE] = adamupdate(netE, ...
            gradientsE,trailingAvgE,trailingAvgSqE,...
            (epoch-1).*nBatch+j,learnRate,gradDecay,sqGradDecay);
    
        [netD, trailingAvgD, trailingAvgSqD] = adamupdate(netD, ...
            gradientsD,trailingAvgD,trailingAvgSqD,...
            (epoch-1).*nBatch+j,learnRate,gradDecay,sqGradDecay);
    
        recordMetrics(monitor, ...
            (epoch-1).*nBatch+j, ...
            ReconstructionLoss=loss2, ...
            PredictionLoss=loss3, ...
            IterationTPprop=xTPprop);
    end
    xBatchTPprop = sum(xBatchTPprop);
    recordMetrics(monitor1, ...
            epoch, ...
            BatchTPprop=xBatchTPprop);
end
    
    


















% Predict
[Z,mu,logSigmaSq] = forward(netE,X);
% Perform clustering.
tau = floor(summary_RoofMaterial .* size(Z,2));
if sum(tau) ~= size(Z,2)
    ttmp = find(tau == max(tau),1);
    tau(ttmp) = tau(ttmp) + (size(Z,2)-sum(tau));
end
err = 1; failed = 1;
while err > 0.01 | failed == 1
    try
        [labels,centroids] = constrainedKMeans(double(extractdata(Z)'), ...
            n_class, tau(tau ~= 0), 1000);
        failed = 0;
    catch MyErr
        failed = 1;
    end
    if failed == 0
        err = sum(abs((tau(tau ~= 0))'-(histcounts(labels)))) ...
            ./ sum(tau(tau ~= 0));
    end
end


% assign roof material
roof_assignment = strings(size(X,1),1);
nonzero_idx_tau = find(tau ~= 0);
for i = 1:n_class
    iX = find(labels == i);
    roof_assignment(iX,:) = uniq_RoofMaterial(nonzero_idx_tau(i));
end
toc, disp("Roof Assigned"), tic

% encode roof material to vulnerability class
mapping = struct;
mapping.wall = data(:, 14:21).Properties.VariableNames';
mapping.roof = data(:, 22:25).Properties.VariableNames';
mapping.wallProb = summary_WallMaterial;
mapping.roofProb = summary_RoofMaterial;
mapping.jointP = (mapping.wallProb * mapping.roofProb') ./ ...
            sum((mapping.wallProb * mapping.roofProb'), 'all');

%% constrained conditional clustering 
wall_assignment = strings(size(X,1),1);
macro_taxonomy_assignment = strings(size(X,1),1);
for i = 1:n_class % per roof category

    %% assign wall material
    tmp_idx = find(uniq_RoofMaterial == uniq_RoofMaterial(nonzero_idx_tau(i))   );
    tau_X = floor(sum(roof_assignment == uniq_RoofMaterial(nonzero_idx_tau(i))) * ...
            mapping.jointP(:,tmp_idx) ./ sum(mapping.jointP(:,tmp_idx)) );
    tau_X(isnan(tau_X)) = 0;
    if size(X(roof_assignment == uniq_RoofMaterial(nonzero_idx_tau(i))),1) < sum(tau_X(tau_X ~= 0))
        tau_X = tau_X - (tau_X == max(tau_X)) .* ...
        (sum(tau_X(tau_X ~= 0)) - size(X(roof_assignment == uniq_RoofMaterial(nonzero_idx_tau(i))),1));
    elseif size(X(roof_assignment == uniq_RoofMaterial(nonzero_idx_tau(i))),1) == 1
        temporary = sum(roof_assignment == uniq_RoofMaterial(nonzero_idx_tau(i))) * ...
            mapping.jointP(:,tmp_idx) ./ sum(mapping.jointP(:,tmp_idx));
        tau_X(temporary == max(temporary)) = 1;
        tau_X(temporary ~= max(temporary)) = 0;
        tau_X(isnan(tau_X)) = 0;
    elseif numel(tau_X(tau_X ~= 0)) == 0
        nelem = size(X(roof_assignment == uniq_RoofMaterial(nonzero_idx_tau(i))),1);
        tempelem = sum(roof_assignment == uniq_RoofMaterial(nonzero_idx_tau(i))) * ...
                mapping.jointP(:,tmp_idx) ./ sum(mapping.jointP(:,tmp_idx));
        maxelem = maxk(tempelem, nelem);
        for g = 1:nelem
            tau_X(tempelem == maxelem(g)) = 1;
        end
    end

    if sum(tau_X) ~= size(X(roof_assignment == uniq_RoofMaterial(nonzero_idx_tau(i)),:),1)
        ttmp = find(tau_X == max(tau_X),1);
        tau_X(ttmp) = tau_X(ttmp) + (size(X(roof_assignment == uniq_RoofMaterial(nonzero_idx_tau(i)),:),1)-sum(tau_X));
    end

    err = 1; failed = 1;
    while err > 0.01 | failed == 1
        try
            [labels,centroids] = constrainedKMeans( X(roof_assignment == uniq_RoofMaterial(nonzero_idx_tau(i)),:), ...
                                                    numel(tau_X(tau_X ~= 0)), ...
                                                    tau_X(tau_X ~= 0), ...
                                                    1000);
            failed = 0;
        catch MyErr
            failed = 1;
        end
        if failed == 0
            err = sum(abs(tau_X(tau_X ~= 0)'-histcounts(labels))) ./ sum(tau_X(tau_X ~= 0));
        end
    end

    % initialize
    tmp_idx2 = find(roof_assignment == uniq_RoofMaterial(nonzero_idx_tau(i)) );
    tmp2 = zeros(size(X,1),1);
    tmp2(tmp_idx2,1) = labels;
    nonzero_idx_tau_X = find(tau_X ~= 0);

    for j = 1:numel(nonzero_idx_tau_X) % per wall category
        wall_assignment(tmp2==j,1) = string(mapping.wall(nonzero_idx_tau_X(j),1));

        %% assign macro-taxonomy given wall material
        % unlike others, we'll use the settlement type ratio from nQ
        % because it has some consideration on the dwelling ratio that we
        % couldn't compute given our approach where our multi-staged
        % clustering has the "dwelling" towards the end (which was
        % considered during the estimation of pixels-to-building ratio). I
        % guess our approach here is more on surface orthogonal projection
        % of building floor area rather than accounting for the
        % population-to-dwelling-ratio complexity which can give some
        % uncertainty. If we just consider the ground floor area of a
        % building which is common to all dwelling types, we preserve the
        % building count statistics and not affected by the
        % popoulation-induced variation in the dwelling-to-building-count
        % ratios. This was what GEM used and that might be something we've
        % uniquely addressed here. But, I would still argue that we benefit
        % from the GEM outout somehow because we incorporated their results
        % to how we got a set of urban-rural ratios from their resulting
        % nQ or Q table here. Another difference we have compared with GEM
        % is the way we spatially disaggregate. Just to note, we just rely
        % on their ratio calculation, not on the use of WorldPop.
        tmp_idx3 = find(uniq_WallMaterial == string(mapping.wall(nonzero_idx_tau_X(j),1)));
        tmp_idx4 = find(wall_assignment == string(mapping.wall(nonzero_idx_tau_X(j),1)) & ...
                        roof_assignment == uniq_RoofMaterial(nonzero_idx_tau(i)) );

        tau_XX = round(    numel(tmp_idx4) * ...
                    jointProb_MacroTaxonomyANDWallMaterial(:,tmp_idx3) ./ ...
                    sum(jointProb_MacroTaxonomyANDWallMaterial(:,tmp_idx3))) ;
        tau_XX(isnan(tau_XX)) = 0;
        if size(X(( wall_assignment == string(mapping.wall(nonzero_idx_tau_X(j),1)) & ...
                    roof_assignment == uniq_RoofMaterial(nonzero_idx_tau(i)) )) ,1) < sum(tau_XX(tau_XX ~= 0))
            tau_XX = tau_XX - (tau_XX == max(tau_XX)) .* ...
            (sum(tau_XX(tau_XX ~= 0)) - ...
            size(X(( wall_assignment == string(mapping.wall(nonzero_idx_tau_X(j),1)) & ...
                    roof_assignment == uniq_RoofMaterial(nonzero_idx_tau(i)) )) ,1));
        end
        if numel(tau_XX(tau_XX ~= 0)) == 0 && size(X(( wall_assignment == string(mapping.wall(nonzero_idx_tau_X(j),1)) & ...
                    roof_assignment == uniq_RoofMaterial(nonzero_idx_tau(i)) )) ,1) == 1
            nelem = size(X(( wall_assignment == string(mapping.wall(nonzero_idx_tau_X(j),1)) & ...
                    roof_assignment == uniq_RoofMaterial(nonzero_idx_tau(i)) )) ,1);
            tempelem = numel(tmp_idx4) * ...
                    jointProb_MacroTaxonomyANDWallMaterial(:,tmp_idx3) ./ ...
                    sum(jointProb_MacroTaxonomyANDWallMaterial(:,tmp_idx3));
            maxelem = maxk(tempelem, nelem);
            idxelem = find(tempelem == maxelem);
            for g = 1:nelem
                tau_XX(idxelem(g)) = 1;
            end
        end
        if sum(tau_XX(tau_XX ~= 0)) == 0 && ...
                size(X(( wall_assignment == string(mapping.wall(nonzero_idx_tau_X(j),1)) & ...
                    roof_assignment == uniq_RoofMaterial(nonzero_idx_tau(i)) )) ,1) == 1
           tau_XX = (numel(tmp_idx4) * ...
                    jointProb_MacroTaxonomyANDWallMaterial(:,tmp_idx3) ./ ...
                    sum(jointProb_MacroTaxonomyANDWallMaterial(:,tmp_idx3)) == max(numel(tmp_idx4) * ...
                    jointProb_MacroTaxonomyANDWallMaterial(:,tmp_idx3) ./ ...
                    sum(jointProb_MacroTaxonomyANDWallMaterial(:,tmp_idx3))));
        end

        if sum(tau_XX) ~= size(X(  (wall_assignment == string(mapping.wall(nonzero_idx_tau_X(j),1)) & ...
                                    roof_assignment == uniq_RoofMaterial(nonzero_idx_tau(i)) ) ,:),1)
            ttmp = find(tau_XX == max(tau_XX),1);
            tau_XX(ttmp) = tau_XX(ttmp) + (size(X(  (wall_assignment == string(mapping.wall(nonzero_idx_tau_X(j),1)) & ...
                                                     roof_assignment == uniq_RoofMaterial(nonzero_idx_tau(i)) ) ,:),1)      -sum(tau_XX));
        end   

        err = 1; failed = 1;
        while err > 0.01 | failed == 1
            try
                [labels,centroids] = constrainedKMeans( X(  (wall_assignment == string(mapping.wall(nonzero_idx_tau_X(j),1)) & ...
                                                            roof_assignment == uniq_RoofMaterial(nonzero_idx_tau(i)) ) ,:), ...
                                                        numel(tau_XX(tau_XX ~= 0)), ...
                                                        tau_XX(tau_XX ~= 0), ...
                                                        1000);  
                failed = 0;
            catch MyErr
                failed = 1;
            end
            if failed == 0
                err = sum(abs(tau_XX(tau_XX ~= 0)'-histcounts(labels))) ./ sum(tau_XX(tau_XX ~= 0));
            end
        end

        % initialize
        tmp4 = zeros(size(X,1),1);
        tmp4(tmp_idx4,1) = labels;
        nonzero_idx_tau_XX = find(tau_XX ~= 0);

        for k = 1:numel(nonzero_idx_tau_XX) % per macro
            macro_taxonomy_assignment(tmp4==k,1) = string(uniq_MacroTaxonomy(nonzero_idx_tau_XX(k),1));
        end
    end
end
toc, disp("Wall and MacroTaxo Assigned"), tic
%% assign height class given macro-taxonomy
height_class_assignment = strings(size(X,1),1);
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
            [labels,centroids] = constrainedKMeans( X( macro_taxonomy_assignment == string(uniq_MacroTaxonomy_from_assignment(j,1)) ,:), ...
                                                    numel(tau_XXX(tau_XXX ~= 0)), ...
                                                    tau_XXX(tau_XXX ~= 0), ...
                                                    1000);
            failed = 0;
        catch MyErr
            failed = 1;
        end
        if failed == 0
            err = sum(abs(tau_XXX(tau_XXX ~= 0)'-histcounts(labels))) ./ sum(tau_XXX(tau_XXX ~= 0));
        end
    end

    % initialize
    tmp6 = zeros(size(X,1),1);
    tmp6(tmp_idx6,1) = labels;
    nonzero_idx_tau_XXX = find(tau_XXX ~= 0);

    for m = 1:numel(nonzero_idx_tau_XXX) % per height class
        height_class_assignment(tmp6==m,1) = ...
            string(uniq_HeightClass(nonzero_idx_tau_XXX(m),1));
    end

end
toc, disp("Height Assigned"), tic

height_class_assignment_id = zeros(size(X,1),1);
for i = 1:numel(uniq_HeightClass)
    height_class_assignment_id((height_class_assignment==uniq_HeightClass(i)),1) = i;
end
roof_assignment_id = zeros(size(X,1),1);
for i = 1:numel(uniq_RoofMaterial)
    roof_assignment_id((roof_assignment==uniq_RoofMaterial(i)),1) = i;
end
macro_taxonomy_assignment_id = zeros(size(X,1),1);
for i = 1:numel(uniq_MacroTaxonomy)
    macro_taxonomy_assignment_id((macro_taxonomy_assignment==uniq_MacroTaxonomy(i)),1) = i;
end
wall_assignment_id = zeros(size(X,1),1);
for i = 1:numel(uniq_WallMaterial)
    wall_assignment_id((wall_assignment==uniq_WallMaterial(i)),1) = i;
end

ii = find(valid_idx==1);
y_height(ii) = height_class_assignment_id;
y_roof(ii) = roof_assignment_id;
y_macrotaxo(ii) = macro_taxonomy_assignment_id;
y_wall(ii) = wall_assignment_id;

toc, disp("Finished"), tic

%%
geotiffwrite("output/20240907_DC_411/y_height.tif",(y_height),maskR)
geotiffwrite("output/20240907_DC_411/y_roof_DC.tif",(y_roof),maskR)
geotiffwrite("output/20240907_DC_411/y_macrotaxo.tif",(y_macrotaxo),maskR)
geotiffwrite("output/20240907_DC_411/y_wall.tif",(y_wall),maskR)
