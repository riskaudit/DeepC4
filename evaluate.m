%% Evaluate several methodologies and variants of deep clustering approach
% 
% Our evaluation can be limited because our prediction is for the year 2022
% whereas the high-resolution building-level data we consider to be 
% accurate is the work done by Bachoder of DLR for the year 2015. Our
% evaluation is only on positive predictions, which means that we consider
% only non-zero prediction category labels. We do not evaluate the quality
% of absence, as we assume that the prior belief we obtained DynamicWorld
% map would suffice that requirement.
%
% List of approaches:
% 1. modelCC.m - constrained K-means clustering (Bradley et al. 2000)
% 2. 

%% initialize
clear, clc, close
cd '/Users/joshuadimasaka/Desktop/PhD/GitHub/rwa'

%% modelCC.m - constrained K-means clustering (Bradley et al. 2000)
[y_height, maskR] = readgeoraster("output/20240907_DC_411/y_height.tif");
[y_roof, ~] = readgeoraster("output/20240907_DC_411/y_roof_DC.tif");
[y_wall, ~] = readgeoraster("output/20240907_DC_411/y_wall.tif");
[label_height, ~] = readgeoraster("data/BLDG/BACHOFER DLR/EO4Kigali_2015_bheight.tif");
[btype_label, ~] = readgeoraster("data/BLDG/BACHOFER DLR/EO4Kigali_2015_btype.tif");

% % crop the label maps with just the pruned location set from the prediction
% % set     
% label_height = label_height(y_height ~= 0);
% btype_label = btype_label(y_height ~= 0);

idx_height = find(label_height> 0 & y_height>0);
sub_label_height = label_height(idx_height);
sub_y_height = y_height(idx_height);

%% height_label 
% (0,3]     1st                 100% x H:1
% (3,5.5]   2nd                 100% x H:2
% (5.5,8]   3rd                 50% x H:3         + 50% x HBET:3-6
% (8,10]    4th                 50% x HBET:3-6    + 50% x HBET:4-7
% (10,14]   5th, 6th            50% x HBET:3-6    + 50% x HBET:4-7
% (14,16]   7th                 100% x HBET:4-7
% (16,inf]  8th                 100% x HBET: 8+

tp_height = (1./size(idx_height,1)) .* sum(...
       ((sub_label_height>0)&(sub_label_height<=3)) .* (sub_y_height==1) + ...
       ((sub_label_height>3)&(sub_label_height<=5.5)) .* (sub_y_height==2) + ...
       ((sub_label_height>5.5)&(sub_label_height<=8)) .* (sub_y_height==3|sub_y_height==4) + ...
       ((sub_label_height>8)&(sub_label_height<=10)) .* (sub_y_height==4|sub_y_height==5) + ...
       ((sub_label_height>10)&(sub_label_height<=14)) .* (sub_y_height==4|sub_y_height==5) + ...
       ((sub_label_height>14)&(sub_label_height<=16)) .* (sub_y_height==5) + ...
       ((sub_label_height>16)) .* (sub_y_height==6) ...
       );


weighted_metric_height = zeros(7,5);
weighted_metric_height(1,1) = sum((sub_label_height>0)&(sub_label_height<=3));
weighted_metric_height(2,1) = sum((sub_label_height>3)&(sub_label_height<=5.5));
weighted_metric_height(3,1) = sum((sub_label_height>5.5)&(sub_label_height<=8));
weighted_metric_height(4,1) = sum((sub_label_height>8)&(sub_label_height<=10));
weighted_metric_height(5,1) = sum((sub_label_height>10)&(sub_label_height<=14));
weighted_metric_height(6,1) = sum((sub_label_height>14)&(sub_label_height<=16));
weighted_metric_height(7,1) = sum((sub_label_height>16));


i = 1;
C = confusionmat(((sub_label_height>0)&(sub_label_height<=3)),(sub_y_height==1),'Order',[0 1]);
weighted_metric_height(i,2) = C(2,2) ./ (C(2,2)+C(2,1));
weighted_metric_height(i,3) = C(2,2) ./ (C(2,2)+C(1,2));
weighted_metric_height(i,4) = (C(2,2)+C(1,1)) ./ (C(2,2)+C(2,1)+C(1,1)+C(1,2));
weighted_metric_height(i,5) = 2.*C(2,2) ./ (2.*C(2,2)+C(1,2)+C(2,1));

i = 2;
C = confusionmat(((sub_label_height>3)&(sub_label_height<=5.5)),(sub_y_height==2),'Order',[0 1]);
weighted_metric_height(i,2) = C(2,2) ./ (C(2,2)+C(2,1));
weighted_metric_height(i,3) = C(2,2) ./ (C(2,2)+C(1,2));
weighted_metric_height(i,4) = (C(2,2)+C(1,1)) ./ (C(2,2)+C(2,1)+C(1,1)+C(1,2));
weighted_metric_height(i,5) = 2.*C(2,2) ./ (2.*C(2,2)+C(1,2)+C(2,1));

i = 3;
C = confusionmat(((sub_label_height>5.5)&(sub_label_height<=8)),(sub_y_height==3|sub_y_height==4),'Order',[0 1]);
weighted_metric_height(i,2) = C(2,2) ./ (C(2,2)+C(2,1));
weighted_metric_height(i,3) = C(2,2) ./ (C(2,2)+C(1,2));
weighted_metric_height(i,4) = (C(2,2)+C(1,1)) ./ (C(2,2)+C(2,1)+C(1,1)+C(1,2));
weighted_metric_height(i,5) = 2.*C(2,2) ./ (2.*C(2,2)+C(1,2)+C(2,1));

i = 4;
C = confusionmat(((sub_label_height>8)&(sub_label_height<=10)),(sub_y_height==4|sub_y_height==5),'Order',[0 1]);
weighted_metric_height(i,2) = C(2,2) ./ (C(2,2)+C(2,1));
weighted_metric_height(i,3) = C(2,2) ./ (C(2,2)+C(1,2));
weighted_metric_height(i,4) = (C(2,2)+C(1,1)) ./ (C(2,2)+C(2,1)+C(1,1)+C(1,2));
weighted_metric_height(i,5) = 2.*C(2,2) ./ (2.*C(2,2)+C(1,2)+C(2,1));

i = 5;
C = confusionmat(((sub_label_height>10)&(sub_label_height<=14)),(sub_y_height==4|sub_y_height==5),'Order',[0 1]);
weighted_metric_height(i,2) = C(2,2) ./ (C(2,2)+C(2,1));
weighted_metric_height(i,3) = C(2,2) ./ (C(2,2)+C(1,2));
weighted_metric_height(i,4) = (C(2,2)+C(1,1)) ./ (C(2,2)+C(2,1)+C(1,1)+C(1,2));
weighted_metric_height(i,5) = 2.*C(2,2) ./ (2.*C(2,2)+C(1,2)+C(2,1));

i = 6;
C = confusionmat(((sub_label_height>14)&(sub_label_height<=16)),(sub_y_height==5),'Order',[0 1]);
weighted_metric_height(i,2) = C(2,2) ./ (C(2,2)+C(2,1));
weighted_metric_height(i,3) = C(2,2) ./ (C(2,2)+C(1,2));
weighted_metric_height(i,4) = (C(2,2)+C(1,1)) ./ (C(2,2)+C(2,1)+C(1,1)+C(1,2));
weighted_metric_height(i,5) = 2.*C(2,2) ./ (2.*C(2,2)+C(1,2)+C(2,1));

i = 7;
C = confusionmat(((sub_label_height>16)),(sub_y_height==6),'Order',[0 1]);
weighted_metric_height(i,2) = C(2,2) ./ (C(2,2)+C(2,1));
weighted_metric_height(i,3) = C(2,2) ./ (C(2,2)+C(1,2));
weighted_metric_height(i,4) = (C(2,2)+C(1,1)) ./ (C(2,2)+C(2,1)+C(1,1)+C(1,2));
weighted_metric_height(i,5) = 2.*C(2,2) ./ (2.*C(2,2)+C(1,2)+C(2,1));

weighted_metric_height(isnan(weighted_metric_height)) = 0;
weighted_metric_height(8,1) = sum(weighted_metric_height(1:7,1));
weighted_metric_height(8,2) = sum((weighted_metric_height(1:7,1) ./ weighted_metric_height(8,1)) .* ... 
                            weighted_metric_height(1:7,2));
weighted_metric_height(8,3) = sum((weighted_metric_height(1:7,1) ./ weighted_metric_height(8,1)) .* ... 
                            weighted_metric_height(1:7,3));
weighted_metric_height(8,4) = sum((weighted_metric_height(1:7,1) ./ weighted_metric_height(8,1)) .* ... 
                            weighted_metric_height(1:7,4));
weighted_metric_height(8,5) = sum((weighted_metric_height(1:7,1) ./ weighted_metric_height(8,1)) .* ... 
                            weighted_metric_height(1:7,5));


%%
idx_roof = find((btype_label>0 & btype_label<=7) & y_roof>0);
sub_label_roof = btype_label(idx_roof);
sub_y_roof = y_roof(idx_roof);

idx_wall = find((btype_label>0 & btype_label<=7) & y_wall>0);
sub_label_wall = btype_label(idx_wall);
sub_y_wall = y_wall(idx_wall);

%% y_roof
% 1 - iron sheets
% 2 - tiles
% 3 - concrete
% 4 - grass

%% y_wall
% 1 - Wood w/ mud
% 2 - Sun-dried bricks
% 3 - All non-durable materials
% 4 - Cement blocks
% 5 - Concrete
% 6 - Stones
% 7 - Timber
% 8 - Burnt bricks
% 
% btype_label 
% 1: Rudimentary, basic or unplanned buildings
%       y_roof: 1, 4
%       y_wall: All except 4, 5
% 2: Building in block structure/large courtyard buildings
%       y_roof: 1
%       y_wall: 4, 5, 8
% 3: Bungalow-type buildings
%       y_roof: 1, 2
%       y_wall: 4, 5, 8
% 4: Villa-type buildings
%       y_roof: 1, 2
%       y_wall: 4, 5
% 5: Low to mid-rise multi-unit buildings
%       y_roof: 2
%       y_wall: 4, 5
% 6: High-rise buildings
%       y_roof: 3
%       y_wall: 5
% 7: Halls
%       y_roof: 1
%       y_wall: 4, 5
% 8: Special structures
%       y_roof: na
%       y_wall: na
% 9: Construction sites
%       y_roof: na
%       y_wall: na

tp_roof = (1./size(idx_roof,1)) .* sum(...
       (sub_label_roof==1) .* (sub_y_roof==1|sub_y_roof==4) + ...
       (sub_label_roof==2) .* (sub_y_roof==1) + ...
       (sub_label_roof==3) .* (sub_y_roof==1|sub_y_roof==2) + ...
       (sub_label_roof==4) .* (sub_y_roof==1|sub_y_roof==2) + ...
       (sub_label_roof==5) .* (sub_y_roof==2) + ...
       (sub_label_roof==6) .* (sub_y_roof==3) + ...
       (sub_label_roof==7) .* (sub_y_roof==1) ...
       )

% nsize, precision, recall, accuracy, and F1 score
weighted_metric_roof = zeros(7,5);
for i = 1:7
    weighted_metric_roof(i,1) = sum(sub_label_roof==i);
end
tp_roof_array = zeros(length(sub_y_roof),7);
fp_roof_array = zeros(length(sub_y_roof),7);
fn_roof_array = zeros(length(sub_y_roof),7);
tn_roof_array = zeros(length(sub_y_roof),7);


i = 1;
C = confusionmat((sub_label_roof==i),(sub_y_roof==1|sub_y_roof==4),'Order',[0 1]);
weighted_metric_roof(i,2) = C(2,2) ./ (C(2,2)+C(2,1));
weighted_metric_roof(i,3) = C(2,2) ./ (C(2,2)+C(1,2));
weighted_metric_roof(i,4) = (C(2,2)+C(1,1)) ./ (C(2,2)+C(2,1)+C(1,1)+C(1,2));
weighted_metric_roof(i,5) = 2.*C(2,2) ./ (2.*C(2,2)+C(1,2)+C(2,1));
concatLabelPred = string(sub_label_roof==i) + string(sub_y_roof==1|sub_y_roof==4);
tp_roof_array(:,i) = concatLabelPred == "truetrue";
fp_roof_array(:,i) = concatLabelPred == "falsetrue";
fn_roof_array(:,i) = concatLabelPred == "truefalse";
tn_roof_array(:,i) = concatLabelPred == "falsefalse";


i = 2;
C = confusionmat((sub_label_roof==i),(sub_y_roof==1),'Order',[0 1]);
weighted_metric_roof(i,2) = C(2,2) ./ (C(2,2)+C(2,1));
weighted_metric_roof(i,3) = C(2,2) ./ (C(2,2)+C(1,2));
weighted_metric_roof(i,4) = (C(2,2)+C(1,1)) ./ (C(2,2)+C(2,1)+C(1,1)+C(1,2));
weighted_metric_roof(i,5) = 2.*C(2,2) ./ (2.*C(2,2)+C(1,2)+C(2,1));
concatLabelPred = string(sub_label_roof==i) + string(sub_y_roof==1);
tp_roof_array(:,i) = concatLabelPred == "truetrue";
fp_roof_array(:,i) = concatLabelPred == "falsetrue";
fn_roof_array(:,i) = concatLabelPred == "truefalse";
tn_roof_array(:,i) = concatLabelPred == "falsefalse";

i = 3;
C = confusionmat((sub_label_roof==i),(sub_y_roof==1|sub_y_roof==2),'Order',[0 1]);
weighted_metric_roof(i,2) = C(2,2) ./ (C(2,2)+C(2,1));
weighted_metric_roof(i,3) = C(2,2) ./ (C(2,2)+C(1,2));
weighted_metric_roof(i,4) = (C(2,2)+C(1,1)) ./ (C(2,2)+C(2,1)+C(1,1)+C(1,2));
weighted_metric_roof(i,5) = 2.*C(2,2) ./ (2.*C(2,2)+C(1,2)+C(2,1));
concatLabelPred = string(sub_label_roof==i) + string(sub_y_roof==1|sub_y_roof==2);
tp_roof_array(:,i) = concatLabelPred == "truetrue";
fp_roof_array(:,i) = concatLabelPred == "falsetrue";
fn_roof_array(:,i) = concatLabelPred == "truefalse";
tn_roof_array(:,i) = concatLabelPred == "falsefalse";

i = 4;
C = confusionmat((sub_label_roof==i),(sub_y_roof==1|sub_y_roof==2),'Order',[0 1]);
weighted_metric_roof(i,2) = C(2,2) ./ (C(2,2)+C(2,1));
weighted_metric_roof(i,3) = C(2,2) ./ (C(2,2)+C(1,2));
weighted_metric_roof(i,4) = (C(2,2)+C(1,1)) ./ (C(2,2)+C(2,1)+C(1,1)+C(1,2));
weighted_metric_roof(i,5) = 2.*C(2,2) ./ (2.*C(2,2)+C(1,2)+C(2,1));
concatLabelPred = string(sub_label_roof==i) + string(sub_y_roof==2);
tp_roof_array(:,i) = concatLabelPred == "truetrue";
fp_roof_array(:,i) = concatLabelPred == "falsetrue";
fn_roof_array(:,i) = concatLabelPred == "truefalse";
tn_roof_array(:,i) = concatLabelPred == "falsefalse";

i = 5;
C = confusionmat((sub_label_roof==i),(sub_y_roof==2),'Order',[0 1]);
weighted_metric_roof(i,2) = C(2,2) ./ (C(2,2)+C(2,1));
weighted_metric_roof(i,3) = C(2,2) ./ (C(2,2)+C(1,2));
weighted_metric_roof(i,4) = (C(2,2)+C(1,1)) ./ (C(2,2)+C(2,1)+C(1,1)+C(1,2));
weighted_metric_roof(i,5) = 2.*C(2,2) ./ (2.*C(2,2)+C(1,2)+C(2,1));
concatLabelPred = string(sub_label_roof==i) + string(sub_y_roof==2);
tp_roof_array(:,i) = concatLabelPred == "truetrue";
fp_roof_array(:,i) = concatLabelPred == "falsetrue";
fn_roof_array(:,i) = concatLabelPred == "truefalse";
tn_roof_array(:,i) = concatLabelPred == "falsefalse";

i = 6;
C = confusionmat((sub_label_roof==i),(sub_y_roof==3),'Order',[0 1]);
weighted_metric_roof(i,2) = C(2,2) ./ (C(2,2)+C(2,1));
weighted_metric_roof(i,3) = C(2,2) ./ (C(2,2)+C(1,2));
weighted_metric_roof(i,4) = (C(2,2)+C(1,1)) ./ (C(2,2)+C(2,1)+C(1,1)+C(1,2));
weighted_metric_roof(i,5) = 2.*C(2,2) ./ (2.*C(2,2)+C(1,2)+C(2,1));
concatLabelPred = string(sub_label_roof==i) + string(sub_y_roof==3);
tp_roof_array(:,i) = concatLabelPred == "truetrue";
fp_roof_array(:,i) = concatLabelPred == "falsetrue";
fn_roof_array(:,i) = concatLabelPred == "truefalse";
tn_roof_array(:,i) = concatLabelPred == "falsefalse";


i = 7;
C = confusionmat((sub_label_roof==i),(sub_y_roof==1),'Order',[0 1]);
weighted_metric_roof(i,2) = C(2,2) ./ (C(2,2)+C(2,1));
weighted_metric_roof(i,3) = C(2,2) ./ (C(2,2)+C(1,2));
weighted_metric_roof(i,4) = (C(2,2)+C(1,1)) ./ (C(2,2)+C(2,1)+C(1,1)+C(1,2));
weighted_metric_roof(i,5) = 2.*C(2,2) ./ (2.*C(2,2)+C(1,2)+C(2,1));
concatLabelPred = string(sub_label_roof==i) + string(sub_y_roof==1);
tp_roof_array(:,i) = concatLabelPred == "truetrue";
fp_roof_array(:,i) = concatLabelPred == "falsetrue";
fn_roof_array(:,i) = concatLabelPred == "truefalse";
tn_roof_array(:,i) = concatLabelPred == "falsefalse";

% y_roof_tp = 0.*y_height;
% y_roof_fp = 0.*y_height;
% y_roof_fn = 0.*y_height;
% y_roof_tn = 0.*y_height;
% y_roof_base = 0.*y_height;
% y_roof_label_crop = 0.*y_height;
% y_roof_pred_crop = 0.*y_height;
% y_roof_tp(idx_roof) = sum(tp_roof_array,2);
% y_roof_fp(idx_roof) = sum(fp_roof_array,2);
% y_roof_fn(idx_roof) = sum(fn_roof_array,2);
% y_roof_tn(idx_roof) = sum(tn_roof_array,2);
% y_roof_base(idx_roof) = 1;
% y_roof_label_crop(idx_roof) = btype_label(idx_roof);
% y_roof_pred_crop(idx_roof) = y_roof(idx_roof);
% geotiffwrite("output/20240907_DC_411/y_roof_tp.tif",(y_roof_tp),maskR)
% geotiffwrite("output/20240907_DC_411/y_roof_fp.tif",(y_roof_fp),maskR)
% geotiffwrite("output/20240907_DC_411/y_roof_fn.tif",(y_roof_fn),maskR)
% geotiffwrite("output/20240907_DC_411/y_roof_tn.tif",(y_roof_tn),maskR)
% geotiffwrite("output/20240907_DC_411/y_roof_base.tif",(y_roof_base),maskR)
% geotiffwrite("output/20240907_DC_411/y_roof_label_crop.tif",(y_roof_label_crop),maskR)
% geotiffwrite("output/20240907_DC_411/y_roof_pred_crop.tif",(y_roof_pred_crop),maskR)


weighted_metric_roof(isnan(weighted_metric_roof)) = 0;
weighted_metric_roof(8,1) = sum(weighted_metric_roof(1:7,1));
weighted_metric_roof(8,2) = sum((weighted_metric_roof(1:7,1) ./ weighted_metric_roof(8,1)) .* ... 
                            weighted_metric_roof(1:7,2));
weighted_metric_roof(8,3) = sum((weighted_metric_roof(1:7,1) ./ weighted_metric_roof(8,1)) .* ... 
                            weighted_metric_roof(1:7,3));
weighted_metric_roof(8,4) = sum((weighted_metric_roof(1:7,1) ./ weighted_metric_roof(8,1)) .* ... 
                            weighted_metric_roof(1:7,4));
weighted_metric_roof(8,5) = sum((weighted_metric_roof(1:7,1) ./ weighted_metric_roof(8,1)) .* ... 
                            weighted_metric_roof(1:7,5));

%% y_wall
% 1 - Wood w/ mud
% 2 - Sun-dried bricks
% 3 - All non-durable materials
% 4 - Cement blocks
% 5 - Concrete
% 6 - Stones
% 7 - Timber
% 8 - Burnt bricks

tp_wall = (1./size(idx_wall,1)) .* sum(...
       (sub_label_wall==1) .* (sub_y_wall~=4&sub_y_wall~=5) + ...
       (sub_label_wall==2) .* (sub_y_wall==4|sub_y_wall==5|sub_y_wall==8) + ...
       (sub_label_wall==3) .* (sub_y_wall==4|sub_y_wall==5|sub_y_wall==8) + ...
       (sub_label_wall==4) .* (sub_y_wall==4|sub_y_wall==5) + ...
       (sub_label_wall==5) .* (sub_y_wall==4|sub_y_wall==5) + ...
       (sub_label_wall==6) .* (sub_y_wall==5) + ...
       (sub_label_wall==7) .* (sub_y_wall==4|sub_y_wall==5) ...
       );

% nsize, precision, recall, accuracy, and F1 score
weighted_metric_wall = zeros(7,5);
for i = 1:7
    weighted_metric_wall(i,1) = sum(sub_label_wall==i);
end

i = 1;
C = confusionmat((sub_label_wall==i),(sub_y_wall~=4&sub_y_wall~=5),'Order',[0 1]);
weighted_metric_wall(i,2) = C(2,2) ./ (C(2,2)+C(2,1));
weighted_metric_wall(i,3) = C(2,2) ./ (C(2,2)+C(1,2));
weighted_metric_wall(i,4) = (C(2,2)+C(1,1)) ./ (C(2,2)+C(2,1)+C(1,1)+C(1,2));
weighted_metric_wall(i,5) = 2.*C(2,2) ./ (2.*C(2,2)+C(1,2)+C(2,1));

i = 2;
C = confusionmat((sub_label_wall==i),(sub_y_wall==4|sub_y_wall==5|sub_y_wall==8),'Order',[0 1]);
weighted_metric_wall(i,2) = C(2,2) ./ (C(2,2)+C(2,1));
weighted_metric_wall(i,3) = C(2,2) ./ (C(2,2)+C(1,2));
weighted_metric_wall(i,4) = (C(2,2)+C(1,1)) ./ (C(2,2)+C(2,1)+C(1,1)+C(1,2));
weighted_metric_wall(i,5) = 2.*C(2,2) ./ (2.*C(2,2)+C(1,2)+C(2,1));

i = 3;
C = confusionmat((sub_label_wall==i),(sub_y_wall==4|sub_y_wall==5|sub_y_wall==8),'Order',[0 1]);
weighted_metric_wall(i,2) = C(2,2) ./ (C(2,2)+C(2,1));
weighted_metric_wall(i,3) = C(2,2) ./ (C(2,2)+C(1,2));
weighted_metric_wall(i,4) = (C(2,2)+C(1,1)) ./ (C(2,2)+C(2,1)+C(1,1)+C(1,2));
weighted_metric_wall(i,5) = 2.*C(2,2) ./ (2.*C(2,2)+C(1,2)+C(2,1));

i = 4;
C = confusionmat((sub_label_wall==i),(sub_y_wall==4|sub_y_wall==5),'Order',[0 1]);
weighted_metric_wall(i,2) = C(2,2) ./ (C(2,2)+C(2,1));
weighted_metric_wall(i,3) = C(2,2) ./ (C(2,2)+C(1,2));
weighted_metric_wall(i,4) = (C(2,2)+C(1,1)) ./ (C(2,2)+C(2,1)+C(1,1)+C(1,2));
weighted_metric_wall(i,5) = 2.*C(2,2) ./ (2.*C(2,2)+C(1,2)+C(2,1));

i = 5;
C = confusionmat((sub_label_wall==i),(sub_y_wall==4|sub_y_wall==5),'Order',[0 1]);
weighted_metric_wall(i,2) = C(2,2) ./ (C(2,2)+C(2,1));
weighted_metric_wall(i,3) = C(2,2) ./ (C(2,2)+C(1,2));
weighted_metric_wall(i,4) = (C(2,2)+C(1,1)) ./ (C(2,2)+C(2,1)+C(1,1)+C(1,2));
weighted_metric_wall(i,5) = 2.*C(2,2) ./ (2.*C(2,2)+C(1,2)+C(2,1));

i = 6;
C = confusionmat((sub_label_wall==i),(sub_y_wall==5),'Order',[0 1]);
weighted_metric_wall(i,2) = C(2,2) ./ (C(2,2)+C(2,1));
weighted_metric_wall(i,3) = C(2,2) ./ (C(2,2)+C(1,2));
weighted_metric_wall(i,4) = (C(2,2)+C(1,1)) ./ (C(2,2)+C(2,1)+C(1,1)+C(1,2));
weighted_metric_wall(i,5) = 2.*C(2,2) ./ (2.*C(2,2)+C(1,2)+C(2,1));

i = 7;
C = confusionmat((sub_label_wall==i),(sub_y_wall==4|sub_y_wall==5),'Order',[0 1]);
weighted_metric_wall(i,2) = C(2,2) ./ (C(2,2)+C(2,1));
weighted_metric_wall(i,3) = C(2,2) ./ (C(2,2)+C(1,2));
weighted_metric_wall(i,4) = (C(2,2)+C(1,1)) ./ (C(2,2)+C(2,1)+C(1,1)+C(1,2));
weighted_metric_wall(i,5) = 2.*C(2,2) ./ (2.*C(2,2)+C(1,2)+C(2,1));

weighted_metric_wall(isnan(weighted_metric_wall)) = 0;
weighted_metric_wall(8,1) = sum(weighted_metric_wall(1:7,1));
weighted_metric_wall(8,2) = sum((weighted_metric_wall(1:7,1) ./ weighted_metric_wall(8,1)) .* ... 
                            weighted_metric_wall(1:7,2));
weighted_metric_wall(8,3) = sum((weighted_metric_wall(1:7,1) ./ weighted_metric_wall(8,1)) .* ... 
                            weighted_metric_wall(1:7,3));
weighted_metric_wall(8,4) = sum((weighted_metric_wall(1:7,1) ./ weighted_metric_wall(8,1)) .* ... 
                            weighted_metric_wall(1:7,4));
weighted_metric_wall(8,5) = sum((weighted_metric_wall(1:7,1) ./ weighted_metric_wall(8,1)) .* ... 
                            weighted_metric_wall(1:7,5));