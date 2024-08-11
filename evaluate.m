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
[height_pred, ~] = readgeoraster("output/20240811_33sectors/y_height.tif");
[height_label, ~] = readgeoraster("data/BLDG/BACHOFER DLR/EO4Kigali_2015_bheight.tif");

idx = find(height_label> 0 & height_pred>0);
subheight_label = height_label(idx);
subheight_pred = height_pred(idx);

% height_label 
% (0,3]     1st                 100% x H:1
% (3,5.5]   2nd                 100% x H:2
% (5.5,8]   3rd                 50% x H:3         + 50% x HBET:3-6
% (8,10]    4th                 50% x HBET:3-6    + 50% x HBET:4-7
% (10,14]   5th, 6th            50% x HBET:3-6    + 50% x HBET:4-7
% (14,16]   7th                 100% x HBET:4-7
% (16,inf]  8th                 100% x HBET: 8+

ACC = (1./size(idx,1)) .* sum(...
       ((subheight_label>0)&(subheight_label<=3)) .* (subheight_pred==1) + ...
       ((subheight_label>3)&(subheight_label<=5.5)) .* (subheight_pred==2) + ...
       ((subheight_label>5.5)&(subheight_label<=8)) .* (subheight_pred==3|subheight_pred==4) + ...
       ((subheight_label>8)&(subheight_label<=10)) .* (subheight_pred==4|subheight_pred==5) + ...
       ((subheight_label>10)&(subheight_label<=14)) .* (subheight_pred==4|subheight_pred==5) + ...
       ((subheight_label>14)&(subheight_label<=16)) .* (subheight_pred==5) + ...
       ((subheight_label>16)) .* (subheight_pred==6) ...
       )

% [btype_label, ~] = readgeoraster("data/BLDG/BACHOFER DLR/EO4Kigali_2015_btype.tif");

% btype_label 
% 1: Rudimentary, basic or unplanned buildings
%       y_roof: 1, 2, 6, 8, 9
%       y_wall: 
% 2: Building in block structure/large courtyard buildings
%       y_roof: 1, 2, 6, 8, 9
%       y_wall: 
% 3: Bungalow-type buildings
%       y_roof: 
%       y_wall: 
% 4: Villa-type buildings
%       y_roof: 
%       y_wall: 
% 5: Low to mid-rise multi-unit buildings
%       y_roof: 
%       y_wall: 
% 6: High-rise buildings
%       y_roof: 5
%       y_wall: 7
% 7: Halls
%       y_roof: 
%       y_wall: 
% 8: Special structures
%       y_roof: 
%       y_wall: 
% 9: Construction sites
%       y_roof: 
%       y_wall: 




