clear, clc, close
cd '/Users/joshuadimasaka/Desktop/PhD/GitHub/DeepC4'

%% load data

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
[label_height, ~] = readgeoraster("data/BLDG/BACHOFER DLR/EO4Kigali_2015_bheight.tif");
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

%% Uncomment or load.
X = [];
row = [];
col = [];
ind = [];
tau = zeros(4,1);
tauH = zeros(6,1);
tauW = zeros(8,1); 

ind_batch = cell(length(sub_label2rasterID.RASTER_ID1),1);
X_batch = cell(length(sub_label2rasterID.RASTER_ID1),1);
n_class_batch = cell(length(sub_label2rasterID.RASTER_ID1),1);
indtemp_batch = cell(length(sub_label2rasterID.RASTER_ID1),1);

tau_batch = cell(length(sub_label2rasterID.RASTER_ID1),1);
tauH_batch = cell(length(sub_label2rasterID.RASTER_ID1),1);
tauW_batch = cell(length(sub_label2rasterID.RASTER_ID1),1);

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
        x_dynProb       = sparse(double(dynProb.*idx));
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
        sub_label_roofwall  = sparse(double(btype_label(find(x_s1vv>0))));
        sub_label_height = sparse(double(label_height(find(x_s1vv>0))));
        indtemp = find(sub_label_roofwall>0 & sub_label_roofwall<=7 & sub_label_height>0);
        indtemp_batch{idx_rID,1} = indtemp;

        if ~isempty(indtemp)

            ind_batch{idx_rID,1} = find(x_s1vv>0);
            ind = [ind; ind_batch{idx_rID,1}];


            [rowS,colS] = find(x_s1vv>0); % incorporate spatial element
            row = [row; rowS];
            col = [col; colS];


            % X_batch{idx_rID,1} = full([  ...
            %             normalize(log(x_s1vv(x_s1vv>0))) ...
            %             normalize(log(x_s1vh(x_s1vh>0))) ...
            %             normalize(log(x_r(x_r>0))) ...
            %             normalize(log(x_g(x_g>0))) ...
            %             normalize(log(x_b(x_b>0))) ...
            %             normalize(log(x_red1(x_red1>0))) ...
            %             normalize(log(x_red2(x_red2>0))) ...
            %             normalize(log(x_red3(x_red3>0))) ...
            %             normalize(log(x_red4(x_red4>0))) ...
            %             normalize(log(x_swir1(x_swir1>0))) ...
            %             normalize(log(x_swir2(x_swir2>0))) ...
            %             normalize(log(x_nir(x_nir>0))) ...
            %             normalize(rowS) ...
            %             normalize(colS) ...
            %             ...
            %             ]);
            % X = [X; full([  ...
            %             normalize(log(x_s1vv(x_s1vv>0))) ...
            %             normalize(log(x_s1vh(x_s1vh>0))) ...
            %             normalize(log(x_r(x_r>0))) ...
            %             normalize(log(x_g(x_g>0))) ...
            %             normalize(log(x_b(x_b>0))) ...
            %             normalize(log(x_red1(x_red1>0))) ...
            %             normalize(log(x_red2(x_red2>0))) ...
            %             normalize(log(x_red3(x_red3>0))) ...
            %             normalize(log(x_red4(x_red4>0))) ...
            %             normalize(log(x_swir1(x_swir1>0))) ...
            %             normalize(log(x_swir2(x_swir2>0))) ...
            %             normalize(log(x_nir(x_nir>0))) ...
            %             normalize(rowS) ...
            %             normalize(colS) ...
            %             ...
            %             ])];

            X_batch{idx_rID,1} = full([  ...
                        (x_s1vv(x_s1vv>0)) ...
                        (x_s1vh(x_s1vh>0)) ...
                        (x_r(x_r>0)) ...
                        (x_g(x_g>0)) ...
                        (x_b(x_b>0)) ...
                        (x_red1(x_red1>0)) ...
                        (x_red2(x_red2>0)) ...
                        (x_red3(x_red3>0)) ...
                        (x_red4(x_red4>0)) ...
                        (x_swir1(x_swir1>0)) ...
                        (x_swir2(x_swir2>0)) ...
                        (x_nir(x_nir>0)) ...
                        ...
                        ]);
            X = [X; full([  ...
                        (x_s1vv(x_s1vv>0)) ...
                        (x_s1vh(x_s1vh>0)) ...
                        (x_r(x_r>0)) ...
                        (x_g(x_g>0)) ...
                        (x_b(x_b>0)) ...
                        (x_red1(x_red1>0)) ...
                        (x_red2(x_red2>0)) ...
                        (x_red3(x_red3>0)) ...
                        (x_red4(x_red4>0)) ...
                        (x_swir1(x_swir1>0)) ...
                        (x_swir2(x_swir2>0)) ...
                        (x_nir(x_nir>0)) ...
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

            % HEIGHT - that is unique to given rID
            uniq_HeightClass = unique(Q.HeightClass);
            summary_HeightClass = zeros(numel(uniq_HeightClass),1);
            for j = 1:numel(uniq_HeightClass)
                summary_HeightClass(j,1) = sum(nQ.numBuilding(string(nQ.HeightClass) == uniq_HeightClass(j)));
            end
            summary_HeightClass(isnan(summary_HeightClass)) = 0;
            summary_HeightClass = summary_HeightClass ./ sum(summary_HeightClass);
            tauH_sub = floor(summary_HeightClass .* length(find(x_s1vv>0)));
            if sum(tauH_sub) ~= length(find(x_s1vv>0))
                ttmp = find(tauH_sub == max(tauH_sub),1);
                tauH_sub(ttmp) = tauH_sub(ttmp) + (length(find(x_s1vv>0))-sum(tauH_sub));
            end
            tauH = tauH + tauH_sub;
            tauH_batch{idx_rID,1} = tauH_sub;

            % WALL
            uniq_WallClass = string(unique(Q.Material));
            summary_WallClass = zeros(numel(uniq_WallClass),1);
            for j = 1:numel(uniq_WallClass)
                summary_WallClass(j,1) = sum(nQ.numBuilding(string(nQ.Material) == uniq_WallClass(j)));
            end
            summary_WallClass(isnan(summary_WallClass)) = 0;
            summary_WallClass = summary_WallClass ./ sum(summary_WallClass);
            tauW_sub = floor(summary_WallClass .* length(find(x_s1vv>0)));
            if sum(tauW_sub) ~= length(find(x_s1vv>0))
                ttmp = find(tauW_sub == max(tauW_sub),1);
                tauW_sub(ttmp) = tauW_sub(ttmp) + (length(find(x_s1vv>0))-sum(tauW_sub));
            end
            tauW = tauW + tauW_sub;
            tauW_batch{idx_rID,1} = tauW_sub;

        end

    end
end


%% Remove empty batches
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
    tauH_batch(idx_removed,:) = [];
    tauW_batch(idx_removed,:) = [];
    n_class_batch(idx_removed,:) = [];
    indtemp_batch(idx_removed,:) = [];
end
nelem = zeros(length(n_class_batch),1);
for i = 1:length(n_class_batch)
    nelem(i,1) = length(indtemp_batch{i});
end 

%% Save
% save("output/20240916_JointDC_Downstream1/input.mat",... ...
%     "X_batch","tau_batch","tauH_batch","tauW_batch","btype_label","label_height","ind_batch","nelem")
load("output/20240916_JointDC_Downstream1/input.mat",... ...
    "X_batch","tau_batch","tauH_batch","tauW_batch","btype_label","label_height","ind_batch","nelem")


%% DR autoencoder 


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

learnRate = 1e-3;

netE = dlnetwork(layersE);
netD = dlnetwork(layersD);

numEpochs = 200;
nBatch = 30;
regularization = 0.05;

trailingAvgE = [];
trailingAvgSqE = [];
trailingAvgD = [];
trailingAvgSqD = [];

gradDecay = 0.8;
sqGradDecay = 0.95;

monitor = trainingProgressMonitor;
monitor.Metrics = [ "ReconstructionLoss", ...
                    "PredictionLoss", ...
                    "IterationTPpropR", ...
                    "IterationTPpropH", ...
                    "IterationTPpropW"];
monitor.XLabel = "Iteration";
groupSubPlot(monitor,"ReconstructionLoss","ReconstructionLoss");
groupSubPlot(monitor,"PredictionLoss","PredictionLoss");
% groupSubPlot(monitor,"NLL","NLL");
groupSubPlot(monitor,"IterationTPpropR","IterationTPpropR");
groupSubPlot(monitor,"IterationTPpropH","IterationTPpropH");
groupSubPlot(monitor,"IterationTPpropW","IterationTPpropW");

monitor1 = trainingProgressMonitor;
monitor1.Metrics = ["BatchTPpropR","BatchTPpropH","BatchTPpropW"];
monitor1.XLabel = "Epoch";
groupSubPlot(monitor1,"BatchTPpropR","BatchTPpropR");
groupSubPlot(monitor1,"BatchTPpropH","BatchTPpropH");
groupSubPlot(monitor1,"BatchTPpropW","BatchTPpropW");

% Loop over epochs.
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


%%

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
    % shuffle_indexes = randperm(nBatch);
    % 26, 29, 12, 6, 7
    for iter = 1:nBatch
        iter
        if epoch == 1 && iter == 1
            gradientsE_prev = [];
            gradientsD_prev = [];
        elseif epoch == 1
            labelsLocal_prev = [];
            labelsLocalH_prev = [];
            labelsLocalW_prev = [];
        end
        j = iter;
        % iter = shuffle_indexes(j);
        % Evaluate loss and gradients.
        [loss2,loss3,...
            xTPpropR,xTPpropH,xTPpropW,...
            gradientsE,gradientsD,...
            labelsLocal_prev,labelsLocalH_prev,labelsLocalW_prev] = ...
            dlfeval(@modelLoss,...
                    netE,netD,...
                    dlarray(X_batch{iter}, 'BC'), ...
                    tau_batch{iter},...
                    tauH_batch{iter},...
                    tauW_batch{iter},...
                    btype_label,...
                    label_height,...
                    ind_batch{iter}, ...
                    loss2_prev,...
                    loss3_prev,...
                    nelem,...
                    nelem(iter),...
                    iter,...
                    gradientsE_prev,...
                    gradientsD_prev,true,epoch,...
                    labelsLocal_prev,labelsLocalH_prev,labelsLocalW_prev);
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

%% Perform downstream
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


%% Cross-Validation

load("output/20240916_JointDC_Downstream1/input.mat",... ...
    "X_batch","tau_batch","tauH_batch","tauW_batch","btype_label","label_height","ind_batch","nelem")

rng(1); cv_idx = randperm(30);

for k = 1:5

    cv_idx_test = cv_idx(6.*(k-1)+1:6*k);
    cv_idx_train = setxor(cv_idx,cv_idx_test);
    
    layersE = [
        featureInputLayer(14) 
    
        fullyConnectedLayer(10)
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
    
        fullyConnectedLayer(10) 
        eluLayer
        layerNormalizationLayer
     
        fullyConnectedLayer(14)]; 
    
    learnRate = 1e-4;
    
    netE = dlnetwork(layersE);
    netD = dlnetwork(layersD);
    
    numEpochs = 100;
    nBatch = 24;
    regularization = 0.05;
    
    trailingAvgE = [];
    trailingAvgSqE = [];
    trailingAvgD = [];
    trailingAvgSqD = [];
    
    gradDecay = 0.8;
    sqGradDecay = 0.95;
    
    monitor = trainingProgressMonitor;
    monitor.Metrics = [ "ReconstructionLoss", ...
                        "PredictionLoss", ...
                        "IterationTPpropR", ...
                        "IterationTPpropH", ...
                        "IterationTPpropW"];
    monitor.XLabel = "Iteration";
    groupSubPlot(monitor,"ReconstructionLoss","ReconstructionLoss");
    groupSubPlot(monitor,"PredictionLoss","PredictionLoss");
    % groupSubPlot(monitor,"NLL","NLL");
    groupSubPlot(monitor,"IterationTPpropR","IterationTPpropR");
    groupSubPlot(monitor,"IterationTPpropH","IterationTPpropH");
    groupSubPlot(monitor,"IterationTPpropW","IterationTPpropW");
    
    monitor1 = trainingProgressMonitor;
    monitor1.Metrics = ["BatchTPpropR","BatchTPpropH","BatchTPpropW"];
    monitor1.XLabel = "Epoch";
    groupSubPlot(monitor1,"BatchTPpropR","BatchTPpropR");
    groupSubPlot(monitor1,"BatchTPpropH","BatchTPpropH");
    groupSubPlot(monitor1,"BatchTPpropW","BatchTPpropW");
    
    % Loop over epochs.
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
        % shuffle_indexes = randperm(nBatch);
        % 26, 29, 12, 6, 7
        for n = 1:nBatch
            iter = cv_idx_train(n);
            if epoch == 1 && n == 1
                gradientsE_prev = [];
                gradientsD_prev = [];
            end
            j = iter;
            % iter = shuffle_indexes(j);
            % Evaluate loss and gradients.
            [loss2,loss3,...
                xTPpropR,xTPpropH,xTPpropW,...
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
                        loss2_prev,...
                        loss3_prev,...
                        nelem,...
                        nelem(iter),...
                        n,...
                        gradientsE_prev,...
                        gradientsD_prev);
            loss2_prev(n,1) = loss2;
            loss3_prev(n,1) = loss3;
            gradientsE_prev = gradientsE;
            gradientsD_prev = gradientsD;
            xBatchTPpropR = [xBatchTPpropR; 
                            xTPpropR.*nelem(iter)./sum(nelem)];
            xBatchTPpropH = [xBatchTPpropH; 
                            xTPpropH.*nelem(iter)./sum(nelem)];
            xBatchTPpropW = [xBatchTPpropW; 
                            xTPpropW.*nelem(iter)./sum(nelem)];
            xTPpropR_history(epoch,n) = xTPpropR;
            xTPpropH_history(epoch,n) = xTPpropH;
            xTPpropW_history(epoch,n) = xTPpropW;
            ReconstructionLoss_history(epoch,n) = loss2;
            PredictionLoss_history(epoch,n) = loss3;
    
            % Update learnable parameters.
            [netE,trailingAvgE,trailingAvgSqE] = adamupdate(netE, ...
                gradientsE,trailingAvgE,trailingAvgSqE,...
                (epoch-1).*nBatch+n,learnRate,gradDecay,sqGradDecay);
            netE_history{epoch,n} = netE;
    
            [netD, trailingAvgD, trailingAvgSqD] = adamupdate(netD, ...
                gradientsD,trailingAvgD,trailingAvgSqD,...
                (epoch-1).*nBatch+n,learnRate,gradDecay,sqGradDecay);
            netD_history{epoch,n} = netD;
    
            recordMetrics(monitor, ...
                (epoch-1).*nBatch+n, ...
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
    save("output/20241014_JointDC_CrossValidationResults/outputTrainedModels_5.mat",... 
        "netE_history","netD_history",...
        "cv_idx","cv_idx_train","cv_idx_test",...
        "xTPpropR_history","xTPpropH_history","xTPpropW_history",...
        "BatchTPpropR_history","BatchTPpropH_history","BatchTPpropW_history",...
        "ReconstructionLoss_history","PredictionLoss_history")
end