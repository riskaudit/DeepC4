function [  X_batch, ...
            tau_batch, tauH_batch, tauW_batch, ...
            btype_label, label_height, ...
            ind_batch, nelem] = loadTrainData(optloadTrainData,...
            mask, label2rasterID, sub_label2rasterID,...
            s1vv, s1vh, rgb, red1, red2, red3, red4, swir1, swir2, nir,...
            dynProb, dynLabel, btype_label, label_height, bldgftprnt,...
            Q,data)

    if      optloadTrainData == 1 % run

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
                        while target > (sum(nQ.numBuilding)./n_bldg_per_pixel)
                            p = p + 0.001;
                            target = sum(x_bldgftprnt .* (x_dynProb >= p), 'all');
                        end
                        p = p - 2*0.001; 
                        target = sum(x_bldgftprnt .* (x_dynProb >= p), 'all');
            
                        while target > (sum(nQ.numBuilding)./n_bldg_per_pixel)
                            p = p + 0.0001;
                            target = sum(x_bldgftprnt .* (x_dynProb >= p), 'all');
                        end
                        p = p - 2*0.0001; 
                        target = sum(x_bldgftprnt .* (x_dynProb >= p), 'all');
            
                        while target > (sum(nQ.numBuilding)./n_bldg_per_pixel)
                            p = p + 0.00001;
                            target = sum(x_bldgftprnt .* (x_dynProb >= p), 'all');
                        end
                        p = p - 2*0.00001; 
                        target = sum(x_bldgftprnt .* (x_dynProb >= p), 'all');
            
                        while target > (sum(nQ.numBuilding)./n_bldg_per_pixel)
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
                                    normalize(rowS) ...
                                    normalize(colS) ...
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
                                    normalize(rowS) ...
                                    normalize(colS) ...
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





            save("output/20241111_DeepC4/input.mat",... ...
                "X_batch","tau_batch","tauH_batch","tauW_batch","btype_label","label_height","ind_batch","nelem")
    elseif  optloadTrainData == 2 % load
            load("output/20241111_DeepC4/input.mat",... 
            "X_batch", ...
            "tau_batch","tauH_batch","tauW_batch", ...
            "btype_label","label_height", ...
            "ind_batch","nelem")
            disp("Successfully loaded 20241111_DeepC4/input.mat")
    end

end

