%% initialize
clear, clc, close
cd '/Users/joshuadimasaka/Desktop/PhD/GitHub/rwa'

%% modelCC.m - constrained K-means clustering (Bradley et al. 2000)
[y_height, ~] = readgeoraster("output/20240829_DR_AE/y_height.tif");
[y_roof, ~] = readgeoraster("output/20240829_DR_AE/y_roof.tif");
[y_wall, ~] = readgeoraster("output/20240829_DR_AE/y_wall.tif");
[label_height, ~] = readgeoraster("data/BLDG/BACHOFER DLR/EO4Kigali_2015_bheight.tif");
[btype_label, ~] = readgeoraster("data/BLDG/BACHOFER DLR/EO4Kigali_2015_btype.tif");

%% roof census
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
% 2: Building in block structure/large courtyard buildings
%       y_roof: 1
% 3: Bungalow-type buildings
%       y_roof: 1, 2
% 4: Villa-type buildings
%       y_roof: 2
% 5: Low to mid-rise multi-unit buildings
%       y_roof: 2
% 6: High-rise buildings
%       y_roof: 3
% 7: Halls
%       y_roof: 1
% 8: Special structures
%       y_roof: na
%       y_wall: na
% 9: Construction sites
%       y_roof: na
%       y_wall: na

idx_roof = find((btype_label>0 & btype_label<=7) & y_roof>0);
sub_label_roof = btype_label(idx_roof);
sub_y_roof = y_roof(idx_roof);
