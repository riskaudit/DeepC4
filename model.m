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
[bldgftprnt, ~] = readgeoraster("data/BLDG/MICROSOFT 2014-2021/rasterized_microsoftbldg.tif");

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
for rID = 258:length(label2rasterID.RASTER_ID1)
    disp("start"), tic
    if rID ~= 111 % Rudashya fix

        if rID == length(label2rasterID.RASTER_ID1)
            rID = 0;
        end


        province = string(label2rasterID.NAME_1(find(label2rasterID.RASTER_ID1 == rID)));
        district = string(label2rasterID.NAME_2(find(label2rasterID.RASTER_ID1 == rID)));
        sector = string(label2rasterID.NAME_3(find(label2rasterID.RASTER_ID1 == rID)));
        
        if rID == 112
            idx =   (mask == rID | mask == (rID-1)) & (dynLabel == 6);
        end
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
        % we are making an assumptino where a 10x10-m pixel would contain only one
        % building, on average. Or, to address this, we can compute the average
        % area of building from bldgftprnt
        average_area_x_bldgftprnt    =  sum(bldgftprnt.*idx, 'all') ./ ...
                                        sum(double(bldgftprnt.*idx>0), 'all');
        % this is interpreted as the average arae of a building in a given grid,
        % hence, the number of pixels needed for a single building would be:
        n_pixels_per_bldg = 100 ./ average_area_x_bldgftprnt; %pixels/nbldg
        
        % this follows that the microsoft x_bldgftprnt would correspond to this 
        % number of building
        nBldgFromBldgData = full(sum(x_bldgftprnt, 'all')) ./ n_pixels_per_bldg;
        
        % as we said, microsoft EO-derived data is imperfect and may always be
        % less than what the census would give us. let's now compute for the
        % remaining nBldg that we will obtain using the values of x_dynProb
        remaining_nBldg = sum(nQ.numBuilding) - nBldgFromBldgData;
        npixels_remaining_nBldg = remaining_nBldg * n_pixels_per_bldg;
        
        % let's now obtain the p_threshod of x_dynProb to meet the need of
        % n_pixels_remaining_nBlds
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
        disp("Valid Idx Obtained"), toc, tic
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
        disp("Covariate X Prepared"), toc, tic
        %% ground truth class representation for global clustering
        % ROOF - common to all rIDs
        uniq_RoofMaterial =     string(data((data.Sector == sector) & ...
                                (data.Province == province) & ...
                                (data.District == district), 28:36).Properties.VariableNames)';
        summary_RoofMaterial =  table2array(data((data.Sector == sector) & ...
                                (data.Province == province) & ...
                                (data.District == district), 28:36))';
        summary_RoofMaterial(isnan(summary_RoofMaterial)) = 0;
        summary_RoofMaterial = summary_RoofMaterial ./ sum(summary_RoofMaterial);
        
        % WALL - common to all rIDs
        uniq_WallMaterial = string(data((data.Sector == sector) & ...
                            (data.Province == province) & ...
                            (data.District == district), 14:27).Properties.VariableNames)';
        summary_WallMaterial =  table2array(data((data.Sector == sector) & ...
                                (data.Province == province) & ...
                                (data.District == district), 14:27))';
        summary_WallMaterial(isnan(summary_WallMaterial)) = 0;
        summary_WallMaterial = summary_WallMaterial ./ sum(summary_WallMaterial);
        
        % MACROTAXONOMY 
        uniq_MacroTaxonomy = unique(Q.MacroTaxonomy);
        jointProb_MacroTaxonomyANDWallMaterial = zeros( numel(uniq_MacroTaxonomy), ...
                                                        numel(uniq_WallMaterial));
        for i = 1:numel(uniq_WallMaterial)
            for j = 1:numel(uniq_MacroTaxonomy)
                jointProb_MacroTaxonomyANDWallMaterial(j,i) = ...
                    sum(nQ.numBuilding( (string(nQ.MacroTaxonomy) == uniq_MacroTaxonomy(j)) & ...
                                        (string(nQ.Material) == uniq_WallMaterial(i))   ));
            end
        end
        jointProb_MacroTaxonomyANDWallMaterial = jointProb_MacroTaxonomyANDWallMaterial ./ ...
                            sum(jointProb_MacroTaxonomyANDWallMaterial, 'all');
        
        
        % HEIGHT - that is unique to given rID
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
        
        %% model: label-agnostic training
        % we know that some of the EO bands indicate height or roof material
        % possibly jointly. we could say that the wall material is not visible to
        % be captured by the satellites. so, we gotta take the challenge that we'll
        % leverage the roof material census instead and wall height as the joint
        % labels, and then we'll post-process it with our encoded belief on the
        % relationship between roof material, wall material, and height class.
        n_class = sum(summary_RoofMaterial > 1e-5);
        [row,col] = find(x_s1vv>0); % incorporate spatial element
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
                    normalize(row) ...
                    normalize(col) ...
                    ...
                    ]);
        
        %% Constrained K-Means clustering algorithm
        % Bradley, P. S., Bennett, K. P., & Demiriz, A. (2000). 
        % Constrained k-means clustering. Microsoft Research, Redmond, 20(0), 0.
        % https://uk.mathworks.com/matlabcentral/fileexchange/117355-constrained-k-means
        tau = floor(summary_RoofMaterial .* size(X,1));
        rng(1,"v5normal"); 
        [labels,centroids] = constrainedKMeans(X, n_class, tau(tau ~= 0), 100);
        
        % assign roof material
        roof_assignment = strings(size(X,1),1);
        nonzero_idx_tau = find(tau ~= 0);
        for i = 1:n_class
        
            iX = find(labels == i);
            roof_assignment(iX,:) = uniq_RoofMaterial(nonzero_idx_tau(i));
        
        end
        
        disp("Roof Assigned"), toc, tic
    
        % encode roof material to vulnerability class
        mapping = struct;
        mapping.wall = data(:, 14:27).Properties.VariableNames';
        mapping.roof = data(:, 28:36).Properties.VariableNames';
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
    
            try
                rng(1,"v5normal"); 
                [labels,centroids] = constrainedKMeans( X(roof_assignment == uniq_RoofMaterial(nonzero_idx_tau(i)),:), ...
                                                        numel(tau_X(tau_X ~= 0)), ...
                                                        tau_X(tau_X ~= 0), ...
                                                        100);
            catch MyErr
                [labels,centroids] = constrainedKMeans( X(roof_assignment == uniq_RoofMaterial(nonzero_idx_tau(i)),:), ...
                                                        numel(tau_X(tau_X ~= 0)), ...
                                                        tau_X(tau_X ~= 0), ...
                                                        100);
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
    
    
                try
                    rng(1,"v5normal"); 
                    [labels,centroids] = constrainedKMeans( X(  (wall_assignment == string(mapping.wall(nonzero_idx_tau_X(j),1)) & ...
                                                                roof_assignment == uniq_RoofMaterial(nonzero_idx_tau(i)) ) ,:), ...
                                                            numel(tau_XX(tau_XX ~= 0)), ...
                                                            tau_XX(tau_XX ~= 0), ...
                                                            100);   
                catch MyErr
                    [labels,centroids] = constrainedKMeans( X(  (wall_assignment == string(mapping.wall(nonzero_idx_tau_X(j),1)) & ...
                                                                roof_assignment == uniq_RoofMaterial(nonzero_idx_tau(i)) ) ,:), ...
                                                            numel(tau_XX(tau_XX ~= 0)), ...
                                                            tau_XX(tau_XX ~= 0), ...
                                                            100);   
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
        disp("Wall and MacroTaxo Assigned"), toc, tic
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
            
            % this is for entries with very few rows and dimensions that lead to
            % computational NAN error ... doesn't happen oftentimes
            try
                rng(1,"v5normal"); 
                [labels,centroids] = constrainedKMeans( X( macro_taxonomy_assignment == string(uniq_MacroTaxonomy_from_assignment(j,1)) ,:), ...
                                                        numel(tau_XXX(tau_XXX ~= 0)), ...
                                                        tau_XXX(tau_XXX ~= 0), ...
                                                        100);
            catch MyErr
                [labels,centroids] = constrainedKMeans( X( macro_taxonomy_assignment == string(uniq_MacroTaxonomy_from_assignment(j,1)) ,:), ...
                                                        numel(tau_XXX(tau_XXX ~= 0)), ...
                                                        tau_XXX(tau_XXX ~= 0), ...
                                                        100);
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
        disp("Height Assigned"), toc, tic
        
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
    
        disp(rID)
        disp(province)
        disp(district)
        disp(sector)
        disp("Finished"), toc, tic
    end
end

geotiffwrite("y_height.tif",single(y_height),maskR)
geotiffwrite("y_roof.tif",single(y_roof),maskR)
geotiffwrite("y_macrotaxo.tif",single(y_macrotaxo),maskR)
geotiffwrite("y_wall.tif",single(y_wall),maskR)
