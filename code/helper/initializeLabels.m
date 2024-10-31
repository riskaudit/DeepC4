function [  labelsInitial, ...
            labelsInitialH, ...
            labelsInitialW] = initializeLabels( subtemp, ...
                                                subtempH, ...
                                                constraints_array, ...
                                                constraints_array_H, ...
                                                constraints_array_W)

    % Roof
    labelsInitial = zeros(size(subtemp));
    unique_subtemp = unique(subtemp);
    true_centroid_index = find(constraints_array(:,3)>0);
    for i = 1:7
        if      i == 7 && any(unique_subtemp==i)
                choices = [1];
                [commonChoices,~]=intersect(true_centroid_index,choices);
                [~,labelsToBeAssigned]=intersect(true_centroid_index,commonChoices);
                labelsInitial(subtemp==i) = labelsToBeAssigned(randi(length(labelsToBeAssigned),[1 sum(subtemp==i)]))';
        elseif  i == 6 && any(unique_subtemp==i)
                choices = [1 3];
                [commonChoices,~]=intersect(true_centroid_index,choices);
                [~,labelsToBeAssigned]=intersect(true_centroid_index,commonChoices);
                labelsInitial(subtemp==i) = labelsToBeAssigned(randi(length(labelsToBeAssigned),[1 sum(subtemp==i)]))';
                if any(labelsToBeAssigned==3) % special treatment for rare (once) occurrence
                    while sum(labelsInitial(subtemp==i)==3) == 0
                        labelsInitial(subtemp==i) = labelsToBeAssigned(randi(length(labelsToBeAssigned),[1 sum(subtemp==i)]))';
                    end
                end
        elseif  i == 5 && any(unique_subtemp==i)
                choices = [1 2];
                [commonChoices,~]=intersect(true_centroid_index,choices);
                [~,labelsToBeAssigned]=intersect(true_centroid_index,commonChoices);
                labelsInitial(subtemp==i) = labelsToBeAssigned(randi(length(labelsToBeAssigned),[1 sum(subtemp==i)]))';
                if any(labelsToBeAssigned==2) % special treatment for rare (once) occurrence
                    while sum(labelsInitial(subtemp==i)==2) == 0
                        labelsInitial(subtemp==i) = labelsToBeAssigned(randi(length(labelsToBeAssigned),[1 sum(subtemp==i)]))';
                    end
                end
        elseif  i == 4 && any(unique_subtemp==i)
                choices = [1 2];
                [commonChoices,~]=intersect(true_centroid_index,choices);
                [~,labelsToBeAssigned]=intersect(true_centroid_index,commonChoices);
                labelsInitial(subtemp==i) = labelsToBeAssigned(randi(length(labelsToBeAssigned),[1 sum(subtemp==i)]))';
                if any(labelsToBeAssigned==2) % special treatment for rare (once) occurrence
                    while sum(labelsInitial(subtemp==i)==2) == 0
                        labelsInitial(subtemp==i) = labelsToBeAssigned(randi(length(labelsToBeAssigned),[1 sum(subtemp==i)]))';
                    end
                end
        elseif  i == 3 && any(unique_subtemp==i)
                choices = [1 2];
                [commonChoices,~]=intersect(true_centroid_index,choices);
                [~,labelsToBeAssigned]=intersect(true_centroid_index,commonChoices);
                labelsInitial(subtemp==i) = labelsToBeAssigned(randi(length(labelsToBeAssigned),[1 sum(subtemp==i)]))';
                if any(labelsToBeAssigned==2) % special treatment for rare (once) occurrence
                    while sum(labelsInitial(subtemp==i)==2) == 0
                        labelsInitial(subtemp==i) = labelsToBeAssigned(randi(length(labelsToBeAssigned),[1 sum(subtemp==i)]))';
                    end
                end
        elseif  i == 2 && any(unique_subtemp==i)
                choices = [1];
                [commonChoices,~]=intersect(true_centroid_index,choices);
                [~,labelsToBeAssigned]=intersect(true_centroid_index,commonChoices);
                labelsInitial(subtemp==i) = labelsToBeAssigned(randi(length(labelsToBeAssigned),[1 sum(subtemp==i)]))';
        elseif  i == 1 && any(unique_subtemp==i)
                choices = [1 4];
                [commonChoices,~]=intersect(true_centroid_index,choices);
                [~,labelsToBeAssigned]=intersect(true_centroid_index,commonChoices);
                labelsInitial(subtemp==i) = labelsToBeAssigned(randi(length(labelsToBeAssigned),[1 sum(subtemp==i)]))';
                if any(labelsToBeAssigned==4) % special treatment for rare (once) occurrence
                    while sum(labelsInitial(subtemp==i)==4) == 0
                        labelsInitial(subtemp==i) = labelsToBeAssigned(randi(length(labelsToBeAssigned),[1 sum(subtemp==i)]))';
                    end
                end
        end
    end

    % Height
    labelsInitialH = zeros(size(subtempH));
    unique_subtempH = unique(subtempH);
    true_centroidH_index = find(constraints_array_H(:,3)>0);
    for i = 1:6
        if      i == 6 && any(unique_subtempH==i)
                choices = [6];
                [commonChoices,~]=intersect(true_centroidH_index,choices);
                [~,labelsToBeAssigned]=intersect(true_centroidH_index,commonChoices);
                labelsInitialH(subtempH==i) = labelsToBeAssigned(randi(length(labelsToBeAssigned),[1 sum(subtempH==i)]))';
                if (sum(subtempH==i) > length(labelsToBeAssigned)) && sum(ismember(labelsToBeAssigned, unique(labelsInitialH(subtempH==i)))) ~= length(labelsToBeAssigned)
                    while sum(ismember(labelsToBeAssigned, unique(labelsInitialH(subtempH==i)))) ~= length(labelsToBeAssigned)
                        labelsInitialH(subtempH==i) = labelsToBeAssigned(randi(length(labelsToBeAssigned),[1 sum(subtempH==i)]))';
                    end
                end
        elseif  i == 5 && any(unique_subtempH==i)
                choices = [5 6];
                [commonChoices,~]=intersect(true_centroidH_index,choices);
                [~,labelsToBeAssigned]=intersect(true_centroidH_index,commonChoices);
                labelsInitialH(subtempH==i) = labelsToBeAssigned(randi(length(labelsToBeAssigned),[1 sum(subtempH==i)]))';
                if (sum(subtempH==i) > length(labelsToBeAssigned)) && sum(ismember(labelsToBeAssigned, unique(labelsInitialH(subtempH==i)))) ~= length(labelsToBeAssigned)
                    while sum(ismember(labelsToBeAssigned, unique(labelsInitialH(subtempH==i)))) ~= length(labelsToBeAssigned)
                        labelsInitialH(subtempH==i) = labelsToBeAssigned(randi(length(labelsToBeAssigned),[1 sum(subtempH==i)]))';
                    end
                end
        elseif  i == 4 && any(unique_subtempH==i)
                choices = [4 5];
                [commonChoices,~]=intersect(true_centroidH_index,choices);
                [~,labelsToBeAssigned]=intersect(true_centroidH_index,commonChoices);
                labelsInitialH(subtempH==i) = labelsToBeAssigned(randi(length(labelsToBeAssigned),[1 sum(subtempH==i)]))';
                if (sum(subtempH==i) > length(labelsToBeAssigned)) && sum(ismember(labelsToBeAssigned, unique(labelsInitialH(subtempH==i)))) ~= length(labelsToBeAssigned)
                    while sum(ismember(labelsToBeAssigned, unique(labelsInitialH(subtempH==i)))) ~= length(labelsToBeAssigned)
                        labelsInitialH(subtempH==i) = labelsToBeAssigned(randi(length(labelsToBeAssigned),[1 sum(subtempH==i)]))';
                    end
                end
        elseif  i == 3 && any(unique_subtempH==i)
                choices = [3 4 5];
                [commonChoices,~]=intersect(true_centroidH_index,choices);
                [~,labelsToBeAssigned]=intersect(true_centroidH_index,commonChoices);
                labelsInitialH(subtempH==i) = labelsToBeAssigned(randi(length(labelsToBeAssigned),[1 sum(subtempH==i)]))';
                if (sum(subtempH==i) > length(labelsToBeAssigned)) && sum(ismember(labelsToBeAssigned, unique(labelsInitialH(subtempH==i)))) ~= length(labelsToBeAssigned) % ensures at least one of the labelstobeassigned exists
                    while sum(ismember(labelsToBeAssigned, unique(labelsInitialH(subtempH==i)))) ~= length(labelsToBeAssigned)
                        labelsInitialH(subtempH==i) = labelsToBeAssigned(randi(length(labelsToBeAssigned),[1 sum(subtempH==i)]))';
                    end
                end
        elseif  i == 2 && any(unique_subtempH==i)
                choices = [2 3 4];
                [commonChoices,~]=intersect(true_centroidH_index,choices);
                [~,labelsToBeAssigned]=intersect(true_centroidH_index,commonChoices);
                labelsInitialH(subtempH==i) = labelsToBeAssigned(randi(length(labelsToBeAssigned),[1 sum(subtempH==i)]))';
                if (sum(subtempH==i) > length(labelsToBeAssigned)) && sum(ismember(labelsToBeAssigned, unique(labelsInitialH(subtempH==i)))) ~= length(labelsToBeAssigned)
                    while sum(ismember(labelsToBeAssigned, unique(labelsInitialH(subtempH==i)))) ~= length(labelsToBeAssigned)
                        labelsInitialH(subtempH==i) = labelsToBeAssigned(randi(length(labelsToBeAssigned),[1 sum(subtempH==i)]))';
                    end
                end
        elseif  i == 1 && any(unique_subtempH==i)
                choices = [1 2];
                [commonChoices,~]=intersect(true_centroidH_index,choices);
                [~,labelsToBeAssigned]=intersect(true_centroidH_index,commonChoices);
                labelsInitialH(subtempH==i) = labelsToBeAssigned(randi(length(labelsToBeAssigned),[1 sum(subtempH==i)]))';
                if (sum(subtempH==i) > length(labelsToBeAssigned)) && sum(ismember(labelsToBeAssigned, unique(labelsInitialH(subtempH==i)))) ~= length(labelsToBeAssigned)
                    while sum(ismember(labelsToBeAssigned, unique(labelsInitialH(subtempH==i)))) ~= length(labelsToBeAssigned)
                        labelsInitialH(subtempH==i) = labelsToBeAssigned(randi(length(labelsToBeAssigned),[1 sum(subtempH==i)]))';
                    end
                end
        end
    end

    % Wall
    labelsInitialW = zeros(size(subtemp));
    unique_subtemp = unique(subtemp);
    true_centroidW_index = find(constraints_array_W(:,3)>0);
    for i = 1:7
        if      i == 7 && any(unique_subtemp==i)
                choices = [2 3 4 6];
                [commonChoices,~]=intersect(true_centroidW_index,choices);
                [~,labelsToBeAssigned]=intersect(true_centroidW_index,commonChoices);
                labelsInitialW(subtemp==i) = labelsToBeAssigned(randi(length(labelsToBeAssigned),[1 sum(subtemp==i)]))';
        elseif  i == 6 && any(unique_subtemp==i)
                choices = [4];
                [commonChoices,~]=intersect(true_centroidW_index,choices);
                [~,labelsToBeAssigned]=intersect(true_centroidW_index,commonChoices);
                labelsInitialW(subtemp==i) = labelsToBeAssigned(randi(length(labelsToBeAssigned),[1 sum(subtemp==i)]))';
        elseif  i == 5 && any(unique_subtemp==i)
                choices = [3 4 6];
                [commonChoices,~]=intersect(true_centroidW_index,choices);
                [~,labelsToBeAssigned]=intersect(true_centroidW_index,commonChoices);
                labelsInitialW(subtemp==i) = labelsToBeAssigned(randi(length(labelsToBeAssigned),[1 sum(subtemp==i)]))';
        elseif  i == 4 && any(unique_subtemp==i)
                choices = [3 4 6];
                [commonChoices,~]=intersect(true_centroidW_index,choices);
                [~,labelsToBeAssigned]=intersect(true_centroidW_index,commonChoices);
                labelsInitialW(subtemp==i) = labelsToBeAssigned(randi(length(labelsToBeAssigned),[1 sum(subtemp==i)]))';
        elseif  i == 3 && any(unique_subtemp==i)
                choices = [2 3 4 6 8];
                [commonChoices,~]=intersect(true_centroidW_index,choices);
                [~,labelsToBeAssigned]=intersect(true_centroidW_index,commonChoices);
                labelsInitialW(subtemp==i) = labelsToBeAssigned(randi(length(labelsToBeAssigned),[1 sum(subtemp==i)]))';
        elseif  i == 2 && any(unique_subtemp==i)
                choices = [1 2 3 4 6];
                [commonChoices,~]=intersect(true_centroidW_index,choices);
                [~,labelsToBeAssigned]=intersect(true_centroidW_index,commonChoices);
                labelsInitialW(subtemp==i) = labelsToBeAssigned(randi(length(labelsToBeAssigned),[1 sum(subtemp==i)]))';
        elseif  i == 1 && any(unique_subtemp==i)
                choices = [1 2 3 4 5 6 7 8];
                [commonChoices,~]=intersect(true_centroidW_index,choices);
                [~,labelsToBeAssigned]=intersect(true_centroidW_index,commonChoices);
                labelsInitialW(subtemp==i) = labelsToBeAssigned(randi(length(labelsToBeAssigned),[1 sum(subtemp==i)]))';
        end
    end


end

