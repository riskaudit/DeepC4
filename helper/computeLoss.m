function [loss] = ...
    computeLoss(...
    Z, indtemp, ...
    constraints_array, ...
    constraints_array_H, ...
    constraints_array_W, ... 
    centroids, ...
    centroidsH, ...
    centroidsW, ...
    subtemp, subtempH, ...
    nsubtemp, nsubtempH, ...
    unique_subtemp, unique_subtempH)

    %% Calculate PredictionLoss Roof 
    identified_classes_index = find(constraints_array(:,3)>0);
    distance_error_array = (repmat(centroids,[1,size(indtemp,1),1])-...
                            repmat(Z(indtemp,1)',[1,1,sum(constraints_array(:,3)~=0)])).^2;
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
                        % loss3_basedOnDistanceError = loss3_basedOnDistanceError + ...
                        % sum(...
                        %     sum(1 - distance_error_array(:,:,not_common_index2),3) + ...
                        %     min(distance_error_array(:,:,common_index),[],3))./size(indtemp,1);
                        loss3_basedOnDistanceError = loss3_basedOnDistanceError +  ...   
                            sum( (subtemp==i)'.*mean(distance_error_array(:,:,common_index),3) ) ./ nsubtemp(i);
                    end
                end
        elseif  i == 2 && any(unique_subtemp==i)
                if nsubtemp(i) ~= 0 
                    col = [1];
                    [common_index,~]=intersect(col,identified_classes_index);

                    not_common_index2 = ~ismember(identified_classes_index,common_index).*identified_classes_index;
                    not_common_index2(not_common_index2==0) = [];
                    
                    if ~isempty(common_index)
                        % loss3_basedOnDistanceError = loss3_basedOnDistanceError + ...
                        % sum(...
                        %     sum(1 - distance_error_array(:,:,not_common_index2),3) + ...
                        %     min(distance_error_array(:,:,common_index),[],3))./size(indtemp,1);
                        loss3_basedOnDistanceError = loss3_basedOnDistanceError + ...  
                            sum( (subtemp==i)'.*mean(distance_error_array(:,:,common_index),3) ) ./ nsubtemp(i);
                    end
                end
        elseif  i == 3 && any(unique_subtemp==i)
                if nsubtemp(i) ~= 0 
                    col = [1 2];
                    [common_index,~]=intersect(col,identified_classes_index);

                    not_common_index2 = ~ismember(identified_classes_index,common_index).*identified_classes_index;
                    not_common_index2(not_common_index2==0) = [];

                    if ~isempty(common_index)
                        % loss3_basedOnDistanceError = loss3_basedOnDistanceError + ...
                        % sum(...
                        %     sum(1 - distance_error_array(:,:,not_common_index2),3) + ...
                        %     min(distance_error_array(:,:,common_index),[],3))./size(indtemp,1);
                        loss3_basedOnDistanceError = loss3_basedOnDistanceError +  ...  
                            sum( (subtemp==i)'.*mean(distance_error_array(:,:,common_index),3) ) ./ nsubtemp(i);
                    end
                end
        elseif  i == 4 && any(unique_subtemp==i)
                if nsubtemp(i) ~= 0 
                    col = [1 2];
                    [common_index,~]=intersect(col,identified_classes_index);

                    not_common_index2 = ~ismember(identified_classes_index,common_index).*identified_classes_index;
                    not_common_index2(not_common_index2==0) = [];

                    if ~isempty(common_index)
                        % loss3_basedOnDistanceError = loss3_basedOnDistanceError + ...
                        % sum(...
                        %     sum(1 - distance_error_array(:,:,not_common_index2),3) + ...
                        %     min(distance_error_array(:,:,common_index),[],3))./size(indtemp,1);
                        loss3_basedOnDistanceError = loss3_basedOnDistanceError +  ...  
                            sum( (subtemp==i)'.*mean(distance_error_array(:,:,common_index),3) ) ./ nsubtemp(i);
                    end
                end
        elseif  i == 5
                if nsubtemp(i) ~= 0 
                    col = [1 2];
                    [common_index,~]=intersect(col,identified_classes_index);

                    not_common_index2 = ~ismember(identified_classes_index,common_index).*identified_classes_index;
                    not_common_index2(not_common_index2==0) = [];

                    if ~isempty(common_index)
                        % loss3_basedOnDistanceError = loss3_basedOnDistanceError + ...
                        % sum(...
                        %     sum(1 - distance_error_array(:,:,not_common_index2),3) + ...
                        %     min(distance_error_array(:,:,common_index),[],3))./size(indtemp,1);
                        loss3_basedOnDistanceError = loss3_basedOnDistanceError + ...  
                            sum( (subtemp==i)'.*mean(distance_error_array(:,:,common_index),3) ) ./ nsubtemp(i);
                    end
                end
        elseif  i == 6
                if nsubtemp(i) ~= 0 
                    col = [1 3];
                    [common_index,~]=intersect(col,identified_classes_index);

                    not_common_index2 = ~ismember(identified_classes_index,common_index).*identified_classes_index;
                    not_common_index2(not_common_index2==0) = [];

                    if ~isempty(common_index)

                        % loss3_basedOnDistanceError = loss3_basedOnDistanceError + ...
                        % sum(...
                        %     sum(1 - distance_error_array(:,:,not_common_index2),3) + ...
                        %     min(distance_error_array(:,:,common_index),[],3))./size(indtemp,1);

                        loss3_basedOnDistanceError = loss3_basedOnDistanceError +  ...  
                            sum( (subtemp==i)'.*mean(distance_error_array(:,:,common_index),3) ) ./ nsubtemp(i);
                    end
                end
        elseif  i == 7
                if nsubtemp(i) ~= 0 
                    col = [1];
                    [common_index,~]=intersect(col,identified_classes_index);

                    not_common_index2 = ~ismember(identified_classes_index,common_index).*identified_classes_index;
                    not_common_index2(not_common_index2==0) = [];

                    if ~isempty(common_index)

                        % loss3_basedOnDistanceError = loss3_basedOnDistanceError + ...
                        % sum(...
                        %     sum(1 - distance_error_array(:,:,not_common_index2),3) + ...
                        %     min(distance_error_array(:,:,common_index),[],3))./size(indtemp,1);

                        loss3_basedOnDistanceError = loss3_basedOnDistanceError + ...  
                            sum( (subtemp==i)'.*mean(distance_error_array(:,:,common_index),3) ) ./ nsubtemp(i);
                    end
                end
        end
    end
    % sum_weights = sum(nsubtemp)./(nsubtemp.*sum(nsubtemp~=0));
    % sum_weights(isinf(sum_weights)) = 0;
    % loss3_basedOnDistanceError = loss3_basedOnDistanceError ./ sum(sum_weights);
    
    %% Calculate PredictionLoss Height
    true_centroidH_index = find(constraints_array_H(:,3)>0);
    centroidH_index = (1:sum(constraints_array_H(:,3)~=0))';
    distance_error_arrayH = (repmat(centroidsH,[1,size(indtemp,1),1])-...
                            repmat(Z(indtemp,2)',[1,1,sum(constraints_array_H(:,3)~=0)])).^2;
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
                    % loss3_basedOnDistanceErrorH = loss3_basedOnDistanceErrorH + ...
                    %     sum(...
                    %         sum(1 - distance_error_arrayH(:,:,not_common_index2),3) + ...
                    %         min(distance_error_arrayH(:,:,common_index2),[],3))./size(indtemp,1);
                    loss3_basedOnDistanceErrorH = loss3_basedOnDistanceErrorH + ...
                        sum( (subtempH==i)'.*mean(distance_error_arrayH(:,:,common_index2),3) ) ./ nsubtempH(i);
                end
        elseif  i == 2 && any(unique_subtempH==i) % (3,5.5]
                col = [2 3 4]; 
                [common_index,~]=intersect(col,true_centroidH_index);
                [~,ia,~] = intersect(true_centroidH_index,common_index);
                common_index2 = centroidH_index(ia);

                not_common_index2 = ~ismember(centroidH_index,common_index2).*centroidH_index;
                not_common_index2(not_common_index2==0) = [];

                if ~isempty(common_index2)
                    % loss3_basedOnDistanceErrorH = loss3_basedOnDistanceErrorH + ...
                    %     sum(...
                    %         sum(1 - distance_error_arrayH(:,:,not_common_index2),3) + ...
                    %         min(distance_error_arrayH(:,:,common_index2),[],3))./size(indtemp,1);
                    loss3_basedOnDistanceErrorH = loss3_basedOnDistanceErrorH + ...
                        sum( (subtempH==i)'.*mean(distance_error_arrayH(:,:,common_index2),3) ) ./ nsubtempH(i);
                end
        elseif  i == 3 && any(unique_subtempH==i) % (5.5,8] 
                col = [3 4 5]; 
                [common_index,~]=intersect(col,true_centroidH_index);
                [~,ia,~] = intersect(true_centroidH_index,common_index);
                common_index2 = centroidH_index(ia);

                not_common_index2 = ~ismember(centroidH_index,common_index2).*centroidH_index;
                not_common_index2(not_common_index2==0) = [];

                if ~isempty(common_index2)
                    % loss3_basedOnDistanceErrorH = loss3_basedOnDistanceErrorH + ...
                    %     sum(...
                    %         sum(1 - distance_error_arrayH(:,:,not_common_index2),3) + ...
                    %         min(distance_error_arrayH(:,:,common_index2),[],3))./size(indtemp,1);
                    loss3_basedOnDistanceErrorH = loss3_basedOnDistanceErrorH + ...
                        sum( (subtempH==i)'.*mean(distance_error_arrayH(:,:,common_index2),3) ) ./ nsubtempH(i);
                end
        elseif  i == 4 && any(unique_subtempH==i) % (8,10]
                col = [4 5]; 
                [common_index,~]=intersect(col,true_centroidH_index);
                [~,ia,~] = intersect(true_centroidH_index,common_index);
                common_index2 = centroidH_index(ia);

                not_common_index2 = ~ismember(centroidH_index,common_index2).*centroidH_index;
                not_common_index2(not_common_index2==0) = [];

                if ~isempty(common_index2)
                    % loss3_basedOnDistanceErrorH = loss3_basedOnDistanceErrorH + ...
                    %     sum(...
                    %         sum(1 - distance_error_arrayH(:,:,not_common_index2),3) + ...
                    %         min(distance_error_arrayH(:,:,common_index2),[],3))./size(indtemp,1);
                    loss3_basedOnDistanceErrorH = loss3_basedOnDistanceErrorH +  ...
                        sum( (subtempH==i)'.*mean(distance_error_arrayH(:,:,common_index2),3) ) ./ nsubtempH(i);
                end
        elseif  i == 5 && any(unique_subtempH==i) % (10,14]
                col = [5 6]; 
                [common_index,~]=intersect(col,true_centroidH_index);
                [~,ia,~] = intersect(true_centroidH_index,common_index);
                common_index2 = centroidH_index(ia);

                not_common_index2 = ~ismember(centroidH_index,common_index2).*centroidH_index;
                not_common_index2(not_common_index2==0) = [];

                if ~isempty(common_index2)
                    % loss3_basedOnDistanceErrorH = loss3_basedOnDistanceErrorH + ...
                    %     sum(...
                    %         sum(1 - distance_error_arrayH(:,:,not_common_index2),3) + ...
                    %         min(distance_error_arrayH(:,:,common_index2),[],3))./size(indtemp,1);
                    loss3_basedOnDistanceErrorH = loss3_basedOnDistanceErrorH +  ...
                        sum( (subtempH==i)'.*mean(distance_error_arrayH(:,:,common_index2),3) ) ./ nsubtempH(i);
                end
        elseif  i == 6 && any(unique_subtempH==i) % (14,16]
                col = [6]; 
                [common_index,~]=intersect(col,true_centroidH_index);
                [~,ia,~] = intersect(true_centroidH_index,common_index);
                common_index2 = centroidH_index(ia);

                not_common_index2 = ~ismember(centroidH_index,common_index2).*centroidH_index;
                not_common_index2(not_common_index2==0) = [];

                if ~isempty(common_index2)
                    % loss3_basedOnDistanceErrorH = loss3_basedOnDistanceErrorH + ...
                    %     sum(...
                    %         sum(1 - distance_error_arrayH(:,:,not_common_index2),3) + ...
                    %         min(distance_error_arrayH(:,:,common_index2),[],3))./size(indtemp,1);
                    loss3_basedOnDistanceErrorH = loss3_basedOnDistanceErrorH +  ...
                        sum( (subtempH==i)'.*mean(distance_error_arrayH(:,:,common_index2),3) ) ./ nsubtempH(i);
                end
        end
    end
    % sum_weightsH = sum(nsubtempH)./(nsubtempH.*sum(nsubtempH~=0));
    % sum_weightsH(isinf(sum_weightsH)) = 0;
    % loss3_basedOnDistanceErrorH = loss3_basedOnDistanceErrorH ./ sum(sum_weightsH);

    %% Calculate PredictionLoss Wall
    true_centroidW_index = find(constraints_array_W(:,3)>0);
    centroidW_index = (1:sum(constraints_array_W(:,3)~=0))';
    distance_error_arrayW = (repmat(centroidsW,[1,size(indtemp,1),1])-...
                            repmat(Z(indtemp,3)',[1,1,sum(constraints_array_W(:,3)~=0)])).^2;
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
                    % loss3_basedOnDistanceErrorW = loss3_basedOnDistanceErrorW + ...
                    %     sum(...
                    %         sum(1 - distance_error_arrayW(:,:,not_common_index2),3) + ...
                    %         min(distance_error_arrayW(:,:,common_index2),[],3))./size(indtemp,1);
                    loss3_basedOnDistanceErrorW = loss3_basedOnDistanceErrorW + ...
                        sum( (subtemp==i)'.*mean(distance_error_arrayW(:,:,common_index2),3) ) ./ nsubtemp(i);
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
                    % loss3_basedOnDistanceErrorW = loss3_basedOnDistanceErrorW + ...
                    %     sum(...
                    %         sum(1 - distance_error_arrayW(:,:,not_common_index2),3) + ...
                    %         min(distance_error_arrayW(:,:,common_index2),[],3))./size(indtemp,1);
                    loss3_basedOnDistanceErrorW = loss3_basedOnDistanceErrorW + ...
                        sum( (subtemp==i)'.*mean(distance_error_arrayW(:,:,common_index2),3) ) ./ nsubtemp(i);
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
                    % loss3_basedOnDistanceErrorW = loss3_basedOnDistanceErrorW + ...
                    %     sum(...
                    %         sum(1 - distance_error_arrayW(:,:,not_common_index2),3) + ...
                    %         min(distance_error_arrayW(:,:,common_index2),[],3))./size(indtemp,1);
                    loss3_basedOnDistanceErrorW = loss3_basedOnDistanceErrorW +  ...
                        sum( (subtemp==i)'.*mean(distance_error_arrayW(:,:,common_index2),3) ) ./ nsubtemp(i);
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
                    % loss3_basedOnDistanceErrorW = loss3_basedOnDistanceErrorW + ...
                    %     sum(...
                    %         sum(1 - distance_error_arrayW(:,:,not_common_index2),3) + ...
                    %         min(distance_error_arrayW(:,:,common_index2),[],3))./size(indtemp,1);
                    loss3_basedOnDistanceErrorW = loss3_basedOnDistanceErrorW + ...
                        sum( (subtemp==i)'.*mean(distance_error_arrayW(:,:,common_index2),3) ) ./ nsubtemp(i);
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
                    % loss3_basedOnDistanceErrorW = loss3_basedOnDistanceErrorW + ...
                    %     sum(...
                    %         sum(1 - distance_error_arrayW(:,:,not_common_index2),3) + ...
                    %         min(distance_error_arrayW(:,:,common_index2),[],3))./size(indtemp,1);
                    loss3_basedOnDistanceErrorW = loss3_basedOnDistanceErrorW +  ...
                        sum( (subtemp==i)'.*mean(distance_error_arrayW(:,:,common_index2),3) ) ./ nsubtemp(i);
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
                    % loss3_basedOnDistanceErrorW = loss3_basedOnDistanceErrorW + ...
                    %     sum(...
                    %         sum(1 - distance_error_arrayW(:,:,not_common_index2),3) + ...
                    %         min(distance_error_arrayW(:,:,common_index2),[],3))./size(indtemp,1);
                    loss3_basedOnDistanceErrorW = loss3_basedOnDistanceErrorW +  ...
                        sum( (subtemp==i)'.*mean(distance_error_arrayW(:,:,common_index2),3) ) ./ nsubtemp(i);
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
                    % loss3_basedOnDistanceErrorW = loss3_basedOnDistanceErrorW + ...
                    %     sum(...
                    %         sum(1 - distance_error_arrayW(:,:,not_common_index2),3) + ...
                    %         min(distance_error_arrayW(:,:,common_index2),[],3))./size(indtemp,1);
                    loss3_basedOnDistanceErrorW = loss3_basedOnDistanceErrorW +  ...
                        sum( (subtemp==i)'.*mean(distance_error_arrayW(:,:,common_index2),3) ) ./ nsubtemp(i);
                end
        end
    end
    % sum_weights = sum(nsubtemp)./(nsubtemp.*sum(nsubtemp~=0));
    % sum_weights(isinf(sum_weights)) = 0;
    % loss3_basedOnDistanceErrorW = loss3_basedOnDistanceErrorW ./ sum(sum_weights);

    %% Combine
    loss = loss3_basedOnDistanceError + loss3_basedOnDistanceErrorH + loss3_basedOnDistanceErrorW;
    

end

