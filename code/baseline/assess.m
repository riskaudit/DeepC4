clear, clc, close

cd '/Users/joshuadimasaka/Desktop/PhD/GitHub/rwa'

data = readtable(['/Users/joshuadimasaka/Desktop/PhD/GitHub/' ...
    'riskaudit/data/groundtruth/GLOBAL_EXPOSURE_MODEL_GEM_2023/' ...
    'Africa_v2023.1.0/Exposure_Res_Rwanda.csv']);

province = data.NAME_1;
setlType = data.SETTLEMENT;
uniqTax = data.TAXONOMY;
macroTax = data.macro_taxonomy;
codeLevel = data.code_quality;
height = data.height_class;
nDwell = data.DWELLINGS;
nBldg = data.BUILDINGS;
nPopl = data.OCCUPANTS_PER_ASSET;

%% Check population
% https://hub.worldpop.org/geodata/summary?id=49708
[m, mR] = readgeoraster("rwa_ppp_2020_UNadj_constrained.tif");
% sum(m(m~=-99999),"all")
% sum(nPopl)
% comment = there's missing 10,803 population counts in the processed GEM
% data, which is equivalent to 8.35% lower.
% GEM population count = 12,941,405
% UNDP population count = 12,952,208
% https://population.un.org/wpp/Publications/Files/WPP2019_Volume-I_Comprehensive-Tables.pdf

%% Check urban-rural ratio
sum(nPopl(setlType=="Urban")) % 2,251,635
sum(nPopl(setlType=="Rural")) % 10,689,770
% Rural / Urban Ratio = 82.6 : 17.4
% 
% 2018 is urban percentage is 17.2.
% (https://population.un.org/wup/Publications/Files/WUP2018-Report.pdf)

%% Population -> number of Dwellings
% https://globaldatalab.org/areadata/table/hhsize/RWA/?levels=1+2+4
% divide subnational pop with national hh size (rural & urban)
% national rural hh size = 4.39
% national urban hh size = 4.07
% 
% {'Eastern Province' }
% {'Kigali City'      }
% {'Northern Province'}
% {'Southern Province'}
% {'Western Province' }
uniq_province = unique(province);
subnatl_urban_rural_dwellings = zeros(numel(uniq_province),2); 
for i = 1:numel(uniq_province)
    subnatl_urban_rural_dwellings(i,1) = sum(nPopl(setlType=="Urban" & ...
        province==string(uniq_province(i)) )) ./ 4.07;
    subnatl_urban_rural_dwellings(i,2) = sum(nPopl(setlType=="Rural" & ...
        province==string(uniq_province(i)) )) ./ 4.39;
end
sum(subnatl_urban_rural_dwellings, "all") %298,825 (-8% lower)
sum(nDwell) % 323,0241


