function [  constraints_array, ...
            constraints_array_H, ...
            constraints_array_W] = ...
            encodeConstraints(tau, tauH, tauW, ...
                              subtemp, subtempH, ...
                              nsubtemp, nsubtempH, ...
                              indtemp)

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
                                - max([ceil((sum(constraints_array(:,3))-size(indtemp,1)).*constraints_array(:,3)./sum(constraints_array(:,3))) ...
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
                                - max([ceil((sum(constraints_array_H(:,3))-size(indtemp,1)).*constraints_array_H(:,3)./sum(constraints_array_H(:,3))) ...
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
                                - max([ceil((sum(constraints_array_W(:,3))-size(indtemp,1)).*constraints_array_W(:,3)./sum(constraints_array_W(:,3))) ...
                                        repelem(0,8)'],[],2);
    constraints_array_W(constraints_array_W(:,4)<=0,4)=0;

end

