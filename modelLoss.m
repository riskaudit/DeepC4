function [loss2,loss3,xTPprop,xTPpropH,xTPpropW, ...
    gradientsE,gradientsD] = modelLoss(netE,netD,X,...
    tau,tauH,tauW,btype_label,label_height,ind,...
    loss2_prev,loss3_prev,nelem,nind,iter,gradientsE_prev,gradientsD_prev)

    %% Forward through encoder.
    % [Z,mu,logSigmaSq] = forward(netE,X);
    Z = forward(netE,X+1e-6);

    %% Forward through decoder.
    Y = forward(netD,Z);

    %% Input supervision
    sub_label_roofwall  = sparse(double(btype_label(ind)));
    sub_label_height = sparse(double(label_height(ind)));
    % sub_label_height_cat = ...
    %    ((sub_label_height>0)&(sub_label_height<=3))     .* 1 + ...
    %    ((sub_label_height>3)&(sub_label_height<=5.5))   .* 2 + ...
    %    ((sub_label_height>5.5)&(sub_label_height<=8))   .* 3 + ...
    %    ((sub_label_height>8)&(sub_label_height<=10))    .* 4 + ...
    %    ((sub_label_height>10)&(sub_label_height<=14))   .* 5 + ...
    %    ((sub_label_height>14)&(sub_label_height<=16))   .* 6 + ...
    %    ((sub_label_height>16))                          .* 7;
    sub_label_height_cat = ...
       ((sub_label_height>0)&(sub_label_height<=(3+5.5)/2))             .* 1 + ...
       ((sub_label_height>(3+5.5)/2)&(sub_label_height<=(5.5+8)/2))     .* 2 + ...
       ((sub_label_height>(5.5+8)/2)&(sub_label_height<=(8+10)/2))      .* 3 + ...
       ((sub_label_height>(8+10)/2)&(sub_label_height<=(10+14)/2))      .* 4 + ...
       ((sub_label_height>(10+14)/2)&(sub_label_height<=(14+16)/2))     .* 5 + ...
       ((sub_label_height>(14+16)/2)&(sub_label_height<=17))            .* 6 + ...
       ((sub_label_height>17))                                          .* 7;

    indtemp = find(sub_label_roofwall>0 & sub_label_roofwall<=7 & sub_label_height>0);
 
    subtemp = full(sub_label_roofwall(indtemp));
    subtempH = full(sub_label_height_cat(indtemp));
    unique_subtemp = unique(subtemp);
    unique_subtempH = unique(subtempH);
    nsubtemp = histcounts(subtemp)';
    nsubtempH = histcounts(subtempH)';

    subZ = Z(:,indtemp);

    %% Supervision constraints
    constraints_array = tau; %always 4
    constraints_array_H = tauH; %always 6
    constraints_array_W = tauW; %always 8

    %% Assign maximum allowable to get minimum constraints - roof
    % constraints_array(:,1) - tau, the global absolute constraints
    % constraints_array(:,2) - available or capacity accdng to ground truth
    % constraints_array(:3) - just the minimum of columns 1 and 2
    % constraints_array(:4) - final minimum constraints for implementation
    for i = 1:length(tau)
        if i == 1
            if tau(i) ~= 0
                col = [1 2 3 4 5 6 7];
                [common_index,~]=intersect(col,unique(subtemp)');
                constraints_array(i,2) = sum(nsubtemp(common_index));
            end
        elseif i == 2
            if tau(i) ~= 0
                col = [3 4 5];
                [common_index,~]=intersect(col,unique(subtemp)');
                constraints_array(i,2) = sum(nsubtemp(common_index));
            end
        elseif i == 3
            if tau(i) ~= 0
                col = [6];
                [common_index,~]=intersect(col,unique(subtemp)');
                constraints_array(i,2) = sum(nsubtemp(common_index));
            end
        elseif i == 4
            if tau(i) ~= 0
                col = [1];
                [common_index,~]=intersect(col,unique(subtemp)');
                constraints_array(i,2) = sum(nsubtemp(common_index));
            end
        end
    end
    constraints_array(:,3) =    constraints_array(:,1).*(constraints_array(:,1)<=constraints_array(:,2)) + ...
                                constraints_array(:,2).*(constraints_array(:,1)>constraints_array(:,2));
    constraints_array(:,4) =    constraints_array(:,3) ...
                                - max([ceil((sum(constraints_array(:,3))-size(subZ,2)).*constraints_array(:,3)./sum(constraints_array(:,3))) ...
                                        repelem(0,4)'],[],2);
    constraints_array(constraints_array(:,4)<=0,4)=0;

    %% Assign maximum allowable to get minimum constraints - height
    for i = 1:length(tauH)
        if i == 1
            if tauH(i) ~= 0
                col = [1];
                [common_index,~]=intersect(col,unique(subtempH)');
                constraints_array_H(i,2) = sum(nsubtempH(common_index));
            end
        elseif i == 2
            if tauH(i) ~= 0
                col = [2];
                [common_index,~]=intersect(col,unique(subtempH)');
                constraints_array_H(i,2) = sum(nsubtempH(common_index));
            end
        elseif i == 3
            if tauH(i) ~= 0
                col = [3];
                [common_index,~]=intersect(col,unique(subtempH)');
                constraints_array_H(i,2) = sum(nsubtempH(common_index));
            end
        elseif i == 4
            if tauH(i) ~= 0
                col = [3 4];
                [common_index,~]=intersect(col,unique(subtempH)');
                constraints_array_H(i,2) = sum(nsubtempH(common_index));
            end
        elseif i == 5
            if tauH(i) ~= 0
                col = [4 5 6];
                [common_index,~]=intersect(col,unique(subtempH)');
                constraints_array_H(i,2) = sum(nsubtempH(common_index));
            end
        elseif i == 6
            if tauH(i) ~= 0
                col = [7];
                [common_index,~]=intersect(col,unique(subtempH)');
                constraints_array_H(i,2) = sum(nsubtempH(common_index));
            end
        end
    end
    constraints_array_H(:,3) =    constraints_array_H(:,1).*(constraints_array_H(:,1)<=constraints_array_H(:,2)) + ...
                                constraints_array_H(:,2).*(constraints_array_H(:,1)>constraints_array_H(:,2));
    constraints_array_H(:,4) =    constraints_array_H(:,3) ...
                                - max([ceil((sum(constraints_array_H(:,3))-size(subZ,2)).*constraints_array_H(:,3)./sum(constraints_array_H(:,3))) ...
                                        repelem(0,6)'],[],2);
    constraints_array_H(constraints_array_H(:,4)<=0,4)=0;


    %% Assign maximum allowable to get minimum constraints - roof
    % "All non durable wall materials"
    % "Burnt bricks"
    % "Cement blocks"
    % "Concrete"
    % "Stone"
    % "Sun dried bricks"
    % "Timber"
    % "Wood with mud"
    for i = 1:length(tauW)
        if i == 1 % "All non durable wall materials"
            if tauW(i) ~= 0
                col = [1 2]; 
                [common_index,~]=intersect(col,unique(subtemp)');
                constraints_array_W(i,2) = sum(nsubtemp(common_index));
            end
        elseif i == 2 % "Burnt bricks"
            if tauW(i) ~= 0
                col = [1 2 3];
                [common_index,~]=intersect(col,unique(subtemp)');
                constraints_array_W(i,2) = sum(nsubtemp(common_index));
            end
        elseif i == 3 % "Cement blocks"
            if tauW(i) ~= 0
                col = [2 3 4 5 7];
                [common_index,~]=intersect(col,unique(subtemp)');
                constraints_array_W(i,2) = sum(nsubtemp(common_index));
            end
        elseif i == 4 % "Concrete"
            if tauW(i) ~= 0
                col = [2 3 4 5 6 7];
                [common_index,~]=intersect(col,unique(subtemp)');
                constraints_array_W(i,2) = sum(nsubtemp(common_index));
            end
        elseif i == 5 % "Stone"
            if tauW(i) ~= 0
                col = [1];
                [common_index,~]=intersect(col,unique(subtemp)');
                constraints_array_W(i,2) = sum(nsubtemp(common_index));
            end
        elseif i == 6 % "Sun dried bricks"
            if tauW(i) ~= 0
                col = [1 2 3 4];
                [common_index,~]=intersect(col,unique(subtemp)');
                constraints_array_W(i,2) = sum(nsubtemp(common_index));
            end
        elseif i == 7 % "Timber"
            if tauW(i) ~= 0
                col = [1];
                [common_index,~]=intersect(col,unique(subtemp)');
                constraints_array_W(i,2) = sum(nsubtemp(common_index));
            end
        elseif i == 8 % "Wood with mud"
            if tauW(i) ~= 0
                col = [1];
                [common_index,~]=intersect(col,unique(subtemp)');
                constraints_array_W(i,2) = sum(nsubtemp(common_index));
            end
        end
    end
    constraints_array_W(:,3) =  constraints_array_W(:,1).*(constraints_array_W(:,1)<=constraints_array_W(:,2)) + ...
                                constraints_array_W(:,2).*(constraints_array_W(:,1)>constraints_array_W(:,2));
    constraints_array_W(:,4) =  constraints_array_W(:,3) ...
                                - max([ceil((sum(constraints_array_W(:,3))-size(subZ,2)).*constraints_array_W(:,3)./sum(constraints_array_W(:,3))) ...
                                        repelem(0,8)'],[],2);
    constraints_array_W(constraints_array_W(:,4)<=0,4)=0;

    %% Perform clustering part 1 - a local for supervised.
    failed = 1;
    while failed == 1
        try

            % MinCostFlow - 98.117 at epoch 14, does not converge for long
            % epochs, results in NAN at epoch around >25, when max(ntotal)./nind;
             % - 98.416 at epoch 21, does not converge for long
            % epochs, results in NAN at epoch around >35, when nind./min(ntotal)
            [labelsLocal,centroids] = constrainedKMeans_DEC(subZ(1:2,:), ...
                sum(constraints_array(:,3)~=0), ...
                constraints_array(constraints_array(:,3)>0,4), 100);
            [labelsLocalH,centroidsH] = constrainedKMeans_DEC(subZ(3:4,:), ...
                sum(constraints_array_H(:,3)~=0), ...
                constraints_array_H(constraints_array_H(:,3)>0,4), 100);
            [labelsLocalW,centroidsW] = constrainedKMeans_DEC(subZ(5:6,:), ...
                sum(constraints_array_W(:,3)~=0), ...
                constraints_array_W(constraints_array_W(:,3)>0,4), 100);

            % Gaussian Mixture - 60%, 93.29% at epoch 142 when NLL is incorporated
            % [labelsLocal,loss4R,~,~,d2] = cluster(...
            %     fitgmdist(extractdata(subZ(1,:))',sum(constraints_array(:,3)~=0),...
            %     'CovarianceType','diagonal',...
            %     'RegularizationValue',0.01,...
            %     'SharedCovariance',true,...
            %     'Options',statset('MaxIter',1500,'TolFun',1e-5)),...
            %     extractdata(subZ(1,:))');
            % [D,n] = size(extractdata(subZ(1,:)));
            % labelsNewOneHot = reshape(onehotencode(labelsLocal,2,"ClassNames",1:sum(constraints_array(:,3)~=0)),[n sum(constraints_array(:,3)~=0) 1]);
            % Z_onehotencoded_new = extractdata(subZ(1,:)).*repmat(reshape(labelsNewOneHot,[1 n sum(constraints_array(:,3)~=0)]),[D 1 1]);
            % centroids = mean(Z_onehotencoded_new,2);
            % 
            % [labelsLocalH,loss4H,~,~,d2] = cluster(...
            %     fitgmdist(extractdata(subZ(2,:))',sum(constraints_array_H(:,3)~=0),...
            %     'CovarianceType','diagonal',...
            %     'RegularizationValue',0.01,...
            %     'SharedCovariance',true,...
            %     'Options',statset('MaxIter',1500,'TolFun',1e-5)),...
            %     extractdata(subZ(2,:))');
            % [D,n] = size(extractdata(subZ(2,:)));
            % labelsNewOneHot = reshape(onehotencode(labelsLocalH,2,"ClassNames",1:sum(constraints_array_H(:,3)~=0)),[n sum(constraints_array_H(:,3)~=0) 1]);
            % Z_onehotencoded_new = extractdata(subZ(2,:)).*repmat(reshape(labelsNewOneHot,[1 n sum(constraints_array_H(:,3)~=0)]),[D 1 1]);
            % centroidsH = mean(Z_onehotencoded_new,2);
            % 
            % [labelsLocalW,loss4W,~,~,d2] = cluster(...
            %     fitgmdist(extractdata(subZ(3,:))',sum(constraints_array_W(:,3)~=0),...
            %     'CovarianceType','diagonal',...
            %     'RegularizationValue',0.01,...
            %     'SharedCovariance',true,...
            %     'Options',statset('MaxIter',1500,'TolFun',1e-5)),...
            %     extractdata(subZ(3,:))');
            % [D,n] = size(extractdata(subZ(3,:)));
            % labelsNewOneHot = reshape(onehotencode(labelsLocalW,2,"ClassNames",1:sum(constraints_array_W(:,3)~=0)),[n sum(constraints_array_W(:,3)~=0) 1]);
            % Z_onehotencoded_new = extractdata(subZ(3,:)).*repmat(reshape(labelsNewOneHot,[1 n sum(constraints_array_W(:,3)~=0)]),[D 1 1]);
            % centroidsW = mean(Z_onehotencoded_new,2);

            % Spectral Clustering - 60%
            % labelsLocal = spectralcluster(extractdata(subZ(1:2,:))',sum(constraints_array(:,3)~=0),...
            %     "LaplacianNormalization","symmetric");
            % [D,n] = size(extractdata(subZ(1:2,:)));
            % labelsNewOneHot = reshape(onehotencode(labelsLocal,2,"ClassNames",1:sum(constraints_array(:,3)~=0)),[n sum(constraints_array(:,3)~=0) 1]);
            % Z_onehotencoded_new = extractdata(subZ(1:2,:)).*repmat(reshape(labelsNewOneHot,[1 n sum(constraints_array(:,3)~=0)]),[D 1 1]);
            % centroids = mean(Z_onehotencoded_new,2);
            % 
            % labelsLocalH = spectralcluster(extractdata(subZ(3:4,:))',sum(constraints_array_H(:,3)~=0),...
            %     "LaplacianNormalization","symmetric");
            % [D,n] = size(extractdata(subZ(3:4,:)));
            % labelsNewOneHot = reshape(onehotencode(labelsLocalH,2,"ClassNames",1:sum(constraints_array_H(:,3)~=0)),[n sum(constraints_array_H(:,3)~=0) 1]);
            % Z_onehotencoded_new = extractdata(subZ(3:4,:)).*repmat(reshape(labelsNewOneHot,[1 n sum(constraints_array_H(:,3)~=0)]),[D 1 1]);
            % centroidsH = mean(Z_onehotencoded_new,2);
            % 
            % labelsLocalW = spectralcluster(extractdata(subZ(5:6,:))',sum(constraints_array_W(:,3)~=0),...
            %     "LaplacianNormalization","symmetric");
            % [D,n] = size(extractdata(subZ(5:6,:)));
            % labelsNewOneHot = reshape(onehotencode(labelsLocalW,2,"ClassNames",1:sum(constraints_array_W(:,3)~=0)),[n sum(constraints_array_W(:,3)~=0) 1]);
            % Z_onehotencoded_new = extractdata(subZ(5:6,:)).*repmat(reshape(labelsNewOneHot,[1 n sum(constraints_array_W(:,3)~=0)]),[D 1 1]);
            % centroidsW = mean(Z_onehotencoded_new,2);

            % Traditonal KMeans
            % [labelsLocal,centroids] = kmeans(extractdata(subZ(1:2,:))', ...
            %     sum(constraints_array(:,3)~=0),'MaxIter',250);
            % centroids = reshape(centroids',[2 1 sum(constraints_array(:,3)~=0)]);
            % [labelsLocalH,centroidsH] = kmeans(extractdata(subZ(3:4,:))', ...
            %     sum(constraints_array_H(:,3)~=0),'MaxIter',250);
            % centroidsH = reshape(centroidsH',[2 1 sum(constraints_array_H(:,3)~=0)]);
            % [labelsLocalW,centroidsW] = kmeans(extractdata(subZ(5:6,:))', ...
            %     sum(constraints_array_W(:,3)~=0),'MaxIter',250);
            % centroidsW = reshape(centroidsW,[2 1 sum(constraints_array_W(:,3)~=0)]);

            failed = 0;
        catch MyErr
            failed = 1;
        end
    end

    %% Calculate PredictionLoss Roof
    identified_classes_index = find(tau ~= 0);
    distance_error_array = sqrt((centroids-subZ(1:2,:)).^2);
    loss3_basedOnDistanceError = 0;
    for i = 1:length(nsubtemp)
        if      i == 1 && any(unique_subtemp==i)
                if nsubtemp(i) ~= 0
                    col = [1 4];
                    [common_index,~]=intersect(col,identified_classes_index);
                    if ~isempty(common_index)
                        loss3_basedOnDistanceError = loss3_basedOnDistanceError + ...
                            mean(sum((subtemp==i)' .* mean(distance_error_array(:,:,common_index),1))./nsubtemp(i));
                    end
                end
        elseif  i == 2 && any(unique_subtemp==i)
                if nsubtemp(i) ~= 0 
                    col = [1];
                    [common_index,~]=intersect(col,identified_classes_index);
                    if ~isempty(common_index)
                        loss3_basedOnDistanceError = loss3_basedOnDistanceError + ...
                            mean(sum((subtemp==i)' .* mean(distance_error_array(:,:,common_index),1))./nsubtemp(i));
                    end
                end
        elseif  i == 3 && any(unique_subtemp==i)
                if nsubtemp(i) ~= 0 
                    col = [1 2];
                    [common_index,~]=intersect(col,identified_classes_index);
                    if ~isempty(common_index)
                        loss3_basedOnDistanceError = loss3_basedOnDistanceError + ...
                            mean(sum((subtemp==i)' .* mean(distance_error_array(:,:,common_index),1))./nsubtemp(i));
                    end
                end
        elseif  i == 4 && any(unique_subtemp==i)
                if nsubtemp(i) ~= 0 
                    col = [1 2];
                    [common_index,~]=intersect(col,identified_classes_index);
                    if ~isempty(common_index)
                        loss3_basedOnDistanceError = loss3_basedOnDistanceError + ...
                            mean(sum((subtemp==i)' .* mean(distance_error_array(:,:,common_index),1))./nsubtemp(i));
                    end
                end
        elseif  i == 5
                if nsubtemp(i) ~= 0 
                    col = [1 2];
                    [common_index,~]=intersect(col,identified_classes_index);
                    if ~isempty(common_index)
                        loss3_basedOnDistanceError = loss3_basedOnDistanceError + ...
                            mean(sum((subtemp==i)' .* mean(distance_error_array(:,:,common_index),1))./nsubtemp(i));
                    end
                end
        elseif  i == 6
                if nsubtemp(i) ~= 0 
                    col = [1 3];
                    [common_index,~]=intersect(col,identified_classes_index);
                    if ~isempty(common_index)
                        loss3_basedOnDistanceError = loss3_basedOnDistanceError + ...
                            mean(sum((subtemp==i)' .* mean(distance_error_array(:,:,common_index),1))./nsubtemp(i));
                    end
                end
        elseif  i == 7
                if nsubtemp(i) ~= 0 
                    col = [1];
                    [common_index,~]=intersect(col,identified_classes_index);
                    if ~isempty(common_index)
                        loss3_basedOnDistanceError = loss3_basedOnDistanceError + ...
                            mean(sum((subtemp==i)' .* mean(distance_error_array(:,:,common_index),1))./nsubtemp(i));
                    end
                end
        end
    end

    %% Calculate PredictionLoss Height
    true_centroidH_index = find(constraints_array_H(:,3)>0);
    centroidH_index = (1:sum(constraints_array_H(:,3)~=0))';
    distance_error_arrayH = sqrt((centroidsH-subZ(3:4,:)).^2);
    loss3_basedOnDistanceErrorH = 0;
    for i = 1:length(nsubtempH) % based on bachofer, 7 categories
        if      i == 1 && any(unique_subtempH==i) % (0,3]
                col = [1]; 
                [common_index,~]=intersect(col,true_centroidH_index);
                [~,ia,~] = intersect(true_centroidH_index,common_index);
                common_index2 = centroidH_index(ia);
                if ~isempty(common_index2)
                    loss3_basedOnDistanceErrorH = loss3_basedOnDistanceErrorH + ...
                        mean(sum((subtempH==i)' .* mean(distance_error_arrayH(:,:,common_index2),1))./nsubtempH(i));
                end
        elseif  i == 2 && any(unique_subtempH==i) % (3,5.5]
                col = [2]; 
                [common_index,~]=intersect(col,true_centroidH_index);
                [~,ia,~] = intersect(true_centroidH_index,common_index);
                common_index2 = centroidH_index(ia);
                if ~isempty(common_index2)
                    loss3_basedOnDistanceErrorH = loss3_basedOnDistanceErrorH + ...
                        mean(sum((subtempH==i)' .* mean(distance_error_arrayH(:,:,common_index2),1))./nsubtempH(i));
                end
        elseif  i == 3 && any(unique_subtempH==i) % (5.5,8] 
                col = [3 4]; 
                [common_index,~]=intersect(col,true_centroidH_index);
                [~,ia,~] = intersect(true_centroidH_index,common_index);
                common_index2 = centroidH_index(ia);
                if ~isempty(common_index2)
                    loss3_basedOnDistanceErrorH = loss3_basedOnDistanceErrorH + ...
                        mean(sum((subtempH==i)' .* mean(distance_error_arrayH(:,:,common_index2),1))./nsubtempH(i));
                end
        elseif  i == 4 && any(unique_subtempH==i) % (8,10]
                col = [4 5]; 
                [common_index,~]=intersect(col,true_centroidH_index);
                [~,ia,~] = intersect(true_centroidH_index,common_index);
                common_index2 = centroidH_index(ia);
                if ~isempty(common_index2)
                    loss3_basedOnDistanceErrorH = loss3_basedOnDistanceErrorH + ...
                        mean(sum((subtempH==i)' .* mean(distance_error_arrayH(:,:,common_index2),1))./nsubtempH(i));
                end
        elseif  i == 5 && any(unique_subtempH==i) % (10,14]
                col = [4 5]; 
                [common_index,~]=intersect(col,true_centroidH_index);
                [~,ia,~] = intersect(true_centroidH_index,common_index);
                common_index2 = centroidH_index(ia);
                if ~isempty(common_index2)
                    loss3_basedOnDistanceErrorH = loss3_basedOnDistanceErrorH + ...
                        mean(sum((subtempH==i)' .* mean(distance_error_arrayH(:,:,common_index2),1))./nsubtempH(i));
                end
        elseif  i == 6 && any(unique_subtempH==i) % (14,16]
                col = [5]; 
                [common_index,~]=intersect(col,true_centroidH_index);
                [~,ia,~] = intersect(true_centroidH_index,common_index);
                common_index2 = centroidH_index(ia);
                if ~isempty(common_index2)
                    loss3_basedOnDistanceErrorH = loss3_basedOnDistanceErrorH + ...
                        mean(sum((subtempH==i)' .* mean(distance_error_arrayH(:,:,common_index2),1))./nsubtempH(i));
                end
        elseif  i == 7 && any(unique_subtempH==i) % (16,inf]
                col = [6]; 
                [common_index,~]=intersect(col,true_centroidH_index);
                [~,ia,~] = intersect(true_centroidH_index,common_index);
                common_index2 = centroidH_index(ia);
                if ~isempty(common_index2)
                    loss3_basedOnDistanceErrorH = loss3_basedOnDistanceErrorH + ...
                        mean(sum((subtempH==i)' .* mean(distance_error_arrayH(:,:,common_index2),1))./nsubtempH(i));
                end
        end
    end

    %% Calculate PredictionLoss Wall
    true_centroidW_index = find(constraints_array_W(:,3)>0);
    centroidW_index = (1:sum(constraints_array_W(:,3)~=0))';
    distance_error_arrayW = sqrt((centroidsW-subZ(5:6,:)).^2);
    loss3_basedOnDistanceErrorW = 0;
    for i = 1:length(nsubtemp) %nsubtemp contains 7 bachofer categories, 
        if      i == 1 && any(unique_subtemp==i) % 1: Rudimentary, basic or unplanned buildings
                col = [1 2 5 6 7 8];
                % "All non durable wall materials"
                % "Burnt bricks"
                % "Stone"
                % "Sun dried bricks"
                % "Timber"
                % "Wood with mud"
                [common_index,~]=intersect(col,true_centroidW_index);
                [~,ia,~] = intersect(true_centroidW_index,common_index);
                common_index2 = centroidW_index(ia);
                if ~isempty(common_index2)
                    loss3_basedOnDistanceErrorW = loss3_basedOnDistanceErrorW + ...
                        mean(sum((subtemp==i)' .* mean(distance_error_arrayW(:,:,common_index2),1))./nsubtemp(i));
                end
        elseif  i == 2 && any(unique_subtemp==i) % 2: Building in block structure/large courtyard buildings
                col = [1 2 3 4 6];
                % "All non durable wall materials"
                % "Burnt bricks"
                % "Cement blocks"
                % "Concrete"
                % "Sun dried bricks"
                [common_index,~]=intersect(col,true_centroidW_index);
                [~,ia,~] = intersect(true_centroidW_index,common_index);
                common_index2 = centroidW_index(ia);
                if ~isempty(common_index2)
                    loss3_basedOnDistanceErrorW = loss3_basedOnDistanceErrorW + ...
                        mean(sum((subtemp==i)' .* mean(distance_error_arrayW(:,:,common_index2),1))./nsubtemp(i));
                end
        elseif  i == 3 && any(unique_subtemp==i) % 3: Bungalow-type buildings
                col = [2 3 4 6];
                % "Burnt bricks"
                % "Cement blocks"
                % "Concrete"
                % "Sun dried bricks"
                [common_index,~]=intersect(col,true_centroidW_index);
                [~,ia,~] = intersect(true_centroidW_index,common_index);
                common_index2 = centroidW_index(ia);
                if ~isempty(common_index2)
                    loss3_basedOnDistanceErrorW = loss3_basedOnDistanceErrorW + ...
                        mean(sum((subtemp==i)' .* mean(distance_error_arrayW(:,:,common_index2),1))./nsubtemp(i));
                end
        elseif  i == 4 && any(unique_subtemp==i) % 4: Villa-type buildings
                col = [3 4 6];
                % "Cement blocks"
                % "Concrete"
                % "Sun dried bricks"
                [common_index,~]=intersect(col,true_centroidW_index);
                [~,ia,~] = intersect(true_centroidW_index,common_index);
                common_index2 = centroidW_index(ia);
                if ~isempty(common_index2)
                    loss3_basedOnDistanceErrorW = loss3_basedOnDistanceErrorW + ...
                        mean(sum((subtemp==i)' .* mean(distance_error_arrayW(:,:,common_index2),1))./nsubtemp(i));
                end
        elseif  i == 5 && any(unique_subtemp==i) % 5: Low to mid-rise multi-unit buildings
                col = [3 4];
                % "Cement blocks"
                % "Concrete"
                [common_index,~]=intersect(col,true_centroidW_index);
                [~,ia,~] = intersect(true_centroidW_index,common_index);
                common_index2 = centroidW_index(ia);
                if ~isempty(common_index2)
                    loss3_basedOnDistanceErrorW = loss3_basedOnDistanceErrorW + ...
                        mean(sum((subtemp==i)' .* mean(distance_error_arrayW(:,:,common_index2),1))./nsubtemp(i));
                end
        elseif  i == 6 && any(unique_subtemp==i) % 6: High-rise buildings
                col = [4];
                % "Concrete"
                [common_index,~]=intersect(col,true_centroidW_index);
                [~,ia,~] = intersect(true_centroidW_index,common_index);
                common_index2 = centroidW_index(ia);
                if ~isempty(common_index2)
                    loss3_basedOnDistanceErrorW = loss3_basedOnDistanceErrorW + ...
                        mean(sum((subtemp==i)' .* mean(distance_error_arrayW(:,:,common_index2),1))./nsubtemp(i));
                end
        elseif  i == 7 && any(unique_subtemp==i) % 7: Halls
                col = [3 4];
                % "Cement blocks"
                % "Concrete"
                [common_index,~]=intersect(col,true_centroidW_index);
                [~,ia,~] = intersect(true_centroidW_index,common_index);
                common_index2 = centroidW_index(ia);
                if ~isempty(common_index2)
                    loss3_basedOnDistanceErrorW = loss3_basedOnDistanceErrorW + ...
                        mean(sum((subtemp==i)' .* mean(distance_error_arrayW(:,:,common_index2),1))./nsubtemp(i));
                end
        end
    end

    %% Add them all together
    loss3 = loss3_basedOnDistanceError + loss3_basedOnDistanceErrorH + loss3_basedOnDistanceErrorW;
    % loss4 = loss4R + loss4H + loss4W;

    %% Reconstruction Loss
    loss2 = mse(Y,X);

    %% Metrics Roof 
    sub_y_roof = labelsLocal;
    xTPprop = (1./size(indtemp,1)) .* sum(...
       (subtemp==1) .* (sub_y_roof==1|sub_y_roof==4) + ...
       (subtemp==2) .* (sub_y_roof==1) + ...
       (subtemp==3) .* (sub_y_roof==1|sub_y_roof==2) + ...
       (subtemp==4) .* (sub_y_roof==1|sub_y_roof==2) + ...
       (subtemp==5) .* (sub_y_roof==1|sub_y_roof==2) + ...
       (subtemp==6) .* (sub_y_roof==1|sub_y_roof==3) + ...
       (subtemp==7) .* (sub_y_roof==1) ...
       );
    % weighted_metric_roof = zeros(7,5);
    % for i = 1:7
    %     weighted_metric_roof(i,1) = sum(subtemp==i);
    % end
    % i = 1;
    % C = confusionmat((subtemp==i),(sub_y_roof==1|sub_y_roof==4),'Order',[0 1]);
    % weighted_metric_roof(i,2) = C(2,2) ./ (C(2,2)+C(2,1));
    % weighted_metric_roof(i,3) = C(2,2) ./ (C(2,2)+C(1,2));
    % weighted_metric_roof(i,4) = (C(2,2)+C(1,1)) ./ (C(2,2)+C(2,1)+C(1,1)+C(1,2));
    % weighted_metric_roof(i,5) = 2.*C(2,2) ./ (2.*C(2,2)+C(1,2)+C(2,1));
    % i = 2;
    % C = confusionmat((subtemp==i),(sub_y_roof==1),'Order',[0 1]);
    % weighted_metric_roof(i,2) = C(2,2) ./ (C(2,2)+C(2,1));
    % weighted_metric_roof(i,3) = C(2,2) ./ (C(2,2)+C(1,2));
    % weighted_metric_roof(i,4) = (C(2,2)+C(1,1)) ./ (C(2,2)+C(2,1)+C(1,1)+C(1,2));
    % weighted_metric_roof(i,5) = 2.*C(2,2) ./ (2.*C(2,2)+C(1,2)+C(2,1));
    % i = 3;
    % C = confusionmat((subtemp==i),(sub_y_roof==1|sub_y_roof==2),'Order',[0 1]);
    % weighted_metric_roof(i,2) = C(2,2) ./ (C(2,2)+C(2,1));
    % weighted_metric_roof(i,3) = C(2,2) ./ (C(2,2)+C(1,2));
    % weighted_metric_roof(i,4) = (C(2,2)+C(1,1)) ./ (C(2,2)+C(2,1)+C(1,1)+C(1,2));
    % weighted_metric_roof(i,5) = 2.*C(2,2) ./ (2.*C(2,2)+C(1,2)+C(2,1));
    % i = 4;
    % C = confusionmat((subtemp==i),(sub_y_roof==1|sub_y_roof==2),'Order',[0 1]);
    % weighted_metric_roof(i,2) = C(2,2) ./ (C(2,2)+C(2,1));
    % weighted_metric_roof(i,3) = C(2,2) ./ (C(2,2)+C(1,2));
    % weighted_metric_roof(i,4) = (C(2,2)+C(1,1)) ./ (C(2,2)+C(2,1)+C(1,1)+C(1,2));
    % weighted_metric_roof(i,5) = 2.*C(2,2) ./ (2.*C(2,2)+C(1,2)+C(2,1));
    % i = 5;
    % C = confusionmat((subtemp==i),(sub_y_roof==1|sub_y_roof==2),'Order',[0 1]);
    % weighted_metric_roof(i,2) = C(2,2) ./ (C(2,2)+C(2,1));
    % weighted_metric_roof(i,3) = C(2,2) ./ (C(2,2)+C(1,2));
    % weighted_metric_roof(i,4) = (C(2,2)+C(1,1)) ./ (C(2,2)+C(2,1)+C(1,1)+C(1,2));
    % weighted_metric_roof(i,5) = 2.*C(2,2) ./ (2.*C(2,2)+C(1,2)+C(2,1));
    % i = 6;
    % C = confusionmat((subtemp==i),(sub_y_roof==1|sub_y_roof==3),'Order',[0 1]);
    % weighted_metric_roof(i,2) = C(2,2) ./ (C(2,2)+C(2,1));
    % weighted_metric_roof(i,3) = C(2,2) ./ (C(2,2)+C(1,2));
    % weighted_metric_roof(i,4) = (C(2,2)+C(1,1)) ./ (C(2,2)+C(2,1)+C(1,1)+C(1,2));
    % weighted_metric_roof(i,5) = 2.*C(2,2) ./ (2.*C(2,2)+C(1,2)+C(2,1));
    % i = 7;
    % C = confusionmat((subtemp==i),(sub_y_roof==1),'Order',[0 1]);
    % weighted_metric_roof(i,2) = C(2,2) ./ (C(2,2)+C(2,1));
    % weighted_metric_roof(i,3) = C(2,2) ./ (C(2,2)+C(1,2));
    % weighted_metric_roof(i,4) = (C(2,2)+C(1,1)) ./ (C(2,2)+C(2,1)+C(1,1)+C(1,2));
    % weighted_metric_roof(i,5) = 2.*C(2,2) ./ (2.*C(2,2)+C(1,2)+C(2,1));
    % weighted_metric_roof(isnan(weighted_metric_roof)) = 0;
    % weighted_metric_roof(8,1) = sum(weighted_metric_roof(1:7,1));
    % xPre = sum((weighted_metric_roof(1:7,1) ./ weighted_metric_roof(8,1)) .* ... 
    %                             weighted_metric_roof(1:7,2));
    % xRec = sum((weighted_metric_roof(1:7,1) ./ weighted_metric_roof(8,1)) .* ... 
    %                             weighted_metric_roof(1:7,3));
    % xAccu = sum((weighted_metric_roof(1:7,1) ./ weighted_metric_roof(8,1)) .* ... 
    %                             weighted_metric_roof(1:7,4));
    % xF1 = sum((weighted_metric_roof(1:7,1) ./ weighted_metric_roof(8,1)) .* ... 
    %                             weighted_metric_roof(1:7,5));

    %% Metrics Height
    sub_y_height = true_centroidH_index(labelsLocalH); %range is 1 to 6, cat
    xTPpropH = (1./size(indtemp,1)) .* sum(...
       (subtempH==1) .* (sub_y_height==1) + ...
       (subtempH==2) .* (sub_y_height==2) + ...
       (subtempH==3) .* (sub_y_height==3|sub_y_height==4) + ...
       (subtempH==4) .* (sub_y_height==4|sub_y_height==5) + ...
       (subtempH==5) .* (sub_y_height==4|sub_y_height==5) + ...
       (subtempH==6) .* (sub_y_height==5) + ...
       (subtempH==7) .* (sub_y_height==6) ...
       );
    % weighted_metric_height = zeros(7,5);
    % for i = 1:7
    %     weighted_metric_height(i,1) = sum(subtempH==i);
    % end
    % i = 1;
    % C = confusionmat((subtempH==i),(sub_y_height==1),'Order',[0 1]);
    % weighted_metric_height(i,2) = C(2,2) ./ (C(2,2)+C(2,1));
    % weighted_metric_height(i,3) = C(2,2) ./ (C(2,2)+C(1,2));
    % weighted_metric_height(i,4) = (C(2,2)+C(1,1)) ./ (C(2,2)+C(2,1)+C(1,1)+C(1,2));
    % weighted_metric_height(i,5) = 2.*C(2,2) ./ (2.*C(2,2)+C(1,2)+C(2,1));
    % i = 2;
    % C = confusionmat((subtempH==i),(sub_y_height==2),'Order',[0 1]);
    % weighted_metric_height(i,2) = C(2,2) ./ (C(2,2)+C(2,1));
    % weighted_metric_height(i,3) = C(2,2) ./ (C(2,2)+C(1,2));
    % weighted_metric_height(i,4) = (C(2,2)+C(1,1)) ./ (C(2,2)+C(2,1)+C(1,1)+C(1,2));
    % weighted_metric_height(i,5) = 2.*C(2,2) ./ (2.*C(2,2)+C(1,2)+C(2,1));
    % i = 3;
    % C = confusionmat((subtempH==i),(sub_y_height==3|sub_y_height==4),'Order',[0 1]);
    % weighted_metric_height(i,2) = C(2,2) ./ (C(2,2)+C(2,1));
    % weighted_metric_height(i,3) = C(2,2) ./ (C(2,2)+C(1,2));
    % weighted_metric_height(i,4) = (C(2,2)+C(1,1)) ./ (C(2,2)+C(2,1)+C(1,1)+C(1,2));
    % weighted_metric_height(i,5) = 2.*C(2,2) ./ (2.*C(2,2)+C(1,2)+C(2,1));
    % i = 4;
    % C = confusionmat((subtempH==i),(sub_y_height==4|sub_y_height==5),'Order',[0 1]);
    % weighted_metric_height(i,2) = C(2,2) ./ (C(2,2)+C(2,1));
    % weighted_metric_height(i,3) = C(2,2) ./ (C(2,2)+C(1,2));
    % weighted_metric_height(i,4) = (C(2,2)+C(1,1)) ./ (C(2,2)+C(2,1)+C(1,1)+C(1,2));
    % weighted_metric_height(i,5) = 2.*C(2,2) ./ (2.*C(2,2)+C(1,2)+C(2,1));
    % i = 5;
    % C = confusionmat((subtempH==i),(sub_y_height==4|sub_y_height==5),'Order',[0 1]);
    % weighted_metric_height(i,2) = C(2,2) ./ (C(2,2)+C(2,1));
    % weighted_metric_height(i,3) = C(2,2) ./ (C(2,2)+C(1,2));
    % weighted_metric_height(i,4) = (C(2,2)+C(1,1)) ./ (C(2,2)+C(2,1)+C(1,1)+C(1,2));
    % weighted_metric_height(i,5) = 2.*C(2,2) ./ (2.*C(2,2)+C(1,2)+C(2,1));
    % i = 6;
    % C = confusionmat((subtempH==i),(sub_y_height==5),'Order',[0 1]);
    % weighted_metric_height(i,2) = C(2,2) ./ (C(2,2)+C(2,1));
    % weighted_metric_height(i,3) = C(2,2) ./ (C(2,2)+C(1,2));
    % weighted_metric_height(i,4) = (C(2,2)+C(1,1)) ./ (C(2,2)+C(2,1)+C(1,1)+C(1,2));
    % weighted_metric_height(i,5) = 2.*C(2,2) ./ (2.*C(2,2)+C(1,2)+C(2,1));
    % i = 7;
    % C = confusionmat((subtempH==i),(sub_y_height==6),'Order',[0 1]);
    % weighted_metric_height(i,2) = C(2,2) ./ (C(2,2)+C(2,1));
    % weighted_metric_height(i,3) = C(2,2) ./ (C(2,2)+C(1,2));
    % weighted_metric_height(i,4) = (C(2,2)+C(1,1)) ./ (C(2,2)+C(2,1)+C(1,1)+C(1,2));
    % weighted_metric_height(i,5) = 2.*C(2,2) ./ (2.*C(2,2)+C(1,2)+C(2,1));
    % weighted_metric_height(isnan(weighted_metric_height)) = 0;
    % weighted_metric_height(8,1) = sum(weighted_metric_height(1:7,1));
    % xPreH = sum((weighted_metric_height(1:7,1) ./ weighted_metric_height(8,1)) .* ... 
    %                             weighted_metric_height(1:7,2));
    % xRecH = sum((weighted_metric_height(1:7,1) ./ weighted_metric_height(8,1)) .* ... 
    %                             weighted_metric_height(1:7,3));
    % xAccuH = sum((weighted_metric_height(1:7,1) ./ weighted_metric_height(8,1)) .* ... 
    %                             weighted_metric_height(1:7,4));
    % xF1H = sum((weighted_metric_height(1:7,1) ./ weighted_metric_height(8,1)) .* ... 
    %                             weighted_metric_height(1:7,5));


    %% Metrics Wall
    sub_y_wall = true_centroidW_index(labelsLocalW); 
    xTPpropW = (1./size(indtemp,1)) .* sum(...
       (subtemp==1) .* (sub_y_wall==1|sub_y_wall==2|sub_y_wall==5|sub_y_wall==6|sub_y_wall==7|sub_y_wall==8) + ...
       (subtemp==2) .* (sub_y_wall==1|sub_y_wall==2|sub_y_wall==3|sub_y_wall==4|sub_y_wall==6) + ...
       (subtemp==3) .* (sub_y_wall==2|sub_y_wall==3|sub_y_wall==4|sub_y_wall==6) + ...
       (subtemp==4) .* (sub_y_wall==3|sub_y_wall==4|sub_y_wall==6) + ...
       (subtemp==5) .* (sub_y_wall==3|sub_y_wall==4) + ...
       (subtemp==6) .* (sub_y_wall==4) + ...
       (subtemp==7) .* (sub_y_wall==3|sub_y_wall==4) ...
       );
    % weighted_metric_wall = zeros(7,5);
    % for i = 1:7
    %     weighted_metric_wall(i,1) = sum(subtemp==i);
    % end
    % i = 1;
    % C = confusionmat((subtemp==i),(sub_y_wall==1|sub_y_wall==2|sub_y_wall==5|sub_y_wall==6|sub_y_wall==7|sub_y_wall==8),'Order',[0 1]);
    % weighted_metric_wall(i,2) = C(2,2) ./ (C(2,2)+C(2,1));
    % weighted_metric_wall(i,3) = C(2,2) ./ (C(2,2)+C(1,2));
    % weighted_metric_wall(i,4) = (C(2,2)+C(1,1)) ./ (C(2,2)+C(2,1)+C(1,1)+C(1,2));
    % weighted_metric_wall(i,5) = 2.*C(2,2) ./ (2.*C(2,2)+C(1,2)+C(2,1));
    % i = 2;
    % C = confusionmat((subtemp==i),(sub_y_wall==1|sub_y_wall==2|sub_y_wall==3|sub_y_wall==4|sub_y_wall==6),'Order',[0 1]);
    % weighted_metric_wall(i,2) = C(2,2) ./ (C(2,2)+C(2,1));
    % weighted_metric_wall(i,3) = C(2,2) ./ (C(2,2)+C(1,2));
    % weighted_metric_wall(i,4) = (C(2,2)+C(1,1)) ./ (C(2,2)+C(2,1)+C(1,1)+C(1,2));
    % weighted_metric_wall(i,5) = 2.*C(2,2) ./ (2.*C(2,2)+C(1,2)+C(2,1));
    % i = 3;
    % C = confusionmat((subtemp==i),(sub_y_wall==2|sub_y_wall==3|sub_y_wall==4|sub_y_wall==6),'Order',[0 1]);
    % weighted_metric_wall(i,2) = C(2,2) ./ (C(2,2)+C(2,1));
    % weighted_metric_wall(i,3) = C(2,2) ./ (C(2,2)+C(1,2));
    % weighted_metric_wall(i,4) = (C(2,2)+C(1,1)) ./ (C(2,2)+C(2,1)+C(1,1)+C(1,2));
    % weighted_metric_wall(i,5) = 2.*C(2,2) ./ (2.*C(2,2)+C(1,2)+C(2,1));
    % i = 4;
    % C = confusionmat((subtemp==i),(sub_y_wall==3|sub_y_wall==4|sub_y_wall==6) ,'Order',[0 1]);
    % weighted_metric_wall(i,2) = C(2,2) ./ (C(2,2)+C(2,1));
    % weighted_metric_wall(i,3) = C(2,2) ./ (C(2,2)+C(1,2));
    % weighted_metric_wall(i,4) = (C(2,2)+C(1,1)) ./ (C(2,2)+C(2,1)+C(1,1)+C(1,2));
    % weighted_metric_wall(i,5) = 2.*C(2,2) ./ (2.*C(2,2)+C(1,2)+C(2,1));
    % i = 5;
    % C = confusionmat((subtemp==i),(sub_y_wall==3|sub_y_wall==4),'Order',[0 1]);
    % weighted_metric_wall(i,2) = C(2,2) ./ (C(2,2)+C(2,1));
    % weighted_metric_wall(i,3) = C(2,2) ./ (C(2,2)+C(1,2));
    % weighted_metric_wall(i,4) = (C(2,2)+C(1,1)) ./ (C(2,2)+C(2,1)+C(1,1)+C(1,2));
    % weighted_metric_wall(i,5) = 2.*C(2,2) ./ (2.*C(2,2)+C(1,2)+C(2,1));
    % i = 6;
    % C = confusionmat((subtemp==i),(sub_y_wall==4),'Order',[0 1]);
    % weighted_metric_wall(i,2) = C(2,2) ./ (C(2,2)+C(2,1));
    % weighted_metric_wall(i,3) = C(2,2) ./ (C(2,2)+C(1,2));
    % weighted_metric_wall(i,4) = (C(2,2)+C(1,1)) ./ (C(2,2)+C(2,1)+C(1,1)+C(1,2));
    % weighted_metric_wall(i,5) = 2.*C(2,2) ./ (2.*C(2,2)+C(1,2)+C(2,1));
    % i = 7;
    % C = confusionmat((subtemp==i),(sub_y_wall==3|sub_y_wall==4),'Order',[0 1]);
    % weighted_metric_wall(i,2) = C(2,2) ./ (C(2,2)+C(2,1));
    % weighted_metric_wall(i,3) = C(2,2) ./ (C(2,2)+C(1,2));
    % weighted_metric_wall(i,4) = (C(2,2)+C(1,1)) ./ (C(2,2)+C(2,1)+C(1,1)+C(1,2));
    % weighted_metric_wall(i,5) = 2.*C(2,2) ./ (2.*C(2,2)+C(1,2)+C(2,1));
    % weighted_metric_wall(isnan(weighted_metric_wall)) = 0;
    % weighted_metric_wall(8,1) = sum(weighted_metric_wall(1:7,1));
    % xPreW = sum((weighted_metric_wall(1:7,1) ./ weighted_metric_wall(8,1)) .* ... 
    %                             weighted_metric_wall(1:7,2));
    % xRecW = sum((weighted_metric_wall(1:7,1) ./ weighted_metric_wall(8,1)) .* ... 
    %                             weighted_metric_wall(1:7,3));
    % xAccuW = sum((weighted_metric_wall(1:7,1) ./ weighted_metric_wall(8,1)) .* ... 
    %                             weighted_metric_wall(1:7,4));
    % xF1W = sum((weighted_metric_wall(1:7,1) ./ weighted_metric_wall(8,1)) .* ... 
    %                             weighted_metric_wall(1:7,5));


    %% Loss and Gradient Update

    loss = (loss2./loss2_prev(iter) + loss3./loss3_prev(iter)).*max(nelem)./nind;
    % loss = (loss2./loss2_prev(iter) + loss3./loss3_prev(iter) + loss4./loss4_prev(iter)).*max(nelem)./nind;
    
    [gradientsE,gradientsD] = ...
        dlgradient(dlarray(loss,'BC'),netE.Learnables,netD.Learnables);
    % dbstop in modelLoss.m at 483 if (anynan(extractdata(netE.Learnables.Value{1,1})) | anynan(extractdata(gradientsE.Value{1,1})))
    if anynan(extractdata(gradientsE.Value{1,1})) || anynan(extractdata(gradientsD.Value{1,1}))
        gradientsE = gradientsE_prev;
        gradientsD = gradientsD_prev;
    end

end