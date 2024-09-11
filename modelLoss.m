function [loss2,loss3,loss4,xTPprop,xPre,xRec,xAccu,xF1, ...
    consistencyLocalGlobal,gradientsE,gradientsD] = modelLoss(netE,netD,X,...
    summary_RoofMaterial,n_class,sub_label_roof,ind,...
    loss2_prev,loss3_prev,loss4_prev)

    % Forward through encoder.
    % [Z,mu,logSigmaSq] = forward(netE,X);
    Z = forward(netE,X);

    % Forward through decoder.
    Y = forward(netD,Z);

    % Input supervision
    temp = full(sub_label_roof(ind));
    indtemp = find(temp>0 & temp<=7);
    subtemp = temp(indtemp);
    nsubtemp = histcounts(subtemp)';
    subZ = Z(:,indtemp);

    % Supervision constraints
    tau = floor(summary_RoofMaterial .* size(Z,2));
    if sum(tau) ~= size(Z,2)
        ttmp = find(tau == max(tau),1);
        tau(ttmp) = tau(ttmp) + (size(Z,2)-sum(tau));
    end
    constraints_array = tau;

    % Assign maximum allowable to get minimum constraints
    for i = 1:length(tau)
        if i == 1
            if tau(i) ~= 0
                constraints_array(i,2) = sum(nsubtemp([1 2 3 4 7]));
            end
        elseif i == 2
            if tau(i) ~= 0
                constraints_array(i,2) = sum(nsubtemp([3 4 5]));
            end
        elseif i == 3
            if tau(i) ~= 0
                constraints_array(i,2) = sum(nsubtemp(6));
            end
        elseif i == 4
            if tau(i) ~= 0
                constraints_array(i,2) = sum(nsubtemp(1));
            end
        end
    end
    constraints_array(:,3) =    constraints_array(:,1).*(constraints_array(:,1)<=constraints_array(:,2)) + ...
                                constraints_array(:,2).*(constraints_array(:,1)>constraints_array(:,2));
    constraints_array(:,4) =    constraints_array(:,3) - (sum(constraints_array(:,3))-length(subZ));
    constraints_array(constraints_array(:,4)<=0,4)=0;

    % Perform clustering part 1 - a local for supervised.
    failed = 1;
    while failed == 1
        try
            [labelsLocal,centroids] = constrainedKMeans_DEC(subZ, ...
                sum(constraints_array(:,3)~=0), ...
                constraints_array(constraints_array(:,3)>0,4), 1000);
            failed = 0;
        catch MyErr
            failed = 1;
        end
    end
    subtemp2 = labelsLocal;

    % Calculate PredictionLoss
    identified_classes_index = find(tau ~= 0);
    distance_error_array = sqrt((centroids-subZ).^2);
    loss3_basedOnDistanceError = 0;
    for i = 1:length(nsubtemp)
        if      i == 1
                if nsubtemp(i) ~= 0
                    col = [1 4];
                    [common_index,~]=intersect(col,identified_classes_index);
                    loss3_basedOnDistanceError = loss3_basedOnDistanceError + ...
                        mean(sum((subtemp==i)' .* mean(distance_error_array(:,:,common_index),1))./nsubtemp(i));
                end
        elseif  i == 2
                if nsubtemp(i) ~= 0 
                    col = [1];
                    [common_index,~]=intersect(col,identified_classes_index);
                    loss3_basedOnDistanceError = loss3_basedOnDistanceError + ...
                        sum((subtemp==i)' .* mean(distance_error_array(:,:,common_index),1))./nsubtemp(i);
                end
        elseif  i == 3
                if nsubtemp(i) ~= 0 
                    col = [1 2];
                    [common_index,~]=intersect(col,identified_classes_index);
                    loss3_basedOnDistanceError = loss3_basedOnDistanceError + ...
                        mean(sum((subtemp==i)' .* mean(distance_error_array(:,:,common_index),1))./nsubtemp(i));
                end
        elseif  i == 4
                if nsubtemp(i) ~= 0 
                    col = [1 2];
                    [common_index,~]=intersect(col,identified_classes_index);
                    loss3_basedOnDistanceError = loss3_basedOnDistanceError + ...
                        mean(sum((subtemp==i)' .* mean(distance_error_array(:,:,common_index),1))./nsubtemp(i));
                end
        elseif  i == 5
                if nsubtemp(i) ~= 0 
                    col = [2];
                    [common_index,~]=intersect(col,identified_classes_index);
                    loss3_basedOnDistanceError = loss3_basedOnDistanceError + ...
                        sum((subtemp==i)' .* mean(distance_error_array(:,:,common_index),1))./nsubtemp(i);
                end
        elseif  i == 6
                if nsubtemp(i) ~= 0 
                    col = [3];
                    [common_index,~]=intersect(col,identified_classes_index);
                    loss3_basedOnDistanceError = loss3_basedOnDistanceError + ...
                        sum((subtemp==i)' .* mean(distance_error_array(:,:,common_index),1))./nsubtemp(i);
                end
        elseif  i == 7
                if nsubtemp(i) ~= 0 
                    col = [1];
                    [common_index,~]=intersect(col,identified_classes_index);
                    loss3_basedOnDistanceError = loss3_basedOnDistanceError + ...
                        sum((subtemp==i)' .* mean(distance_error_array(:,:,common_index),1))./nsubtemp(i);
                end
        end
    end
    loss3 = loss3_basedOnDistanceError;

    % Perform clustering part 2 - the local learning we have from part 1 must be
    % consistent with the global results (when applied)
    failed = 1;
    while failed == 1
        try
            [labelsGlobal,centroidsGlobal] = constrainedKMeans_DEC(Z, ...
                n_class, tau(tau ~= 0), 1000);
            failed = 0;
        catch MyErr
            failed = 1;
        end
        % if failed == 0
        %     err = sum(abs((tau(tau ~= 0))'-(histcounts(labelsGlobal)))) ...
        %         ./ sum(tau(tau ~= 0));
        % end
    end
    % Loss based on Consistencu
    centroidsGlobalforLocal = centroidsGlobal(:,:,constraints_array(:,3)>0);
    distance_error_arrayGlobal = sqrt((centroidsGlobalforLocal-subZ).^2);
    loss4_basedOnGlobalLocalConsistency = 0;
    for i = 1:length(nsubtemp)
        if      i == 1
                if nsubtemp(i) ~= 0
                    col = [1 4];
                    [common_index,~]=intersect(col,identified_classes_index);
                    loss4_basedOnGlobalLocalConsistency = loss4_basedOnGlobalLocalConsistency + ...
                        mean(sum((subtemp==i)' .* ...
                        mean(abs(distance_error_arrayGlobal(:,:,common_index)-distance_error_array(:,:,common_index)),1))./nsubtemp(i));
                end
        elseif  i == 2
                if nsubtemp(i) ~= 0 
                    col = [1];
                    [common_index,~]=intersect(col,identified_classes_index);
                    loss4_basedOnGlobalLocalConsistency = loss4_basedOnGlobalLocalConsistency + ...
                        sum((subtemp==i)' .* ...
                        mean(abs(distance_error_arrayGlobal(:,:,common_index)-distance_error_array(:,:,common_index)),1))./nsubtemp(i);
                end
        elseif  i == 3
                if nsubtemp(i) ~= 0 
                    col = [1 2];
                    [common_index,~]=intersect(col,identified_classes_index);
                    loss4_basedOnGlobalLocalConsistency = loss4_basedOnGlobalLocalConsistency + ...
                        mean(sum((subtemp==i)' .* ...
                        mean(abs(distance_error_arrayGlobal(:,:,common_index)-distance_error_array(:,:,common_index)),1))./nsubtemp(i));
                end
        elseif  i == 4
                if nsubtemp(i) ~= 0 
                    col = [1 2];
                    [common_index,~]=intersect(col,identified_classes_index);
                    loss4_basedOnGlobalLocalConsistency = loss4_basedOnGlobalLocalConsistency + ...
                        mean(sum((subtemp==i)' .* ...
                        mean(abs(distance_error_arrayGlobal(:,:,common_index)-distance_error_array(:,:,common_index)),1))./nsubtemp(i));
                end
        elseif  i == 5
                if nsubtemp(i) ~= 0 
                    col = [2];
                    [common_index,~]=intersect(col,identified_classes_index);
                    loss4_basedOnGlobalLocalConsistency = loss4_basedOnGlobalLocalConsistency + ...
                        sum((subtemp==i)' .* ...
                        mean(abs(distance_error_arrayGlobal(:,:,common_index)-distance_error_array(:,:,common_index)),1))./nsubtemp(i);
                end
        elseif  i == 6
                if nsubtemp(i) ~= 0 
                    col = [3];
                    [common_index,~]=intersect(col,identified_classes_index);
                    loss4_basedOnGlobalLocalConsistency = loss4_basedOnGlobalLocalConsistency + ...
                        sum((subtemp==i)' .* ...
                        mean(abs(distance_error_arrayGlobal(:,:,common_index)-distance_error_array(:,:,common_index)),1))./nsubtemp(i);
                end
        elseif  i == 7
                if nsubtemp(i) ~= 0 
                    col = [1];
                    [common_index,~]=intersect(col,identified_classes_index);
                    loss4_basedOnGlobalLocalConsistency = loss4_basedOnGlobalLocalConsistency + ...
                        sum((subtemp==i)' .* ...
                        mean(abs(distance_error_arrayGlobal(:,:,common_index)-distance_error_array(:,:,common_index)),1))./nsubtemp(i);
                end
        end
    end
    loss4 = loss4_basedOnGlobalLocalConsistency;

    % Metric
    consistencyLocalGlobal = sum(labelsLocal == labelsGlobal(indtemp))./length(indtemp);

    % Cluster Loss
    % qij = zeros(size(Z,2), n_class);
    % nu = 1;
    % Z_qij = double(extractdata(Z));
    % for iQ = 1:size(qij,1)
    %     for jQ = 1:size(qij,2)
    %         qij(iQ,jQ) = tpdf(pdist2(Z_qij(:,iQ)',centroids(jQ,:)),nu);
    %     end
    % end
    % qij = qij./sum(qij,2);
    % pij = qij.*qij./sum(qij,1);
    % pij = pij./sum(pij,2);
    % M   = numel(pij);                   
    % P   = reshape(pij,[M,1]);           
    % Q   = reshape(qij,[M,1]);
    % KLD = nansum( P .* log2( P./Q ) );
    % loss_C = KLD;

    % Combine Cluster Loss with elboLoss (incl. reconstruction and
    % variational normality)
    % loss1 = regularization.*loss_C;
    % loss2 = elboLoss(Y,X,mu,logSigmaSq);
    loss2 = mse(Y,X);

    % subqij = qij(indtemp,:);

    

    sub_y_roof = labelsLocal;
    xTPprop = (1./size(indtemp,1)) .* sum(...
       (subtemp==1) .* (sub_y_roof==1|sub_y_roof==4) + ...
       (subtemp==2) .* (sub_y_roof==1) + ...
       (subtemp==3) .* (sub_y_roof==1|sub_y_roof==2) + ...
       (subtemp==4) .* (sub_y_roof==1|sub_y_roof==2) + ...
       (subtemp==5) .* (sub_y_roof==2) + ...
       (subtemp==6) .* (sub_y_roof==3) + ...
       (subtemp==7) .* (sub_y_roof==1) ...
       );

    weighted_metric_roof = zeros(7,5);
    for i = 1:7
        weighted_metric_roof(i,1) = sum(subtemp==i);
    end
    i = 1;
    C = confusionmat((subtemp==i),(sub_y_roof==1|sub_y_roof==4),'Order',[0 1]);
    weighted_metric_roof(i,2) = C(2,2) ./ (C(2,2)+C(2,1));
    weighted_metric_roof(i,3) = C(2,2) ./ (C(2,2)+C(1,2));
    weighted_metric_roof(i,4) = (C(2,2)+C(1,1)) ./ (C(2,2)+C(2,1)+C(1,1)+C(1,2));
    weighted_metric_roof(i,5) = 2.*C(2,2) ./ (2.*C(2,2)+C(1,2)+C(2,1));
    i = 2;
    C = confusionmat((subtemp==i),(sub_y_roof==1),'Order',[0 1]);
    weighted_metric_roof(i,2) = C(2,2) ./ (C(2,2)+C(2,1));
    weighted_metric_roof(i,3) = C(2,2) ./ (C(2,2)+C(1,2));
    weighted_metric_roof(i,4) = (C(2,2)+C(1,1)) ./ (C(2,2)+C(2,1)+C(1,1)+C(1,2));
    weighted_metric_roof(i,5) = 2.*C(2,2) ./ (2.*C(2,2)+C(1,2)+C(2,1));
    i = 3;
    C = confusionmat((subtemp==i),(sub_y_roof==1|sub_y_roof==2),'Order',[0 1]);
    weighted_metric_roof(i,2) = C(2,2) ./ (C(2,2)+C(2,1));
    weighted_metric_roof(i,3) = C(2,2) ./ (C(2,2)+C(1,2));
    weighted_metric_roof(i,4) = (C(2,2)+C(1,1)) ./ (C(2,2)+C(2,1)+C(1,1)+C(1,2));
    weighted_metric_roof(i,5) = 2.*C(2,2) ./ (2.*C(2,2)+C(1,2)+C(2,1));
    i = 4;
    C = confusionmat((subtemp==i),(sub_y_roof==1|sub_y_roof==2),'Order',[0 1]);
    weighted_metric_roof(i,2) = C(2,2) ./ (C(2,2)+C(2,1));
    weighted_metric_roof(i,3) = C(2,2) ./ (C(2,2)+C(1,2));
    weighted_metric_roof(i,4) = (C(2,2)+C(1,1)) ./ (C(2,2)+C(2,1)+C(1,1)+C(1,2));
    weighted_metric_roof(i,5) = 2.*C(2,2) ./ (2.*C(2,2)+C(1,2)+C(2,1));
    i = 5;
    C = confusionmat((subtemp==i),(sub_y_roof==2),'Order',[0 1]);
    weighted_metric_roof(i,2) = C(2,2) ./ (C(2,2)+C(2,1));
    weighted_metric_roof(i,3) = C(2,2) ./ (C(2,2)+C(1,2));
    weighted_metric_roof(i,4) = (C(2,2)+C(1,1)) ./ (C(2,2)+C(2,1)+C(1,1)+C(1,2));
    weighted_metric_roof(i,5) = 2.*C(2,2) ./ (2.*C(2,2)+C(1,2)+C(2,1));
    i = 6;
    C = confusionmat((subtemp==i),(sub_y_roof==3),'Order',[0 1]);
    weighted_metric_roof(i,2) = C(2,2) ./ (C(2,2)+C(2,1));
    weighted_metric_roof(i,3) = C(2,2) ./ (C(2,2)+C(1,2));
    weighted_metric_roof(i,4) = (C(2,2)+C(1,1)) ./ (C(2,2)+C(2,1)+C(1,1)+C(1,2));
    weighted_metric_roof(i,5) = 2.*C(2,2) ./ (2.*C(2,2)+C(1,2)+C(2,1));
    i = 7;
    C = confusionmat((subtemp==i),(sub_y_roof==1),'Order',[0 1]);
    weighted_metric_roof(i,2) = C(2,2) ./ (C(2,2)+C(2,1));
    weighted_metric_roof(i,3) = C(2,2) ./ (C(2,2)+C(1,2));
    weighted_metric_roof(i,4) = (C(2,2)+C(1,1)) ./ (C(2,2)+C(2,1)+C(1,1)+C(1,2));
    weighted_metric_roof(i,5) = 2.*C(2,2) ./ (2.*C(2,2)+C(1,2)+C(2,1));
    weighted_metric_roof(isnan(weighted_metric_roof)) = 0;
    weighted_metric_roof(8,1) = sum(weighted_metric_roof(1:7,1));
    xPre = sum((weighted_metric_roof(1:7,1) ./ weighted_metric_roof(8,1)) .* ... 
                                weighted_metric_roof(1:7,2));
    xRec = sum((weighted_metric_roof(1:7,1) ./ weighted_metric_roof(8,1)) .* ... 
                                weighted_metric_roof(1:7,3));
    xAccu = sum((weighted_metric_roof(1:7,1) ./ weighted_metric_roof(8,1)) .* ... 
                                weighted_metric_roof(1:7,4));
    xF1 = sum((weighted_metric_roof(1:7,1) ./ weighted_metric_roof(8,1)) .* ... 
                                weighted_metric_roof(1:7,5));


    % 
    % weighted_loss_ind = zeros(length(nsubtemp),1);
    % for i = 1:length(nsubtemp)
    %     if      i == 1
    %             col = [1 4];
    %             [common_index,~]=intersect(col,identified_classes_index);
    %             Y = sum(subqij(:,common_index),2); %probability
    %             Y = [Y 1-Y];
    %             T = onehotencode(double(subtemp == i),2,"ClassNames",[1 0]); %target one hot encoding
    %             weighted_loss_ind(i,1) = crossentropy(Y,T);
    %     elseif  i == 2
    %             col = [1];
    %             [common_index,~]=intersect(col,identified_classes_index);
    %             Y = sum(subqij(:,common_index),2); %probability
    %             Y = [Y 1-Y];
    %             T = onehotencode(double(subtemp == i),2,"ClassNames",[1 0]); %target one hot encoding
    %             weighted_loss_ind(i,1) = crossentropy(Y,T);
    %     elseif  i == 3
    %             col = [1 2];
    %             [common_index,~]=intersect(col,identified_classes_index);
    %             Y = sum(subqij(:,common_index),2); %probability
    %             Y = [Y 1-Y];
    %             T = onehotencode(double(subtemp == i),2,"ClassNames",[1 0]); %target one hot encoding
    %             weighted_loss_ind(i,1) = crossentropy(Y,T);
    %     elseif  i == 4
    %             col = [1 2];
    %             [common_index,~]=intersect(col,identified_classes_index);
    %             Y = sum(subqij(:,common_index),2); %probability
    %             Y = [Y 1-Y];
    %             T = onehotencode(double(subtemp == i),2,"ClassNames",[1 0]); %target one hot encoding
    %             weighted_loss_ind(i,1) = crossentropy(Y,T);
    %     elseif  i == 5
    %             col = [2];
    %             [common_index,~]=intersect(col,identified_classes_index);
    %             Y = sum(subqij(:,common_index),2); %probability
    %             Y = [Y 1-Y];
    %             T = onehotencode(double(subtemp == i),2,"ClassNames",[1 0]); %target one hot encoding
    %             weighted_loss_ind(i,1) = crossentropy(Y,T);
    %     elseif  i == 6
    %             col = [3];
    %             [common_index,~]=intersect(col,identified_classes_index);
    %             Y = sum(subqij(:,common_index),2); %probability
    %             Y = [Y 1-Y];
    %             T = onehotencode(double(subtemp == i),2,"ClassNames",[1 0]); %target one hot encoding
    %             weighted_loss_ind(i,1) = crossentropy(Y,T);
    %     elseif  i == 7
    %             col = [1];
    %             [common_index,~]=intersect(col,identified_classes_index);
    %             Y = sum(subqij(:,common_index),2); %probability
    %             Y = [Y 1-Y];
    %             T = onehotencode(double(subtemp == i),2,"ClassNames",[1 0]); %target one hot encoding
    %             weighted_loss_ind(i,1) = crossentropy(Y,T);
    %     end
    % end
    % loss3 = sum(weighted_loss_ind.*nsubtemp./sum(nsubtemp));

    % loss = loss1 + loss2 + loss3;
    loss = loss2./loss2_prev+loss3./loss3_prev+loss4./loss4_prev;
    % loss = loss2./loss2_prev+loss3./loss3_prev+loss4./loss4_prev;
    [gradientsE,gradientsD] = ...
        dlgradient(dlarray(loss,'BC'),netE.Learnables,netD.Learnables);


end