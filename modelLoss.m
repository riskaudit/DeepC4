function [loss2,loss3,xTPprop,xTPpropH,xTPpropW, ...
    gradientsE,gradientsD,labelsLocal_prev,labelsLocalH_prev,labelsLocalW_prev] = ...
    modelLoss(netE,netD,X,...
    tau,tauH,tauW,btype_label,label_height,ind,...
    loss2_prev,loss3_prev,nelem,nind,iter,gradientsE_prev,gradientsD_prev, ...
    train_boolean,epoch,labelsLocal_prev,labelsLocalH_prev,labelsLocalW_prev)

    %% Input supervision
    sub_label_roofwall  = sparse(double(btype_label(ind)));
    sub_label_height = sparse(double(label_height(ind)));
    sub_label_height_cat = ...
       ((sub_label_height>0)&(sub_label_height<6))              .* 1 + ...
       ((sub_label_height>=6)&(sub_label_height<9))             .* 2 + ...
       ((sub_label_height>=9)&(sub_label_height<12))            .* 3 + ...
       ((sub_label_height>=12)&(sub_label_height<21))           .* 4 + ...  % 5 -> 4
       ((sub_label_height>=21)&(sub_label_height<24))           .* 5 + ...  % 6 -> 5
       ((sub_label_height>=24))                                 .* 6;       % 7 - > 6


    indtemp = find(sub_label_roofwall>0 & sub_label_roofwall<=7 & sub_label_height>0);
 
    subtemp = full(sub_label_roofwall(indtemp));
    subtempH = full(sub_label_height_cat(indtemp));
    unique_subtemp = unique(subtemp);
    unique_subtempH = unique(subtempH);
    nsubtemp = histcounts(subtemp,1:8)';
    nsubtempH = histcounts(subtempH,1:7)';

    %% Forward through encoder.
    % [Z,mu,logSigmaSq] = forward(netE,X);
    subZ = forward(netE,X(:,indtemp)+1e-6);

    %% Forward through decoder.
    subY = forward(netD,subZ);

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
                col = [1 2];
                [common_index,~]=intersect(col,unique(subtempH)');
                constraints_array_H(i,2) = sum(nsubtempH(common_index));
            end
        elseif i == 3
            if tauH(i) ~= 0
                col = [2 3];
                [common_index,~]=intersect(col,unique(subtempH)');
                constraints_array_H(i,2) = sum(nsubtempH(common_index));
            end
        elseif i == 4
            if tauH(i) ~= 0
                col = [2 3 4];
                [common_index,~]=intersect(col,unique(subtempH)');
                constraints_array_H(i,2) = sum(nsubtempH(common_index));
            end
        elseif i == 5
            if tauH(i) ~= 0
                col = [3 4 5];
                [common_index,~]=intersect(col,unique(subtempH)');
                constraints_array_H(i,2) = sum(nsubtempH(common_index));
            end
        elseif i == 6
            if tauH(i) ~= 0
                col = [6 7];
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
                col = [1 2 3 7];
                [common_index,~]=intersect(col,unique(subtemp)');
                constraints_array_W(i,2) = sum(nsubtemp(common_index));
            end
        elseif i == 3 % "Cement blocks"
            if tauW(i) ~= 0
                col = [1 2 3 4 5 7];
                [common_index,~]=intersect(col,unique(subtemp)');
                constraints_array_W(i,2) = sum(nsubtemp(common_index));
            end
        elseif i == 4 % "Concrete"
            if tauW(i) ~= 0
                col = [1 2 3 4 5 6 7];
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
                col = [1 2 3 4 5 7];
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
                col = [1 3];
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

    % MinCostFlow - 98.117 at epoch 14, does not converge for long
    % epochs, results in NAN at epoch around >25, when max(ntotal)./nind;
     % - 98.416 at epoch 21, does not converge for long
    % epochs, results in NAN at epoch around >35, when nind./min(ntotal)
    disp('roof')
    [labelsLocal,centroids] = constrainedKMeans_DEC(subZ(1,:), ...
        sum(constraints_array(:,3)~=0), ...
        constraints_array(constraints_array(:,3)>0,4), 50);
    labelsLocal_prev = labelsLocal;
    disp('height')
    [labelsLocalH,centroidsH] = constrainedKMeans_DEC(subZ(2,:), ...
        sum(constraints_array_H(:,3)~=0), ...
        constraints_array_H(constraints_array_H(:,3)>0,4), 50);
    labelsLocalH_prev = labelsLocalH;
    disp('wall')
    [labelsLocalW,centroidsW] = constrainedKMeans_DEC(subZ(3,:), ...
        sum(constraints_array_W(:,3)~=0), ...
        constraints_array_W(constraints_array_W(:,3)>0,4), 50);
    labelsLocalW_prev = labelsLocalW;

    

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
    % labelsLocal = spectralcluster(extractdata(subZ(1,:))',sum(constraints_array(:,3)~=0),...
    %     "LaplacianNormalization","symmetric");
    % [D,n] = size(extractdata(subZ(1,:)));
    % labelsNewOneHot = reshape(onehotencode(labelsLocal,2,"ClassNames",1:sum(constraints_array(:,3)~=0)),[n sum(constraints_array(:,3)~=0) 1]);
    % Z_onehotencoded_new = extractdata(subZ(1,:)).*repmat(reshape(labelsNewOneHot,[1 n sum(constraints_array(:,3)~=0)]),[D 1 1]);
    % centroids = mean(Z_onehotencoded_new,2);
    % 
    % labelsLocalH = spectralcluster(extractdata(subZ(2,:))',sum(constraints_array_H(:,3)~=0),...
    %     "LaplacianNormalization","symmetric");
    % [D,n] = size(extractdata(subZ(2,:)));
    % labelsNewOneHot = reshape(onehotencode(labelsLocalH,2,"ClassNames",1:sum(constraints_array_H(:,3)~=0)),[n sum(constraints_array_H(:,3)~=0) 1]);
    % Z_onehotencoded_new = extractdata(subZ(2,:)).*repmat(reshape(labelsNewOneHot,[1 n sum(constraints_array_H(:,3)~=0)]),[D 1 1]);
    % centroidsH = mean(Z_onehotencoded_new,2);
    % 
    % labelsLocalW = spectralcluster(extractdata(subZ(3,:))',sum(constraints_array_W(:,3)~=0),...
    %     "LaplacianNormalization","symmetric");
    % [D,n] = size(extractdata(subZ(3,:)));
    % labelsNewOneHot = reshape(onehotencode(labelsLocalW,2,"ClassNames",1:sum(constraints_array_W(:,3)~=0)),[n sum(constraints_array_W(:,3)~=0) 1]);
    % Z_onehotencoded_new = extractdata(subZ(3,:)).*repmat(reshape(labelsNewOneHot,[1 n sum(constraints_array_W(:,3)~=0)]),[D 1 1]);
    % centroidsW = mean(Z_onehotencoded_new,2);

    % Traditonal KMeans
    % [labelsLocal,centroids] = kmeans(extractdata(subZ(1,:))', ...
    %     sum(constraints_array(:,3)~=0),'MaxIter',50);
    % centroids = reshape(centroids',[1 1 sum(constraints_array(:,3)~=0)]);
    % [labelsLocalH,centroidsH] = kmeans(extractdata(subZ(2,:))', ...
    %     sum(constraints_array_H(:,3)~=0),'MaxIter',50);
    % centroidsH = reshape(centroidsH',[1 1 sum(constraints_array_H(:,3)~=0)]);
    % [labelsLocalW,centroidsW] = kmeans(extractdata(subZ(3,:))', ...
    %     sum(constraints_array_W(:,3)~=0),'MaxIter',50);
    % centroidsW = reshape(centroidsW,[1 1 sum(constraints_array_W(:,3)~=0)]);



    %% Calculate PredictionLoss Roof
    identified_classes_index = find(constraints_array(:,3)>0);
    distance_error_array = (repmat(centroids,[1,size(subZ,2),1])-...
                            repmat(subZ(1,:),[1,1,sum(constraints_array(:,3)~=0)])).^2;
    distance_error_array = sqrt(sum(distance_error_array,1));
    distance_error_array = exp(distance_error_array)./sum(exp(distance_error_array),3);
    loss3_basedOnDistanceError = 0;
    for i = 1:length(nsubtemp)
        if      i == 1 && any(unique_subtemp==i)
                if nsubtemp(i) ~= 0
                    col = [1 4];
                    [common_index,~]=intersect(col,identified_classes_index);

                    not_common_index2 = ~ismember(identified_classes_index,common_index).*identified_classes_index;
                    not_common_index2(not_common_index2==0) = [];

                    if ~isempty(common_index)
                        loss3_basedOnDistanceError = loss3_basedOnDistanceError + ...
                        sum(...
                            sum(1 - distance_error_array(:,:,not_common_index2),3) + ...
                            min(distance_error_array(:,:,common_index),[],3))./size(subZ,2);
                        % loss3_basedOnDistanceError = loss3_basedOnDistanceError + sum(nsubtemp)./(nsubtemp(i).*sum(nsubtemp~=0)).*  ...   
                        %     sum( (subtemp==i)'.*mean(distance_error_array(:,:,common_index),3) ) ./ nsubtemp(i);
                    end
                end
        elseif  i == 2 && any(unique_subtemp==i)
                if nsubtemp(i) ~= 0 
                    col = [1];
                    [common_index,~]=intersect(col,identified_classes_index);

                    not_common_index2 = ~ismember(identified_classes_index,common_index).*identified_classes_index;
                    not_common_index2(not_common_index2==0) = [];
                    
                    if ~isempty(common_index)
                        loss3_basedOnDistanceError = loss3_basedOnDistanceError + ...
                        sum(...
                            sum(1 - distance_error_array(:,:,not_common_index2),3) + ...
                            min(distance_error_array(:,:,common_index),[],3))./size(subZ,2);
                        % loss3_basedOnDistanceError = loss3_basedOnDistanceError + sum(nsubtemp)./(nsubtemp(i).*sum(nsubtemp~=0)).*  ...  
                        %     sum( (subtemp==i)'.*mean(distance_error_array(:,:,common_index),3) ) ./ nsubtemp(i);
                    end
                end
        elseif  i == 3 && any(unique_subtemp==i)
                if nsubtemp(i) ~= 0 
                    col = [1 2];
                    [common_index,~]=intersect(col,identified_classes_index);

                    not_common_index2 = ~ismember(identified_classes_index,common_index).*identified_classes_index;
                    not_common_index2(not_common_index2==0) = [];

                    if ~isempty(common_index)
                        loss3_basedOnDistanceError = loss3_basedOnDistanceError + ...
                        sum(...
                            sum(1 - distance_error_array(:,:,not_common_index2),3) + ...
                            min(distance_error_array(:,:,common_index),[],3))./size(subZ,2);
                        % loss3_basedOnDistanceError = loss3_basedOnDistanceError + sum(nsubtemp)./(nsubtemp(i).*sum(nsubtemp~=0)).*  ...  
                        %     sum( (subtemp==i)'.*mean(distance_error_array(:,:,common_index),3) ) ./ nsubtemp(i);
                    end
                end
        elseif  i == 4 && any(unique_subtemp==i)
                if nsubtemp(i) ~= 0 
                    col = [1 2];
                    [common_index,~]=intersect(col,identified_classes_index);

                    not_common_index2 = ~ismember(identified_classes_index,common_index).*identified_classes_index;
                    not_common_index2(not_common_index2==0) = [];

                    if ~isempty(common_index)
                        loss3_basedOnDistanceError = loss3_basedOnDistanceError + ...
                        sum(...
                            sum(1 - distance_error_array(:,:,not_common_index2),3) + ...
                            min(distance_error_array(:,:,common_index),[],3))./size(subZ,2);
                        % loss3_basedOnDistanceError = loss3_basedOnDistanceError + sum(nsubtemp)./(nsubtemp(i).*sum(nsubtemp~=0)).*  ...  
                        %     sum( (subtemp==i)'.*mean(distance_error_array(:,:,common_index),3) ) ./ nsubtemp(i);
                    end
                end
        elseif  i == 5
                if nsubtemp(i) ~= 0 
                    col = [1 2];
                    [common_index,~]=intersect(col,identified_classes_index);

                    not_common_index2 = ~ismember(identified_classes_index,common_index).*identified_classes_index;
                    not_common_index2(not_common_index2==0) = [];

                    if ~isempty(common_index)
                        loss3_basedOnDistanceError = loss3_basedOnDistanceError + ...
                        sum(...
                            sum(1 - distance_error_array(:,:,not_common_index2),3) + ...
                            min(distance_error_array(:,:,common_index),[],3))./size(subZ,2);
                        % loss3_basedOnDistanceError = loss3_basedOnDistanceError + sum(nsubtemp)./(nsubtemp(i).*sum(nsubtemp~=0)).*  ...  
                        %     sum( (subtemp==i)'.*mean(distance_error_array(:,:,common_index),3) ) ./ nsubtemp(i);
                    end
                end
        elseif  i == 6
                if nsubtemp(i) ~= 0 
                    col = [1 3];
                    [common_index,~]=intersect(col,identified_classes_index);

                    not_common_index2 = ~ismember(identified_classes_index,common_index).*identified_classes_index;
                    not_common_index2(not_common_index2==0) = [];

                    if ~isempty(common_index)

                        loss3_basedOnDistanceError = loss3_basedOnDistanceError + ...
                        sum(...
                            sum(1 - distance_error_array(:,:,not_common_index2),3) + ...
                            min(distance_error_array(:,:,common_index),[],3))./size(subZ,2);

                        % loss3_basedOnDistanceError = loss3_basedOnDistanceError + sum(nsubtemp)./(nsubtemp(i).*sum(nsubtemp~=0)).*  ...  
                        %     sum( (subtemp==i)'.*mean(distance_error_array(:,:,common_index),3) ) ./ nsubtemp(i);
                    end
                end
        elseif  i == 7
                if nsubtemp(i) ~= 0 
                    col = [1];
                    [common_index,~]=intersect(col,identified_classes_index);

                    not_common_index2 = ~ismember(identified_classes_index,common_index).*identified_classes_index;
                    not_common_index2(not_common_index2==0) = [];

                    if ~isempty(common_index)

                        loss3_basedOnDistanceError = loss3_basedOnDistanceError + ...
                        sum(...
                            sum(1 - distance_error_array(:,:,not_common_index2),3) + ...
                            min(distance_error_array(:,:,common_index),[],3))./size(subZ,2);

                        % loss3_basedOnDistanceError = loss3_basedOnDistanceError + sum(nsubtemp)./(nsubtemp(i).*sum(nsubtemp~=0)).*  ...  
                        %     sum( (subtemp==i)'.*mean(distance_error_array(:,:,common_index),3) ) ./ nsubtemp(i);
                    end
                end
        end
    end
    sum_weights = sum(nsubtemp)./(nsubtemp.*sum(nsubtemp~=0));
    sum_weights(isinf(sum_weights)) = 0;
    % loss3_basedOnDistanceError = loss3_basedOnDistanceError ./ sum(sum_weights);

    %% Calculate PredictionLoss Height
    true_centroidH_index = find(constraints_array_H(:,3)>0);
    centroidH_index = (1:sum(constraints_array_H(:,3)~=0))';
    distance_error_arrayH = (repmat(centroidsH,[1,size(subZ,2),1])-...
                            repmat(subZ(2,:),[1,1,sum(constraints_array_H(:,3)~=0)])).^2;
    distance_error_arrayH = sqrt(sum(distance_error_arrayH,1));
    distance_error_arrayH = exp(distance_error_arrayH)./sum(exp(distance_error_arrayH),3);
    loss3_basedOnDistanceErrorH = 0;
    for i = 1:length(nsubtempH) 
        if      i == 1 && any(unique_subtempH==i) % (0,3]
                col = [1 2]; 
                [common_index,~]=intersect(col,true_centroidH_index);
                [~,ia,~] = intersect(true_centroidH_index,common_index);
                common_index2 = centroidH_index(ia);

                not_common_index2 = ~ismember(centroidH_index,common_index2).*centroidH_index;
                not_common_index2(not_common_index2==0) = [];

                if ~isempty(common_index2)
                    loss3_basedOnDistanceErrorH = loss3_basedOnDistanceErrorH + ...
                        sum(...
                            sum(1 - distance_error_arrayH(:,:,not_common_index2),3) + ...
                            min(distance_error_arrayH(:,:,common_index2),[],3))./size(subZ,2);

                    % loss3_basedOnDistanceErrorH = loss3_basedOnDistanceErrorH + sum(nsubtempH)./(nsubtempH(i).*sum(nsubtempH~=0)).*  ...
                    %     sum( (subtempH==i)'.*mean(distance_error_arrayH(:,:,common_index2),3) ) ./ nsubtempH(i);
                end
        elseif  i == 2 && any(unique_subtempH==i) % (3,5.5]
                col = [2 3 4]; 
                [common_index,~]=intersect(col,true_centroidH_index);
                [~,ia,~] = intersect(true_centroidH_index,common_index);
                common_index2 = centroidH_index(ia);

                not_common_index2 = ~ismember(centroidH_index,common_index2).*centroidH_index;
                not_common_index2(not_common_index2==0) = [];

                if ~isempty(common_index2)
                    loss3_basedOnDistanceErrorH = loss3_basedOnDistanceErrorH + ...
                        sum(...
                            sum(1 - distance_error_arrayH(:,:,not_common_index2),3) + ...
                            min(distance_error_arrayH(:,:,common_index2),[],3))./size(subZ,2);
                    % loss3_basedOnDistanceErrorH = loss3_basedOnDistanceErrorH + sum(nsubtempH)./(nsubtempH(i).*sum(nsubtempH~=0)).*  ...
                    %     sum( (subtempH==i)'.*mean(distance_error_arrayH(:,:,common_index2),3) ) ./ nsubtempH(i);
                end
        elseif  i == 3 && any(unique_subtempH==i) % (5.5,8] 
                col = [3 4 5]; 
                [common_index,~]=intersect(col,true_centroidH_index);
                [~,ia,~] = intersect(true_centroidH_index,common_index);
                common_index2 = centroidH_index(ia);

                not_common_index2 = ~ismember(centroidH_index,common_index2).*centroidH_index;
                not_common_index2(not_common_index2==0) = [];

                if ~isempty(common_index2)
                    loss3_basedOnDistanceErrorH = loss3_basedOnDistanceErrorH + ...
                        sum(...
                            sum(1 - distance_error_arrayH(:,:,not_common_index2),3) + ...
                            min(distance_error_arrayH(:,:,common_index2),[],3))./size(subZ,2);
                    % loss3_basedOnDistanceErrorH = loss3_basedOnDistanceErrorH + sum(nsubtempH)./(nsubtempH(i).*sum(nsubtempH~=0)).*  ...
                    %     sum( (subtempH==i)'.*mean(distance_error_arrayH(:,:,common_index2),3) ) ./ nsubtempH(i);
                end
        elseif  i == 4 && any(unique_subtempH==i) % (8,10]
                col = [4 5]; 
                [common_index,~]=intersect(col,true_centroidH_index);
                [~,ia,~] = intersect(true_centroidH_index,common_index);
                common_index2 = centroidH_index(ia);

                not_common_index2 = ~ismember(centroidH_index,common_index2).*centroidH_index;
                not_common_index2(not_common_index2==0) = [];

                if ~isempty(common_index2)
                    loss3_basedOnDistanceErrorH = loss3_basedOnDistanceErrorH + ...
                        sum(...
                            sum(1 - distance_error_arrayH(:,:,not_common_index2),3) + ...
                            min(distance_error_arrayH(:,:,common_index2),[],3))./size(subZ,2);
                    % loss3_basedOnDistanceErrorH = loss3_basedOnDistanceErrorH + ...
                    %     sum(nsubtempH)./(nsubtempH(i).*sum(nsubtempH~=0)).*  ...
                    %     sum( (subtempH==i)'.*mean(distance_error_arrayH(:,:,common_index2),3) ) ./ nsubtempH(i);
                end
        elseif  i == 5 && any(unique_subtempH==i) % (10,14]
                col = [5 6]; 
                [common_index,~]=intersect(col,true_centroidH_index);
                [~,ia,~] = intersect(true_centroidH_index,common_index);
                common_index2 = centroidH_index(ia);

                not_common_index2 = ~ismember(centroidH_index,common_index2).*centroidH_index;
                not_common_index2(not_common_index2==0) = [];

                if ~isempty(common_index2)
                    loss3_basedOnDistanceErrorH = loss3_basedOnDistanceErrorH + ...
                        sum(...
                            sum(1 - distance_error_arrayH(:,:,not_common_index2),3) + ...
                            min(distance_error_arrayH(:,:,common_index2),[],3))./size(subZ,2);
                    % loss3_basedOnDistanceErrorH = loss3_basedOnDistanceErrorH + sum(nsubtempH)./(nsubtempH(i).*sum(nsubtempH~=0)).*  ...
                    %     sum( (subtempH==i)'.*mean(distance_error_arrayH(:,:,common_index2),3) ) ./ nsubtempH(i);
                end
        elseif  i == 6 && any(unique_subtempH==i) % (14,16]
                col = [6]; 
                [common_index,~]=intersect(col,true_centroidH_index);
                [~,ia,~] = intersect(true_centroidH_index,common_index);
                common_index2 = centroidH_index(ia);

                not_common_index2 = ~ismember(centroidH_index,common_index2).*centroidH_index;
                not_common_index2(not_common_index2==0) = [];

                if ~isempty(common_index2)
                    loss3_basedOnDistanceErrorH = loss3_basedOnDistanceErrorH + ...
                        sum(...
                            sum(1 - distance_error_arrayH(:,:,not_common_index2),3) + ...
                            min(distance_error_arrayH(:,:,common_index2),[],3))./size(subZ,2);
                    % loss3_basedOnDistanceErrorH = loss3_basedOnDistanceErrorH + sum(nsubtempH)./(nsubtempH(i).*sum(nsubtempH~=0)).*  ...
                    %     sum( (subtempH==i)'.*mean(distance_error_arrayH(:,:,common_index2),3) ) ./ nsubtempH(i);
                end
        end
    end
    sum_weightsH = sum(nsubtempH)./(nsubtempH.*sum(nsubtempH~=0));
    sum_weightsH(isinf(sum_weightsH)) = 0;
    % % loss3_basedOnDistanceErrorH = loss3_basedOnDistanceErrorH ./ sum(sum_weightsH);

    %% Calculate PredictionLoss Wall
    true_centroidW_index = find(constraints_array_W(:,3)>0);
    centroidW_index = (1:sum(constraints_array_W(:,3)~=0))';

    distance_error_arrayW = (repmat(centroidsW,[1,size(subZ,2),1])-...
                            repmat(subZ(3,:),[1,1,sum(constraints_array_W(:,3)~=0)])).^2;
    distance_error_arrayW = sqrt(sum(distance_error_arrayW,1));

    distance_error_arrayW = exp(distance_error_arrayW)./sum(exp(distance_error_arrayW),3);

    loss3_basedOnDistanceErrorW = 0;
    for i = 1:length(nsubtemp) %nsubtemp contains 7 bachofer categories, 
        if      i == 1 && any(unique_subtemp==i) % 1: Rudimentary, basic or unplanned buildings
                col = [1 2 3 4 5 6 7 8];
                % "All non durable wall materials"
                % "Burnt bricks"
                % "Stone"
                % "Sun dried bricks"
                % "Timber"
                % "Wood with mud"
                [common_index,~]=intersect(col,true_centroidW_index);
                [~,ia,~] = intersect(true_centroidW_index,common_index);
                common_index2 = centroidW_index(ia);

                not_common_index2 = ~ismember(centroidW_index,common_index2).*centroidW_index;
                not_common_index2(not_common_index2==0) = [];

                if ~isempty(common_index2)
                    loss3_basedOnDistanceErrorW = loss3_basedOnDistanceErrorW + ...
                        sum(...
                            sum(1 - distance_error_arrayW(:,:,not_common_index2),3) + ...
                            min(distance_error_arrayW(:,:,common_index2),[],3))./size(subZ,2);
                    % loss3_basedOnDistanceErrorW = loss3_basedOnDistanceErrorW + sum(nsubtemp)./(nsubtemp(i).*sum(nsubtemp~=0)).*  ...
                    %     sum( (subtemp==i)'.*mean(distance_error_arrayW(:,:,common_index2),3) ) ./ nsubtemp(i);
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

                not_common_index2 = ~ismember(centroidW_index,common_index2).*centroidW_index;
                not_common_index2(not_common_index2==0) = [];

                if ~isempty(common_index2)
                    loss3_basedOnDistanceErrorW = loss3_basedOnDistanceErrorW + ...
                        sum(...
                            sum(1 - distance_error_arrayW(:,:,not_common_index2),3) + ...
                            min(distance_error_arrayW(:,:,common_index2),[],3))./size(subZ,2);
                    % loss3_basedOnDistanceErrorW = loss3_basedOnDistanceErrorW + sum(nsubtemp)./(nsubtemp(i).*sum(nsubtemp~=0)).*  ...
                    %     sum( (subtemp==i)'.*mean(distance_error_arrayW(:,:,common_index2),3) ) ./ nsubtemp(i);
                end
        elseif  i == 3 && any(unique_subtemp==i) % 3: Bungalow-type buildings
                col = [2 3 4 6 8];
                % "Burnt bricks"
                % "Cement blocks"
                % "Concrete"
                % "Sun dried bricks"
                [common_index,~]=intersect(col,true_centroidW_index);
                [~,ia,~] = intersect(true_centroidW_index,common_index);
                common_index2 = centroidW_index(ia);

                not_common_index2 = ~ismember(centroidW_index,common_index2).*centroidW_index;
                not_common_index2(not_common_index2==0) = [];

                if ~isempty(common_index2)
                    loss3_basedOnDistanceErrorW = loss3_basedOnDistanceErrorW + ...
                        sum(...
                            sum(1 - distance_error_arrayW(:,:,not_common_index2),3) + ...
                            min(distance_error_arrayW(:,:,common_index2),[],3))./size(subZ,2);
                    % loss3_basedOnDistanceErrorW = loss3_basedOnDistanceErrorW + sum(nsubtemp)./(nsubtemp(i).*sum(nsubtemp~=0)).*  ...
                    %     sum( (subtemp==i)'.*mean(distance_error_arrayW(:,:,common_index2),3) ) ./ nsubtemp(i);
                end
        elseif  i == 4 && any(unique_subtemp==i) % 4: Villa-type buildings
                col = [3 4 6];
                % "Cement blocks"
                % "Concrete"
                % "Sun dried bricks"
                [common_index,~]=intersect(col,true_centroidW_index);
                [~,ia,~] = intersect(true_centroidW_index,common_index);
                common_index2 = centroidW_index(ia);

                not_common_index2 = ~ismember(centroidW_index,common_index2).*centroidW_index;
                not_common_index2(not_common_index2==0) = [];

                if ~isempty(common_index2)
                    loss3_basedOnDistanceErrorW = loss3_basedOnDistanceErrorW + ...
                        sum(...
                            sum(1 - distance_error_arrayW(:,:,not_common_index2),3) + ...
                            min(distance_error_arrayW(:,:,common_index2),[],3))./size(subZ,2);
                    % loss3_basedOnDistanceErrorW = loss3_basedOnDistanceErrorW + sum(nsubtemp)./(nsubtemp(i).*sum(nsubtemp~=0)).*  ...
                    %     sum( (subtemp==i)'.*mean(distance_error_arrayW(:,:,common_index2),3) ) ./ nsubtemp(i);
                end
        elseif  i == 5 && any(unique_subtemp==i) % 5: Low to mid-rise multi-unit buildings
                col = [3 4];
                % "Cement blocks"
                % "Concrete"
                [common_index,~]=intersect(col,true_centroidW_index);
                [~,ia,~] = intersect(true_centroidW_index,common_index);
                common_index2 = centroidW_index(ia);

                not_common_index2 = ~ismember(centroidW_index,common_index2).*centroidW_index;
                not_common_index2(not_common_index2==0) = [];

                if ~isempty(common_index2)
                    loss3_basedOnDistanceErrorW = loss3_basedOnDistanceErrorW + ...
                        sum(...
                            sum(1 - distance_error_arrayW(:,:,not_common_index2),3) + ...
                            min(distance_error_arrayW(:,:,common_index2),[],3))./size(subZ,2);
                    % loss3_basedOnDistanceErrorW = loss3_basedOnDistanceErrorW + sum(nsubtemp)./(nsubtemp(i).*sum(nsubtemp~=0)).*  ...
                    %     sum( (subtemp==i)'.*mean(distance_error_arrayW(:,:,common_index2),3) ) ./ nsubtemp(i);
                end
        elseif  i == 6 && any(unique_subtemp==i) % 6: High-rise buildings
                col = [4];
                % "Concrete"
                [common_index,~]=intersect(col,true_centroidW_index);
                [~,ia,~] = intersect(true_centroidW_index,common_index);
                common_index2 = centroidW_index(ia);

                not_common_index2 = ~ismember(centroidW_index,common_index2).*centroidW_index;
                not_common_index2(not_common_index2==0) = [];

                if ~isempty(common_index2)
                    loss3_basedOnDistanceErrorW = loss3_basedOnDistanceErrorW + ...
                        sum(...
                            sum(1 - distance_error_arrayW(:,:,not_common_index2),3) + ...
                            min(distance_error_arrayW(:,:,common_index2),[],3))./size(subZ,2);
                    % loss3_basedOnDistanceErrorW = loss3_basedOnDistanceErrorW + sum(nsubtemp)./(nsubtemp(i).*sum(nsubtemp~=0)).*  ...
                    %     sum( (subtemp==i)'.*mean(distance_error_arrayW(:,:,common_index2),3) ) ./ nsubtemp(i);
                end
        elseif  i == 7 && any(unique_subtemp==i) % 7: Halls
                col = [2 3 4 6];
                % "Cement blocks"
                % "Concrete"
                [common_index,~]=intersect(col,true_centroidW_index);
                [~,ia,~] = intersect(true_centroidW_index,common_index);
                common_index2 = centroidW_index(ia);

                not_common_index2 = ~ismember(centroidW_index,common_index2).*centroidW_index;
                not_common_index2(not_common_index2==0) = [];

                if ~isempty(common_index2)
                    loss3_basedOnDistanceErrorW = loss3_basedOnDistanceErrorW + ...
                        sum(...
                            sum(1 - distance_error_arrayW(:,:,not_common_index2),3) + ...
                            min(distance_error_arrayW(:,:,common_index2),[],3))./size(subZ,2);
                    % loss3_basedOnDistanceErrorW = loss3_basedOnDistanceErrorW + sum(nsubtemp)./(nsubtemp(i).*sum(nsubtemp~=0)).*  ...
                    %     sum( (subtemp==i)'.*mean(distance_error_arrayW(:,:,common_index2),3) ) ./ nsubtemp(i);
                end
        end
    end
    sum_weights = sum(nsubtemp)./(nsubtemp.*sum(nsubtemp~=0));
    sum_weights(isinf(sum_weights)) = 0;
    % loss3_basedOnDistanceErrorW = loss3_basedOnDistanceErrorW ./ sum(sum_weights);

    %% Add them all together
    % loss3 = loss3_basedOnDistanceErrorH;
    loss3 = loss3_basedOnDistanceError + loss3_basedOnDistanceErrorH + loss3_basedOnDistanceErrorW;

    %% Reconstruction Loss
    loss2 = rmse(subY,X(:,indtemp)+1e-6,'all');

    %% Metrics Roof 
    sub_y_roof = labelsLocal;
    % xTPprop = (1./size(indtemp,1)) .* sum(...
    %    (subtemp==1) .* (sub_y_roof==1|sub_y_roof==4) + ...
    %    (subtemp==2) .* (sub_y_roof==1) + ...
    %    (subtemp==3) .* (sub_y_roof==1|sub_y_roof==2) + ...
    %    (subtemp==4) .* (sub_y_roof==1|sub_y_roof==2) + ...
    %    (subtemp==5) .* (sub_y_roof==1|sub_y_roof==2) + ...
    %    (subtemp==6) .* (sub_y_roof==1|sub_y_roof==3) + ...
    %    (subtemp==7) .* (sub_y_roof==1) ...
    %    );
    xTPprop = [ ...
       sum((subtemp==1) .* (sub_y_roof==1|sub_y_roof==4))./sum(subtemp==1) ; ...
       sum((subtemp==2) .* (sub_y_roof==1))./sum(subtemp==2) ; ...
       sum((subtemp==3) .* (sub_y_roof==1|sub_y_roof==2))./sum(subtemp==3) ; ...
       sum((subtemp==4) .* (sub_y_roof==1|sub_y_roof==2))./sum(subtemp==4) ; ...
       sum((subtemp==5) .* (sub_y_roof==1|sub_y_roof==2))./sum(subtemp==5) ; ...
       sum((subtemp==6) .* (sub_y_roof==1|sub_y_roof==3))./sum(subtemp==6) ; ...
       sum((subtemp==7) .* (sub_y_roof==1))./sum(subtemp==7) ...
       ].*sum(nsubtemp)./(nsubtemp.*sum(nsubtemp~=0));
    xTPprop(isnan(xTPprop)) = 0;
    xTPprop = sum(xTPprop)./sum(sum_weights);

    %% Metrics Height
    sub_y_height = true_centroidH_index(labelsLocalH); %range is 1 to 6, cat
    xTPpropH = (1./size(indtemp,1)) .* sum(...
       (subtempH==1) .* (sub_y_height==1|sub_y_height==2) + ...
       (subtempH==2) .* (sub_y_height==2|sub_y_height==3|sub_y_height==4) + ...
       (subtempH==3) .* (sub_y_height==3|sub_y_height==4|sub_y_height==5) + ...
       (subtempH==4) .* (sub_y_height==4|sub_y_height==5) + ...
       (subtempH==5) .* (sub_y_height==5|sub_y_height==5) + ...
       (subtempH==6) .* (sub_y_height==6) ...
       );
    xTPpropH = [ ...
       sum( (subtempH==1) .* (sub_y_height==1|sub_y_height==2) )./sum(subtempH==1) ; ...
       sum( (subtempH==2) .* (sub_y_height==2|sub_y_height==3|sub_y_height==4) )./sum(subtempH==2) ; ...
       sum( (subtempH==3) .* (sub_y_height==3|sub_y_height==4|sub_y_height==5) )./sum(subtempH==3) ; ...
       sum( (subtempH==4) .* (sub_y_height==4|sub_y_height==5) )./sum(subtempH==4) ; ...
       sum( (subtempH==5) .* (sub_y_height==5|sub_y_height==5) )./sum(subtempH==5) ; ...
       sum( (subtempH==6) .* (sub_y_height==6) )./sum(subtempH==6) ...
       ].*sum(nsubtempH)./(nsubtempH.*sum(nsubtempH~=0));
    xTPpropH(isnan(xTPpropH)) = 0;
    xTPpropH = sum(xTPpropH)./sum(sum_weightsH);


    %% Metrics Wall
    sub_y_wall = true_centroidW_index(labelsLocalW); 
    % xTPpropW = (1./size(indtemp,1)) .* sum(...
    %    (subtemp==1) .* (sub_y_wall==1|sub_y_wall==2|sub_y_wall==3|sub_y_wall==4|sub_y_wall==5|sub_y_wall==6|sub_y_wall==7|sub_y_wall==8) + ...
    %    (subtemp==2) .* (sub_y_wall==1|sub_y_wall==2|sub_y_wall==3|sub_y_wall==4|sub_y_wall==6) + ...
    %    (subtemp==3) .* (sub_y_wall==2|sub_y_wall==3|sub_y_wall==4|sub_y_wall==6|sub_y_wall==8) + ...
    %    (subtemp==4) .* (sub_y_wall==3|sub_y_wall==4|sub_y_wall==6) + ...
    %    (subtemp==5) .* (sub_y_wall==3|sub_y_wall==4|sub_y_wall==6) + ...
    %    (subtemp==6) .* (sub_y_wall==4) + ...
    %    (subtemp==7) .* (sub_y_wall==2|sub_y_wall==3|sub_y_wall==4|sub_y_wall==6) ...
    %    );
    xTPpropW = [ ...
       sum( (subtemp==1) .* (sub_y_wall==1|sub_y_wall==2|sub_y_wall==3|sub_y_wall==4|sub_y_wall==5|sub_y_wall==6|sub_y_wall==7|sub_y_wall==8) )./sum(subtemp==1) ; ...
       sum( (subtemp==2) .* (sub_y_wall==1|sub_y_wall==2|sub_y_wall==3|sub_y_wall==4|sub_y_wall==6) )./sum(subtemp==2) ; ...
       sum( (subtemp==3) .* (sub_y_wall==2|sub_y_wall==3|sub_y_wall==4|sub_y_wall==6|sub_y_wall==8) )./sum(subtemp==3) ; ...
       sum( (subtemp==4) .* (sub_y_wall==3|sub_y_wall==4|sub_y_wall==6) )./sum(subtemp==4) ; ...
       sum( (subtemp==5) .* (sub_y_wall==3|sub_y_wall==4|sub_y_wall==6) )./sum(subtemp==5) ; ...
       sum( (subtemp==6) .* (sub_y_wall==4) )./sum(subtemp==6) ; ...
       sum( (subtemp==7) .* (sub_y_wall==2|sub_y_wall==3|sub_y_wall==4|sub_y_wall==6) )./sum(subtemp==7) ...
       ].*sum(nsubtemp)./(nsubtemp.*sum(nsubtemp~=0));
    xTPpropW(isnan(xTPpropW)) = 0;
    xTPpropW = sum(xTPpropW)./sum(sum_weights);

    %% Loss and Gradient Update
    if train_boolean == true
        % loss = (loss2 + loss3).*max(nelem)./nind;
        % loss = (loss2./loss2_prev(iter) + loss3./loss3_prev(iter));
        % loss = (loss2./loss2_prev(iter) + loss3./loss3_prev(iter))*max(nelem)./nind; %.*max(nelem)./nind;
        loss = (loss2 + loss3);
        % loss = loss3;
     % loss = (loss2./loss2_prev(iter) + loss3./loss3_prev(iter) + loss4./loss4_prev(iter)).*max(nelem)./nind;
        
        [gradientsE,gradientsD] = ...
            dlgradient(dlarray(loss,'BC'),netE.Learnables,netD.Learnables);
        % dbstop in modelLoss.m at 483 if (anynan(extractdata(netE.Learnables.Value{1,1})) | anynan(extractdata(gradientsE.Value{1,1})))
        if anynan(extractdata(gradientsE.Value{1,1})) || anynan(extractdata(gradientsD.Value{1,1}))
            disp('nan gradient explosion alert')
            gradientsE = gradientsE_prev;
            gradientsD = gradientsD_prev;
        end

    else
        gradientsE = 1e7;
        gradientsD = 1e7;
    end

end