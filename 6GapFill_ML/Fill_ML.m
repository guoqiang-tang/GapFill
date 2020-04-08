function Fill_ML(stnorder1,stnorder2,varnamein,LSTMflag)
% stnorder1=2539; stnorder2=32590;
% varnames={'tmax'};
% LSTMflag=0;
varnames={varnamein};
if ischar(stnorder1)
    stnorder1=str2double(stnorder1);
end
if ischar(stnorder2)
    stnorder2=str2double(stnorder2);
end
if ischar(LSTMflag)  %1: run lstm, other values: don't run lstm
    LSTMflag=str2double(LSTMflag);
end
stnorder=[stnorder1,stnorder2];
fprintf('Station order is %d--%d\n',stnorder1,stnorder2);

%0 Basic inputs
% % Plato
% FileGauge='/datastore/GLOBALWATER/CommonData/GapFill/RawStnData/AllGauge_QC.nc4';
% FileRea{1}='/datastore/GLOBALWATER/CommonData/GapFill/RawStnData/StnReanalysis/ERA5.nc4';
% FileRea{2}='/datastore/GLOBALWATER/CommonData/GapFill/RawStnData/StnReanalysis/JRA55.nc4';
% FileRea{3}='/datastore/GLOBALWATER/CommonData/GapFill/RawStnData/StnReanalysis/MERRA2.nc4';
% FileTLRin='/datastore/GLOBALWATER/CommonData/GapFill/AuxiliaryData/MERRA2_TLR.nc4';
% % output files
% Outpath='/home/gut428/GapFill/Data';
% FileTLRout='/datastore/GLOBALWATER/CommonData/GapFill/AuxiliaryData/MERRA2_TLR_Match_Gauge.mat';

% Cedar
FileGauge='../AllGauge_QC.nc4';
FileRea{1}='../StnReanalysis/ERA5.nc4';
FileRea{2}='../StnReanalysis/JRA55.nc4';
FileRea{3}='../StnReanalysis/MERRA2.nc4';
FileTLRin='../AuxiliaryData/MERRA2_TLR.nc4';
% output files
Outpath='../FillData_ML';
FileTLRout='../AuxiliaryData/MERRA2_TLR_Match_Gauge.mat';


% % mac path
% FileGauge='~/Research/GapFill/AllGauge_QC.nc4';
% FileRea{1}='~/Research/GapFill/ERA5.nc4';
% FileRea{2}='~/Research/GapFill/JRA55.nc4';
% FileRea{3}='~/Research/GapFill/MERRA2.nc4';
% FileTLRin='/datastore/GLOBALWATER/CommonData/GapFill/AuxiliaryData/MERRA2_TLR.nc4';
% % output files
% Outpath='~/Research/GapFill';
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
nday=length(date);
nstn=size(LLE,1);

%3 Calculate the CC between station data and reanalysis data
CCreaall=cell(length(varnames),1);
for vv=1:length(varnames)
    varvv=varnames{vv};
    filevv=['CCrea_',varvv,'.mat'];
    if exist(filevv,'file')
        load(filevv,'CCrea');
    else
        CCrea=f_CCrea(FileGauge,FileRea,varvv);
        save(filevv,'CCrea');
    end
    CCreaall{vv}=CCrea;
    clear CCrea
end

%4 for each station, calculate the index nearest neighbor stations
%this step takes much time
IDne_num=cell(length(varnames),1);
for vv=1:length(varnames)
    varvv=varnames{vv};
    CCreavv=CCreaall{vv};
    filevv=['IDne_info_',varvv,'.mat'];
    IDne_numv=f_findnear(FileGauge,varvv,radius,leastne,Validnum,filevv,CCreavv);
    IDne_num{vv}=IDne_numv;
    clear IDne_numv
end

%5 extract temperate lapse rate for each station
StnTLR=f_GaugeTLR(FileTLRin,FileTLRout,LLE,date);
StnTLR=single(StnTLR);

%6 for each station, fill the gap
for vv=1:length(varnames)
    OutpathFillvv=[Outpath,'/ML_',varnames{vv}];
    if ~exist(OutpathFillvv,'dir'); mkdir(OutpathFillvv); end
    % gap filling and save them as individual files
    varvv=varnames{vv};
    f_FillGap_ML(OutpathFillvv,FileGauge,FileRea,IDne_num{vv},varvv,Validnum,StnTLR,LSTMflag,stnorder);
end

end
