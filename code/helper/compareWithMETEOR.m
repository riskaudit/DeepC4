close, clc, clear all
cd '/Users/joshuadimasaka/Desktop/PhD/GitHub/DeepC4'

%% Load METEOR data
[nbldg_A, R] = readgeoraster('data/METEOR/RWA_nbldg_A.tif');
[nbldg_C3L, ~] = readgeoraster('data/METEOR/RWA_nbldg_C3L.tif');
[nbldg_C3M, ~] = readgeoraster('data/METEOR/RWA_nbldg_C3M.tif');
[nbldg_INF, ~] = readgeoraster('data/METEOR/RWA_nbldg_INF.tif');
[nbldg_RS, ~] = readgeoraster('data/METEOR/RWA_nbldg_RS.tif');
[nbldg_UCB, ~] = readgeoraster('data/METEOR/RWA_nbldg_UCB.tif');
[nbldg_UFB, ~] = readgeoraster('data/METEOR/RWA_nbldg_UFB.tif');
[nbldg_W, ~] = readgeoraster('data/METEOR/RWA_nbldg_W.tif');
[nbldg_W5, ~] = readgeoraster('data/METEOR/RWA_nbldg_W5.tif');

%% Load DeepC4 outputs
[y_mt_01,~] = readgeoraster("output/20241111_DeepC4/global/projectedintoMETEOR/y_macrotaxo_1.tif");
[y_mt_02,~] = readgeoraster("output/20241111_DeepC4/global/projectedintoMETEOR/y_macrotaxo_2.tif");
[y_mt_03,~] = readgeoraster("output/20241111_DeepC4/global/projectedintoMETEOR/y_macrotaxo_3.tif");
[y_mt_04,~] = readgeoraster("output/20241111_DeepC4/global/projectedintoMETEOR/y_macrotaxo_4.tif");
[y_mt_05,~] = readgeoraster("output/20241111_DeepC4/global/projectedintoMETEOR/y_macrotaxo_5.tif");
[y_mt_06,~] = readgeoraster("output/20241111_DeepC4/global/projectedintoMETEOR/y_macrotaxo_6.tif");
[y_mt_07,~] = readgeoraster("output/20241111_DeepC4/global/projectedintoMETEOR/y_macrotaxo_7.tif");
[y_mt_08,~] = readgeoraster("output/20241111_DeepC4/global/projectedintoMETEOR/y_macrotaxo_8.tif");
[y_mt_09,~] = readgeoraster("output/20241111_DeepC4/global/projectedintoMETEOR/y_macrotaxo_9.tif");
[y_mt_10,~] = readgeoraster("output/20241111_DeepC4/global/projectedintoMETEOR/y_macrotaxo_10.tif");
[y_mt_11,~] = readgeoraster("output/20241111_DeepC4/global/projectedintoMETEOR/y_macrotaxo_11.tif");
[y_mt_12,~] = readgeoraster("output/20241111_DeepC4/global/projectedintoMETEOR/y_macrotaxo_12.tif");
[y_mt_13,~] = readgeoraster("output/20241111_DeepC4/global/projectedintoMETEOR/y_macrotaxo_13.tif");
[y_mt_14,~] = readgeoraster("output/20241111_DeepC4/global/projectedintoMETEOR/y_macrotaxo_14.tif");
[y_mt_15,~] = readgeoraster("output/20241111_DeepC4/global/projectedintoMETEOR/y_macrotaxo_15.tif");
[y_mt_16,~] = readgeoraster("output/20241111_DeepC4/global/projectedintoMETEOR/y_macrotaxo_16.tif");

%% METEOR and DeepC4 Relatonship

% y_macrotaxo
% 1	    #4848ea		CR/LFINF - reinforced concrete with infill walls
% 2	    #1c62da		CR/LWAL - reinforced concrete with shear walls
% 3	    #cf79a3		MATO - other material
% 4	    #34d4c1		MCF+CB/LWAL - confined concrete block masonry with shear walls
% 5	    #6ec953		MCF+CL/LWAL - confined clay brick masonry with shear walls
% 6	    #c480d9	    MUR+ADO+MOC/LWAL - unreinforced adobe block masonry with cement mortar and shear walls
% 7	    #e09410		MUR+ADO/LWAL - unreinforced adobe block masonry with shear walls
% 8	    #c97680		MUR+CB/LWAL - unreinforced concrete block masonry with shear walls
% 9	    #885ad2	    MUR+CL+MOC/LWAL - unreinforced clay brick masonry with cement mortar and shear walls
% 10	#a7ee34		MUR+CL/LWAL - unreinforced clay brick masonry with shear walls
% 11	#ed6fda		MUR+STDRE+MOC/LWAL - unreinforced dressed stone masonry with cement mortar and shear walls
% 12	#32ee4b		MUR+STDRE/LWAL - unreinforced dressed stone masonry with shear walls
% 13	#1aa9d9		MUR+STRUB+MOC/LWAL - unreinforced masonry rubble stone with cement mortar and shear walls
% 14	#e19073		MUR+STRUB/LWAL - unreinforced masonry rubble stone with shear walls
% 15	#e5e842		W+WWD/LWAL - wattle and daub with shear walls
% 16	#73d1a3		W/LWAL - wood with shear walls


%% COMPARISON in terms of TOTAL BUILDING COUNT PER VULNERABILITY TYPE

% All
% All
A = sum(nbldg_A,'all') + ...
    sum(nbldg_C3L,'all') + ...
    sum(nbldg_C3M,'all') + ...
    sum(nbldg_INF,'all') + ...
    sum(nbldg_RS,'all') + ...
    sum(nbldg_UCB,'all') + ...
    sum(nbldg_UFB,'all') + ...
    sum(nbldg_W,'all') + ...
    sum(nbldg_W5,'all');
B = sum(y_mt_01,'all') + sum(y_mt_02,'all') + ...
    sum(y_mt_03,'all') + sum(y_mt_04,'all') + ...
    sum(y_mt_05,'all') + sum(y_mt_06,'all') + ...
    sum(y_mt_07,'all') + sum(y_mt_08,'all') + ...
    sum(y_mt_09,'all') + sum(y_mt_10,'all') + ...
    sum(y_mt_11,'all') + sum(y_mt_12,'all') + ...
    sum(y_mt_13,'all') + sum(y_mt_14,'all') + ...
    sum(y_mt_15,'all') + sum(y_mt_16,'all');
B = B*100/60
P = 2.*abs(A-B)./(A+B)

% A (Adobe blocks (unbaked sundried mud block) walls)
% y_macrotaxo: 5, 6, 7
A = sum(nbldg_A,'all')
B = sum(y_mt_05,'all') + sum(y_mt_06,'all') + sum(y_mt_07,'all')
B = B*100/60
P = 2.*abs(A-B)./(A+B)


% C3L + C3M (Nonductile reinforced concrete frame with masonry infill walls low-rise/mid-rise)
% y_macrotaxo: 1, 2, 4 
A = sum(nbldg_C3L,'all') + sum(nbldg_C3M,'all')
B = sum(y_mt_01,'all') + sum(y_mt_02,'all') + sum(y_mt_04,'all')
B = B*100/60
P = 2.*abs(A-B)./(A+B)

% INF (Informal constructions)
% y_macrotaxo: 3
A = sum(nbldg_INF,'all') 
B = sum(y_mt_03,'all') 
B = B*100/60
P = 2.*abs(A-B)./(A+B)

% RS (Rubble stone (field stone) masonry)
% y_macrotaxo: 11, 12, 13, 14
% y_macrotaxo: 3
A = sum(nbldg_RS,'all') 
B = sum(y_mt_11,'all') + sum(y_mt_12,'all') + sum(y_mt_13,'all') + sum(y_mt_14,'all') 
B = B*100/60
P = 2.*abs(A-B)./(A+B)

% UCB (Concrete block unreinforced masonry with lime or cement mortar)
% y_macrotaxo: 8, 
A = sum(nbldg_UCB,'all') 
B = sum(y_mt_08,'all') 
B = B*100/60
P = 2.*abs(A-B)./(A+B)

% UFB (Unreinforced fired brick masonry)
% y_macrotaxo: 9, 10
A = sum(nbldg_UFB,'all') 
B = sum(y_mt_09,'all') + sum(y_mt_10,'all') 
B = B*100/60
P = 2.*abs(A-B)./(A+B)

% W (Wood)
% y_macrotaxo: 16
A = sum(nbldg_W,'all') 
B = sum(y_mt_16,'all') 
B = B*100/60
P = 2.*abs(A-B)./(A+B)

% W5 (Wattle and Daub (Walls with bamboo/light timber log/reed mesh and post)
% y_macrotaxo: 15
A = sum(nbldg_W5,'all') 
B = sum(y_mt_15,'all')
B = B*100/60
P = 2.*abs(A-B)./(A+B)


%% COMPARISON in terms of TOTAL BUILDING COUNT PER VULNERABILITY TYPE
y_roof = readgeoraster("output/20241025_DeepGC4/global/map/y_roof.tif");