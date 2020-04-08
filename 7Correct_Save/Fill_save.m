function Fill_save(stnorder1,stnorder2,varnamein,Overwrite)
% stnorder1=1; stnorder2=32590;
% varvv='tmin';
varvv=varnamein;
if ischar(stnorder1)
    stnorder1=str2double(stnorder1);
end
if ischar(stnorder2)
    stnorder2=str2double(stnorder2);
end
if ischar(Overwrite)
    Overwrite=str2double(Overwrite);
end
stnorder=[stnorder1,stnorder2];
fprintf('Station order is %d--%d\n',stnorder1,stnorder2);


% save the estimated SCD in uniform format
% 1. One uniform netcdf file
% 2. Separate file for each station

% %1. Inpath setting
% Plato
Inpath={'/datastore/GLOBALWATER/CommonData/GapFill_new/RawFill/DOY_prcp';...
    '/datastore/GLOBALWATER/CommonData/GapFill_new/RawFill/DOY_tmin';...
    '/datastore/GLOBALWATER/CommonData/GapFill_new/RawFill/DOY_tmax'};
% Inpath={'/datastore/GLOBALWATER/CommonData/GapFill_new/RawFill/DOY_prcp';...
%     '/home/gut428/GapFill/Data/DOY_tmin';...
%     '/home/gut428/GapFill/Data/DOY_tmax'};
Inpath_ML={'/datastore/GLOBALWATER/CommonData/GapFill_new/RawFill/ML_prcp';...
    '/datastore/GLOBALWATER/CommonData/GapFill_new/RawFill/ML_tmin';...
    '/datastore/GLOBALWATER/CommonData/GapFill_new/RawFill/ML_tmax'};
PathMerge='/home/gut428/GapFill/Data/GGEM_merge';
FileGauge='/datastore/GLOBALWATER/CommonData/GapFill/RawStnData/AllGauge_QC.nc4';
FileTLR='/datastore/GLOBALWATER/CommonData/GapFill/AuxiliaryData/MERRA2_TLR_Match_Gauge.mat';

varall={'prcp','tmin','tmax'};
% Overwrite=1; % 0: not overwrite; 1: overwrite

OutPath='/home/gut428/GapFill/Data/SCD_NorthAmerica';
if ~exist(OutPath,'dir'); mkdir(OutPath); end

%3. save data
indvv=find(ismember(varall,varvv));
Inpathvv=Inpath{indvv};
Inpathvv_ML=Inpath_ML{indvv};
% save: one nc4 file for one station
f_SaveSCD(Inpathvv,Inpathvv_ML,FileGauge,PathMerge,OutPath,FileTLR,varvv,Overwrite,stnorder);
end