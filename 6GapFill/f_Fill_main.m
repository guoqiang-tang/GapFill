function f_Fill_main(stnorder1,stnorder2,varnamein)
% stnorder1=1; stnorder2=32590;
% varnames={'prcp'};
if ischar(stnorder1)
    stnorder1=str2double(stnorder1);
end
if ischar(stnorder2)
    stnorder2=str2double(stnorder2);
end
stnorder=[stnorder1,stnorder2];
varnames={varnamein};
fprintf('Station order is %d--%d\n',stnorder1,stnorder2);

%0 Basic inputs
% Plato
FileGauge='/datastore/GLOBALWATER/CommonData/GapFill/RawStnData/AllGauge_QC.nc4';
FileRea{1}='/datastore/GLOBALWATER/CommonData/GapFill/RawStnData/StnReanalysis/ERA5.nc4';
FileRea{2}='/datastore/GLOBALWATER/CommonData/GapFill/RawStnData/StnReanalysis/JRA55.nc4';
FileRea{3}='/datastore/GLOBALWATER/CommonData/GapFill/RawStnData/StnReanalysis/MERRA2.nc4';
FileTLRin='/datastore/GLOBALWATER/CommonData/GapFill/AuxiliaryData/MERRA2_TLR.nc4';

% output files
Outpath='/home/gut428/GapFill/Data';
FileTLRout='/datastore/GLOBALWATER/CommonData/GapFill/AuxiliaryData/MERRA2_TLR_Match_Gauge.mat';

% mac
% FileGauge='~/Research/GapFill/AllGauge_QC.nc4';
% FileRea{1}='~/Research/GapFill/ERA5.nc4';
% FileRea{2}='~/Research/GapFill/JRA55.nc4';
% FileRea{3}='~/Research/GapFill/MERRA2.nc4';
% FileTLRin='~/Research/GapFill/MERRA2_TLR.nc4';
% 
% % output files
% Outpath='/home/gut428/GapFill/Data';
% FileTLRout='~/Research/GapFill/MERRA2_TLR_Match_Gauge.mat';


%1 Basic settings
Validnum.all=3000;  % the least number of valid samples for each station and each variable to be included in the gap filling process
Validnum.month=200;  % the least number of valid samples for each month
radius=200; % searching the nearest neightboring stations within the radius
yyrange=[1979,2018]; % fill gap between the year range
leastne=1; % the least number of nearest gauges that is required to fill the target gauge

%2 Read basic information of all rain gauges
%use the info from the final QC folder
LLE=ncread(FileGauge,'LLE');
date=ncread(FileGauge,'date');

%3 for each station, calculate the index nearest neighbor stations
%this step takes much time
IDne_numDOY=cell(length(varnames),1);
IDne_ccDOY=cell(length(varnames),1);
IDne_distDOY=cell(length(varnames),1);
for vv=1:length(varnames)
    varvv=varnames{vv};
%     filevv=['~/Research/GapFill/IDneDOY_info_',varvv,'.mat'];
    filevv=['IDneDOY_info_',varvv,'.mat'];
    [IDne_numv,IDne_ccv,IDne_distv]=f_findnear_DOY(FileGauge,varvv,radius,leastne,Validnum,filevv,stnorder);
    IDne_numDOY{vv}=IDne_numv;
    IDne_ccDOY{vv}=IDne_ccv;
    IDne_distDOY{vv}=IDne_distv;
end

%4 extract temperate lapse rate for each station
StnTLR=f_GaugeTLR(FileTLRin,FileTLRout,LLE,date);

%5 for each station, fill the gap
for vv=1:length(varnames)
    OutpathFillvv=[Outpath,'/DOY_',varnames{vv}];
    if ~exist(OutpathFillvv,'dir'); mkdir(OutpathFillvv); end
    % gap filling and save them as individual files
    IDne_numvv=IDne_numDOY{vv}; IDne_ccvv=IDne_ccDOY{vv}; IDne_distvv=IDne_distDOY{vv}; varvv=varnames{vv};
    f_FillGap_DOY(OutpathFillvv,FileGauge,FileRea,IDne_numvv,IDne_ccvv,IDne_distvv,varvv,Validnum,StnTLR,stnorder);
end

end