clear, clc, close
cd '/Users/joshuadimasaka/Desktop/PhD/GitHub/DeepC4'

%% load maskR
[~, maskR] = readgeoraster("data/MASK/rasterized_vector.tif");

%% load building-level data from  Bachofer
load("output/20240916_JointDC_Downstream1/input.mat",... ...
    "X_batch","tau_batch","tauH_batch","tauW_batch","btype_label","label_height","ind_batch","nelem")

%% load finished model 
load("output/20241011_JointDC_CorrectedLoss/outputTrainedModels.mat",... 
    "netE_history","netD_history",...
    "xTPpropR_history","xTPpropH_history","xTPpropW_history",...
    "BatchTPpropR_history","BatchTPpropH_history","BatchTPpropW_history",...
    "ReconstructionLoss_history","PredictionLoss_history")

%% Determine the optimal iter and epoch

% Upon inspection, desirable reconstruction loss <= 5 (MSE)
target_epochs = find(sum(ReconstructionLoss_history<=1,2)>0 ...
                & sum(PredictionLoss_history<=500,2)>0);
target_epochs = target_epochs(target_epochs >= 150);

% Refine selection using TPprop for Roof, Height, and Wall
averageTPprop = BatchTPpropR_history(target_epochs,1)./3 + ... 
                BatchTPpropH_history(target_epochs,1)./3 + ...
                BatchTPpropW_history(target_epochs,1)./3;
final_epoch   = target_epochs(averageTPprop==max(averageTPprop));
target_iters  = 1:30;
averageXTPprop = xTPpropR_history(final_epoch,:)./3 + ... 
                 xTPpropH_history(final_epoch,:)./3 + ...
                 xTPpropW_history(final_epoch,:)./3;
final_iter    = target_iters(averageXTPprop==max(averageXTPprop));

nBatch = 30;
y_roof = zeros(size(btype_label));
y_height = zeros(size(btype_label));
y_wall = zeros(size(btype_label));

for iter = 1:nBatch
    

    %% Forward through encoder.
    Z = forward(netE_history{final_epoch,final_iter},...
        dlarray(X_batch{iter}, 'BC')+1e-6);

    %% Input supervision
    ind = ind_batch{iter};
    sub_label_roofwall  = sparse(double(btype_label(ind)));
    sub_label_height = sparse(double(label_height(ind)));
    sub_label_height_cat = ...
       ((sub_label_height>0)&(sub_label_height<6))              .* 1 + ...
       ((sub_label_height>=6)&(sub_label_height<9))             .* 2 + ...
       ((sub_label_height>=9)&(sub_label_height<12))            .* 3 + ...
       ((sub_label_height>=12)&(sub_label_height<15))           .* 4 + ...
       ((sub_label_height>=15)&(sub_label_height<21))           .* 5 + ...
       ((sub_label_height>=21)&(sub_label_height<24))           .* 6 + ...
       ((sub_label_height>=24))                                 .* 7;


    indtemp = find(sub_label_roofwall>0 & sub_label_roofwall<=7 & sub_label_height>0);
 
    subtemp = full(sub_label_roofwall(indtemp));
    subtempH = full(sub_label_height_cat(indtemp));
    unique_subtemp = unique(subtemp);
    unique_subtempH = unique(subtempH);
    nsubtemp = histcounts(subtemp)';
    nsubtempH = histcounts(subtempH)';

    subZ = Z(:,indtemp);

    %% Supervision constraints
    tau = tau_batch{iter};
    tauH = tauH_batch{iter};
    tauW = tauW_batch{iter};
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
    constraints_array(:,4) =   constraints_array(:,2);
    % constraints_array(1:2,4) =   constraints_array(1:2,2) - ceil((sum(constraints_array(:,2))-size(subZ,2))./2);

    % constraints_array(:,4) =   constraints_array(:,2) - ...
    %     ceil((sum(constraints_array(:,2))-size(subZ,2)).*...
    %     (constraints_array(:,2)./sum(constraints_array(:,2))));

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
    constraints_array_H(:,4) =   constraints_array_H(:,2);
    % constraints_array_H([3 4 5],4) =   constraints_array_H([3 4 5],2) - ...
    %     ceil((sum(constraints_array_H(:,2))-size(subZ,2)).*...
    %     (constraints_array_H([3 4 5],2)./sum(constraints_array_H([3 4 5],2))));
    % constraints_array_H(4:5,4) =   constraints_array_H([4 5],2) - ...
    %     ceil((sum(constraints_array_H(:,2))-size(subZ,2)).*...
    %     (constraints_array_H([4 5],2)./sum(constraints_array_H([4 5],2))));

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
    constraints_array_W(:,4) =   constraints_array_W(:,2);
    constraints_array_W(:,4) =   constraints_array_W(:,2) - ...
        ceil((sum(constraints_array_W(:,2))-size(subZ,2)).*...
        (constraints_array_W(:,2)./sum(constraints_array_W(:,2))));
    % constraints_array_W([1 2 3 4 6 8],4) =   constraints_array_W([1 2 3 4 6 8],2) - ...
    %     ceil((sum(constraints_array_W(:,2))-size(subZ,2)).*...
    %     (constraints_array_W([1 2 3 4 6 8],2)./sum(constraints_array_W([1 2 3 4 6 8],2))));
    % constraints_array_W(:,4) =  constraints_array_W(:,3) ...
    %                             - max([ceil((sum(constraints_array_W(:,3))-size(subZ,2)).*constraints_array_W(:,3)./sum(constraints_array_W(:,3))) ...
    %                                     repelem(0,8)'],[],2);
    constraints_array_W(constraints_array_W(:,4)<=0,4)=0;

    %% Perform clustering part 1 - a local for supervised.
    disp('roof')
    [labelsLocal,centroids] = constrainedKMeans_DEC(subZ(1,:), ...
        sum(constraints_array(:,3)~=0), ...
        constraints_array(constraints_array(:,3)>0,4), 50);
    disp('height')
    constraints_array_H(1,4) = constraints_array_H(1,4) - 100;
    [labelsLocalH,centroidsH] = constrainedKMeans_DEC(subZ(2,:), ...
        sum(constraints_array_H(:,3)~=0), ...
        constraints_array_H(constraints_array_H(:,3)>0,4), 50);
    disp('wall')
    [labelsLocalW,centroidsW] = constrainedKMeans_DEC(subZ(3,:), ...
        sum(constraints_array_W(:,3)~=0), ...
        constraints_array_W(constraints_array_W(:,3)>0,4), 50);

    %% Metrics Roof 
    sub_y_roof = labelsLocal;
    y_roof(ind(indtemp)) = 1 + ...
       (subtemp==1) .* (sub_y_roof==1|sub_y_roof==4) + ...
       (subtemp==2) .* (sub_y_roof==1) + ...
       (subtemp==3) .* (sub_y_roof==1|sub_y_roof==2) + ...
       (subtemp==4) .* (sub_y_roof==1|sub_y_roof==2) + ...
       (subtemp==5) .* (sub_y_roof==1|sub_y_roof==2) + ...
       (subtemp==6) .* (sub_y_roof==1|sub_y_roof==3) + ...
       (subtemp==7) .* (sub_y_roof==1);

    %% Metrics Height
    true_centroidH_index = find(constraints_array_H(:,3)>0);
    sub_y_height = true_centroidH_index(labelsLocalH); %range is 1 to 6, cat
    y_height(ind(indtemp)) = 1 + ...
       (subtempH==1) .* (sub_y_height==1) + ...
       (subtempH==2) .* (sub_y_height==2) + ...
       (subtempH==3) .* (sub_y_height==3|sub_y_height==4) + ...
       (subtempH==4) .* (sub_y_height==4|sub_y_height==5) + ...
       (subtempH==5) .* (sub_y_height==4|sub_y_height==5) + ...
       (subtempH==6) .* (sub_y_height==5) + ...
       (subtempH==7) .* (sub_y_height==6);

    %% Metrics Wall
    true_centroidW_index = find(constraints_array_W(:,3)>0);
    sub_y_wall = true_centroidW_index(labelsLocalW); 
    y_wall(ind(indtemp)) = 1 + ...
       (subtemp==1) .* (sub_y_wall==1|sub_y_wall==2|sub_y_wall==3|sub_y_wall==4|sub_y_wall==5|sub_y_wall==6|sub_y_wall==7|sub_y_wall==8) + ...
       (subtemp==2) .* (sub_y_wall==1|sub_y_wall==2|sub_y_wall==3|sub_y_wall==4|sub_y_wall==6) + ...
       (subtemp==3) .* (sub_y_wall==2|sub_y_wall==3|sub_y_wall==4|sub_y_wall==6|sub_y_wall==8) + ...
       (subtemp==4) .* (sub_y_wall==3|sub_y_wall==4|sub_y_wall==6) + ...
       (subtemp==5) .* (sub_y_wall==3|sub_y_wall==4|sub_y_wall==6) + ...
       (subtemp==6) .* (sub_y_wall==4) + ...
       (subtemp==7) .* (sub_y_wall==2|sub_y_wall==3|sub_y_wall==4|sub_y_wall==6);    

end

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