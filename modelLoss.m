function [loss2,loss3,xTPprop, ...
    gradientsE,gradientsD] = modelLoss(netE,netD,X,...
    tau,n_class,btype_label,ind,...
    loss2_prev,loss3_prev,ntotal,nind)

    % Forward through encoder.
    % [Z,mu,logSigmaSq] = forward(netE,X);
    Z = forward(netE,X);

    % Forward through decoder.
    Y = forward(netD,Z);

    % Input supervision
    sub_label_roof  = sparse(double(btype_label(ind)));
    temp = sub_label_roof;
    indtemp = find(temp>0 & temp<=7);
    subtemp = full(temp(indtemp));
    nsubtemp = histcounts(subtemp)';
    subZ = Z(:,indtemp);

    % Supervision constraints
    constraints_array = tau;

    % Assign maximum allowable to get minimum constraints
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
                                - max([ceil((sum(constraints_array(:,3))-length(subZ)).*constraints_array(:,3)./sum(constraints_array(:,3))) ...
                                        repelem(0,4)'],[],2);
    constraints_array(constraints_array(:,4)<=0,4)=0;

    % Perform clustering part 1 - a local for supervised.
    failed = 1;
    while failed == 1
        try

            % MinCostFlow - 98.117 at epoch 14, does not converge for long
            % epochs, results in NAN at epoch around >25, when max(ntotal)./nind;
             % - 98.416 at epoch 21, does not converge for long
            % epochs, results in NAN at epoch around >35, when nind./min(ntotal)
            [labelsLocal,centroids] = constrainedKMeans_DEC(subZ, ...
                sum(constraints_array(:,3)~=0), ...
                constraints_array(constraints_array(:,3)>0,4), 1000);

            % Gaussian Mixture - 60%, 93.29% at epoch 142 when NLL is incorporated
            % [labelsLocal,loss4,~,~,d2] = cluster(...
            %     fitgmdist(extractdata(subZ)',sum(constraints_array(:,3)~=0),...
            %     'CovarianceType','diagonal',...
            %     'RegularizationValue',0.01,...
            %     'SharedCovariance',true,...
            %     'Options',statset('MaxIter',1500,'TolFun',1e-5)),...
            %     extractdata(subZ)');
            % [D,n] = size(extractdata(subZ));
            % labelsNewOneHot = reshape(onehotencode(labelsLocal,2,"ClassNames",1:sum(constraints_array(:,3)~=0)),[n sum(constraints_array(:,3)~=0) 1]);
            % Z_onehotencoded_new = extractdata(subZ).*repmat(reshape(labelsNewOneHot,[1 n sum(constraints_array(:,3)~=0)]),[D 1 1]);
            % centroids = mean(Z_onehotencoded_new,2);

            % Spectral Clustering - 60%
            % labelsLocal = spectralcluster(extractdata(subZ)',sum(constraints_array(:,3)~=0),...
            %     "LaplacianNormalization","symmetric");
            % [D,n] = size(extractdata(subZ));
            % labelsNewOneHot = reshape(onehotencode(labelsLocal,2,"ClassNames",1:sum(constraints_array(:,3)~=0)),[n sum(constraints_array(:,3)~=0) 1]);
            % Z_onehotencoded_new = extractdata(subZ).*repmat(reshape(labelsNewOneHot,[1 n sum(constraints_array(:,3)~=0)]),[D 1 1]);
            % centroids = mean(Z_onehotencoded_new,2);

            failed = 0;
        catch MyErr
            failed = 1;
        end
    end
    subtemp2 = labelsLocal;

    % Calculate PredictionLoss
    identified_classes_index = find(tau ~= 0);
    distance_error_array = sqrt((centroids-subZ).^2);
    % distance_error_array = reshape(d2,[D n sum(constraints_array(:,3)~=0)]);
    loss3_basedOnDistanceError = 0;
    for i = 1:length(nsubtemp)
        if      i == 1
                if nsubtemp(i) ~= 0
                    col = [1 4];
                    [common_index,~]=intersect(col,identified_classes_index);
                    if ~isempty(common_index)
                        loss3_basedOnDistanceError = loss3_basedOnDistanceError + ...
                            mean(sum((subtemp==i)' .* mean(distance_error_array(:,:,common_index),1))./nsubtemp(i));
                    end
                end
        elseif  i == 2
                if nsubtemp(i) ~= 0 
                    col = [1];
                    [common_index,~]=intersect(col,identified_classes_index);
                    if ~isempty(common_index)
                        loss3_basedOnDistanceError = loss3_basedOnDistanceError + ...
                            sum((subtemp==i)' .* mean(distance_error_array(:,:,common_index),1))./nsubtemp(i);
                    end
                end
        elseif  i == 3
                if nsubtemp(i) ~= 0 
                    col = [1 2];
                    [common_index,~]=intersect(col,identified_classes_index);
                    if ~isempty(common_index)
                        loss3_basedOnDistanceError = loss3_basedOnDistanceError + ...
                            mean(sum((subtemp==i)' .* mean(distance_error_array(:,:,common_index),1))./nsubtemp(i));
                    end
                end
        elseif  i == 4
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
                            sum((subtemp==i)' .* mean(distance_error_array(:,:,common_index),1))./nsubtemp(i);
                    end
                end
        end
    end
    loss3 = loss3_basedOnDistanceError;

    % Reconstruction Loss
    loss2 = mse(Y,X);

    % Metrics
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
    C = confusionmat((subtemp==i),(sub_y_roof==1|sub_y_roof==2),'Order',[0 1]);
    weighted_metric_roof(i,2) = C(2,2) ./ (C(2,2)+C(2,1));
    weighted_metric_roof(i,3) = C(2,2) ./ (C(2,2)+C(1,2));
    weighted_metric_roof(i,4) = (C(2,2)+C(1,1)) ./ (C(2,2)+C(2,1)+C(1,1)+C(1,2));
    weighted_metric_roof(i,5) = 2.*C(2,2) ./ (2.*C(2,2)+C(1,2)+C(2,1));
    i = 6;
    C = confusionmat((subtemp==i),(sub_y_roof==1|sub_y_roof==3),'Order',[0 1]);
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

    loss = (loss2 + loss3 ).*nind./min(ntotal); %max(ntotal)./nind;
    % nind./min(ntotal)
    % loss = loss2./(loss2_prev+1e-3)+10.*loss3./(loss3_prev+1e-3)+1e-2;
    [gradientsE,gradientsD] = ...
        dlgradient(dlarray(loss,'BC'),netE.Learnables,netD.Learnables);


end