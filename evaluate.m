%% Evaluate several methodologies and variants of deep clustering approach
% 
% Our evaluation can be limited because our prediction is for the year 2022
% whereas the high-resolution building-level data we consider to be 
% accurate is the work done by Bachoder of DLR for the year 2015. 
%
% List of approaches:
% 1. modelCC.m - constrained K-means clustering (Bradley et al. 2000)
% 2. 

%% initialize
clear, clc, close
cd '/Users/joshuadimasaka/Desktop/PhD/GitHub/rwa'

%% modelCC.m - constrained K-means clustering (Bradley et al. 2000)
[pred, ~] = readgeoraster("output/20240801/y_height.tif");
[label, ~] = readgeoraster("data/BLDG/BACHOFER DLR/EO4Kigali_2015_bheight.tif");
