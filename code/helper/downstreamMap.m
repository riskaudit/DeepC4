clear, clc, close
cd '/Users/joshuadimasaka/Desktop/PhD/GitHub/DeepC4'

%% load maskR
[mask, maskR] = readgeoraster("data/MASK/rasterized_vector.tif");

%% load building-level data from  Bachofer
load("output/20240916_JointDC_Downstream1/input.mat",... ...
    "X_batch","tau_batch","tauH_batch","tauW_batch","btype_label","label_height","ind_batch","nelem")

load("output/20241025_DeepGC4/global/outputTrainedModels.mat",... 
    "netE_history","netD_history",...
    "xTPpropR_history","xTPpropH_history","xTPpropW_history",...
    "xTPpropR2_history","xTPpropH2_history","xTPpropW2_history",...
    "ReconstructionLoss_history","PredictionLoss_history")


%% Determine the optimal iter and epoch

select_iter = [2:12 14:15 18:21 24 26 28];
lossR_byepoch = sum(ReconstructionLoss_history'.*nelem(select_iter))...
                ./sum(nelem(select_iter));
lossP_byepoch = sum(PredictionLoss_history'.*nelem(select_iter))...
                ./sum(nelem(select_iter));
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
xTPprop2_byepoch = ...
    xTPpropR2_byepoch(joint_possible_epochs_basedonlossRP)./3 + ...
    xTPpropH2_byepoch(joint_possible_epochs_basedonlossRP)./3 + ...
    xTPpropW2_byepoch(joint_possible_epochs_basedonlossRP)./3;
xTPprop_byepoch_combined = xTPprop_byepoch./2 + xTPprop2_byepoch./2;
selected_epoch = joint_possible_epochs_basedonlossRP(xTPprop_byepoch_combined==max(xTPprop_byepoch_combined));

netE = netE_history{selected_epoch,end};
netD = netD_history{selected_epoch,end};

%% Perform downstream

y_height = zeros(size(mask));
y_roof = zeros(size(mask));
y_macrotaxo = zeros(size(mask));
y_wall = zeros(size(mask));

[   mask, maskR,...
    label2rasterID, sub_label2rasterID,...
    s1vv, s1vh, rgb, red1, red2, red3, red4, swir1, swir2, nir,...
    dynProb, dynLabel, btype_label, label_height, bldgftprnt,...
    Q,data...
    ] = loadCountryData();

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

        % HEIGHT given MACROTAXONOMY
        % uniq_MacroTaxonomy = unique(Q.MacroTaxonomy);
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
        % uniq_HeightClass = string(unique(Q.HeightClass));

        % Height
        summary_HeightClass = zeros(numel(uniq_HeightClass),1);
        for j = 1:numel(uniq_HeightClass)
            summary_HeightClass(j,1) = sum(nQ.numBuilding(string(nQ.HeightClass) == uniq_HeightClass(j)));
        end
        summary_HeightClass(isnan(summary_HeightClass)) = 0;
        summary_HeightClass = summary_HeightClass ./ sum(summary_HeightClass);
        tauH = floor(summary_HeightClass .* length(find(x_s1vv>0)));
        if sum(tauH) ~= length(find(x_s1vv>0))
            ttmp = find(tauH == max(tauH),1);
            tauH(ttmp) = tauH(ttmp) + (length(find(x_s1vv>0))-sum(tauH));
        end

        % MACROTAXONOMY GIVEN WALL
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
        % uniq_MacroTaxonomy = unique(Q.MacroTaxonomy);
        % jointProb_MacroTaxonomyANDWallMaterial = zeros( numel(uniq_MacroTaxonomy), ...
        %                                                 numel(uniq_WallClass));
        % for i = 1:numel(uniq_WallClass)
        %     for j = 1:numel(uniq_MacroTaxonomy)
        %         jointProb_MacroTaxonomyANDWallMaterial(j,i) = ...
        %             sum(nQ.numBuilding( (string(nQ.MacroTaxonomy) == uniq_MacroTaxonomy(j)) & ...
        %                                 (string(nQ.Material) == uniq_WallClass(i))   ));
        %     end
        % end
        % jointProb_MacroTaxonomyANDWallMaterial = jointProb_MacroTaxonomyANDWallMaterial ./ ...
        %                     sum(jointProb_MacroTaxonomyANDWallMaterial, 'all');
        
       

        %% Predict roof, height, and wall
        Z = forward(netE, dlarray(X, 'BC')+1e-6);

        %% ROOF
        tic, err = 1; failed = 1;
        while err > 0.01 | failed == 1
            try
                [labelsR,centroidsR] = constrainedKMeans_DEC(Z(1,:), sum(tauR > 1e-5), tauR(tauR ~= 0), 50, []);
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
        tic, err = 1; failed = 1;
        while err > 0.01 | failed == 1
            try
                [labelsH,centroidsH] = constrainedKMeans_DEC(Z(2,:), sum(tauH > 1e-5), tauH(tauH ~= 0), 50, []);
                failed = 0;
            catch MyErr
                failed = 1;
            end
            if failed == 0
                err = sum(abs((tauH(tauH ~= 0))'-(histcounts(labelsH)))) ./ sum(tauH(tauH ~= 0));
            end
        end
        height_class_assignment = strings(size(Z,2),1);
        nonzero_idx_tauH = find(tauH ~= 0);
        for i = 1:sum(tauH > 1e-5)
            iX = find(labelsH == i);
            height_class_assignment(iX,:) = uniq_HeightClass(nonzero_idx_tauH(i));
        end
        height_class_assignment_id = zeros(size(X,1),1);
        for i = 1:numel(uniq_HeightClass)
            height_class_assignment_id((height_class_assignment==uniq_HeightClass(i)),1) = i;
        end
        y_height(valid_idx==1) = height_class_assignment_id;
        toc, disp("Height Assigned"), tic

        %% WALL
        tic, err = 1; failed = 1;
        while err > 0.01 | failed == 1
            try
                [labelsW,centroidsW] = constrainedKMeans_DEC(Z(3,:), sum(tauW > 1e-5), tauW(tauW ~= 0), 50, []);
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
                                                                 tau_XX(tau_XX ~= 0), 50, []);
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
        % height_class_assignment = strings(size(X,1),1);
        % height_class_assignment_id = zeros(size(X,1),1);
        % uniq_MacroTaxonomy_from_assignment = unique(macro_taxonomy_assignment);
        % for j = 1:numel(uniq_MacroTaxonomy_from_assignment) % per macro taxo category
        % 
        %     % same explanation as before
        %     tmp_idx5 = find(uniq_MacroTaxonomy == string(uniq_MacroTaxonomy_from_assignment(j,1))   );
        %     tmp_idx6 = find(macro_taxonomy_assignment == string(uniq_MacroTaxonomy_from_assignment(j,1)) );
        % 
        %     tau_XXX = round(    numel(tmp_idx6) * ...
        %     jointProb_HeightClassANDMacroTaxonomy(:,tmp_idx5) ./ ...
        %     sum(jointProb_HeightClassANDMacroTaxonomy(:,tmp_idx5))) ;
        %     tau_XXX(isnan(tau_XXX)) = 0;
        % 
        %     if size(X(macro_taxonomy_assignment == string(uniq_MacroTaxonomy_from_assignment(j,1))) ,1) ...
        %                    < sum(tau_XXX(tau_XXX ~= 0))
        %         tau_XXX = tau_XXX - (tau_XXX == max(tau_XXX)) .* ...
        %         (sum(tau_XXX(tau_XXX ~= 0)) - ...
        %         size(X(  macro_taxonomy_assignment == string(uniq_MacroTaxonomy_from_assignment(j,1)) ),1));
        %     elseif size(X(macro_taxonomy_assignment == string(uniq_MacroTaxonomy_from_assignment(j,1))) ,1) == 1
        %         tau_XXX(jointProb_HeightClassANDMacroTaxonomy(:,tmp_idx5) == max(jointProb_HeightClassANDMacroTaxonomy(:,tmp_idx5))) = 1;
        %         tau_XXX(jointProb_HeightClassANDMacroTaxonomy(:,tmp_idx5) ~= max(jointProb_HeightClassANDMacroTaxonomy(:,tmp_idx5))) = 0;
        %         tau_XXX(isnan(tau_XXX)) = 0;
        %     end
        %     if sum(tau_XXX) ~= size(X( macro_taxonomy_assignment == string(uniq_MacroTaxonomy_from_assignment(j,1)) ,:),1)
        %         ttmp = find(tau_XXX == max(tau_XXX),1);
        %         tau_XXX(ttmp) = tau_XXX(ttmp) + (size(X( macro_taxonomy_assignment == string(uniq_MacroTaxonomy_from_assignment(j,1)) ,:),1)-sum(tau_XXX));
        %     end
        %     err = 1; failed = 1;
        %     while err > 0.01 | failed == 1
        %         try
        %             [labelsH,centroidsH] = constrainedKMeans_DEC(Z(2, macro_taxonomy_assignment==string(uniq_MacroTaxonomy_from_assignment(j,1)) ),...
        %                                                          numel(tau_XXX(tau_XXX ~= 0)), ...
        %                                                          tau_XXX(tau_XXX ~= 0), 50);
        %             failed = 0;
        %         catch MyErr
        %             failed = 1;
        %         end
        %         if failed == 0
        %             err = sum(abs((tau_XXX(tau_XXX ~= 0))'-(histcounts(labelsH)))) ./ sum(tau_XXX(tau_XXX ~= 0));
        %         end
        %     end
        %     height_class_assignment_sub = strings(size(tmp_idx6,1),1);
        %     nonzero_idx_tau_XXX = find(tau_XXX ~= 0);
        %     for i = 1:sum(tau_XXX > 1e-5)
        %         iX = find(labelsH == i);
        %         height_class_assignment_sub(iX,:) = uniq_HeightClass(nonzero_idx_tau_XXX(i));
        %     end
        %     height_class_assignment(tmp_idx6) = height_class_assignment_sub;
        %     for i = 1:numel(uniq_HeightClass)
        %         height_class_assignment_id((height_class_assignment==uniq_HeightClass(i)),1) = i;
        %     end
        % 
        % end
        % y_height(valid_idx==1) = height_class_assignment_id;
        % toc, disp("Height Assigned"), tic
        

    end
end

%% Export
geotiffwrite("output/20241025_DeepGC4/global/map/y_height.tif",(y_height),maskR)
geotiffwrite("output/20241025_DeepGC4/global/map/y_roof.tif",(y_roof),maskR)
geotiffwrite("output/20241025_DeepGC4/global/map/y_macrotaxo.tif",(y_macrotaxo),maskR)
geotiffwrite("output/20241025_DeepGC4/global/map/y_wall.tif",(y_wall),maskR)











% 1 indicates misprediction, 2 indicates TP
% geotiffwrite("output/20241015_MapTPandELSE/y_roof.tif",(y_roof),maskR)
% geotiffwrite("output/20241015_MapTPandELSE/y_height.tif",(y_height),maskR)
% geotiffwrite("output/20241015_MapTPandELSE/y_wall.tif",(y_wall),maskR)
% [y_roof, ~] = readgeoraster('output/20241015_MapTPandELSE/y_roof.tif');
% [y_height, ~] = readgeoraster('output/20241015_MapTPandELSE/y_height.tif');
% [y_wall, ~] = readgeoraster('output/20241015_MapTPandELSE/y_wall.tif');

% output a table of performance per classes
% this tells us the relative performance across classes
training_performance_roof = zeros(7,2); 
for i = 1:7
    for j = 1:2
        training_performance_roof(i,j) = ...
            sum(btype_label(:)==i & y_roof(:)==j);
    end
end
training_performance_roof(:,3) = training_performance_roof(:,1) ...
    ./sum(training_performance_roof(:,1:2),2);
training_performance_roof(:,4) = training_performance_roof(:,2) ...
    ./sum(training_performance_roof(:,1:2),2);
% training_performance_roof =
%         2347       86889
%           63        2528
%          174       41557
%           41       11054
%           17        3417
%           51        1764
%          483       15263

% 17273	71963	0.193565377202026	0.806434622797974
% 551	2040	0.212659204940178	0.787340795059823
% 3560	38171	0.0853082840094894	0.914691715990511
% 929	10166	0.0837314105452907	0.916268589454709
% 317	3117	0.0923121723937100	0.907687827606290
% 605	1210	0.333333333333333	0.666666666666667
% 4362	11384	0.277022735932935	0.722977264067065

% 2222	87014	0.0249002644672554	0.975099735532745
% 55	2536	0.0212273253570050	0.978772674642995
% 187	41544	0.00448108121061082	0.995518918789389
% 38	11057	0.00342496620099144	0.996575033799009
% 23	3411	0.00669772859638905	0.993302271403611
% 77	1738	0.0424242424242424	0.957575757575758
% 470	15276	0.0298488505017147	0.970151149498285

% 2287	86949	0.0256286700434802	0.974371329956520
% 86	2505	0.0331918178309533	0.966808182169047
% 216	41515	0.00517600824327239	0.994823991756728
% 27	11068	0.00243352861649392	0.997566471383506
% 18	3416	0.00524170064065230	0.994758299359348
% 29	1786	0.0159779614325069	0.984022038567493
% 625	15121	0.0396926203480249	0.960307379651975

training_performance_height = zeros(7,2); 
label_height_cat = ...
   ((label_height>0)&(label_height<6))              .* 1 + ...
   ((label_height>=6)&(label_height<9))             .* 2 + ...
   ((label_height>=9)&(label_height<12))            .* 3 + ...
   ((label_height>=12)&(label_height<15))           .* 4 + ...
   ((label_height>=15)&(label_height<21))           .* 5 + ...
   ((label_height>=21)&(label_height<24))           .* 6 + ...
   ((label_height>=24))                             .* 7;
for i = 1:7
    for j = 1:2
        training_performance_height(i,j) = ...
            sum(label_height_cat(:)==i & y_height(:)==j);
    end
end
training_performance_height(:,3) = training_performance_height(:,1) ...
    ./sum(training_performance_height(:,1:2),2);
training_performance_height(:,4) = training_performance_height(:,2) ...
    ./sum(training_performance_height(:,1:2),2);
% training_performance_height =
%        11961      141119
%         8944         823
%         1575          31
%          670          12
%          381           4
%           92           0
%           36           0

% 11543	141537	0.0754050169845832	0.924594983015417
% 9173	594	0.939182963038804	0.0608170369611959
% 1581	25	0.984433374844334	0.0155666251556663
% 664	18	0.973607038123167	0.0263929618768328
% 378	7	0.981818181818182	0.0181818181818182
% 91	1	0.989130434782609	0.0108695652173913
% 36	0	1	0

% 14776	138304	0.0965246929709956	0.903475307029005
% 8967	800	0.918091532712194	0.0819084672878059
% 1562	44	0.972602739726027	0.0273972602739726
% 672	10	0.985337243401760	0.0146627565982405
% 382	3	0.992207792207792	0.00779220779220779
% 92	0	1	0
% 36	0	1	0

% 15330	137750	0.100143715704207	0.899856284295793
% 9228	539	0.944814170164841	0.0551858298351592
% 1553	53	0.966998754669988	0.0330012453300125
% 668	14	0.979472140762463	0.0205278592375367
% 376	9	0.976623376623377	0.0233766233766234
% 91	1	0.989130434782609	0.0108695652173913
% 32	4	0.888888888888889	0.111111111111111

training_performance_wall = zeros(7,2); 
for i = 1:7
    for j = 1:2
        training_performance_wall(i,j) = ...
            sum(btype_label(:)==i & y_wall(:)==j);
    end
end
training_performance_wall(:,3) = training_performance_wall(:,1) ...
    ./sum(training_performance_wall(:,1:2),2);
training_performance_wall(:,4) = training_performance_wall(:,2) ...
    ./sum(training_performance_wall(:,1:2),2);
% training_performance_wall =
%            0       89236
%          708        1883
%         1120       40611
%         3514        7581
%         1056        2378
%         1804          11
%         2612       13134

% 0	89236	0	1
% 686	1905	0.264762639907372	0.735237360092628
% 6624	35107	0.158730919460353	0.841269080539647
% 5312	5783	0.478774222622803	0.521225777377197
% 1589	1845	0.462725684333139	0.537274315666861
% 1491	324	0.821487603305785	0.178512396694215
% 4711	11035	0.299187095135273	0.700812904864728

% 0	89236	0	1
% 649	1942	0.250482439212659	0.749517560787341
% 7108	34623	0.170329012005464	0.829670987994536
% 4916	6179	0.443082469580892	0.556917530419108
% 1668	1766	0.485730926033780	0.514269073966220
% 1434	381	0.790082644628099	0.209917355371901
% 4807	10939	0.305283881620729	0.694716118379271