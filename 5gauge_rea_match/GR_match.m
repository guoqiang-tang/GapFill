% according to the locations of rain gauges, extract reanalysis
% precipitation
clc;clear;close all
% plato path
Infile_gauge='/datastore/GLOBALWATER/CommonData/GapFill_new/RawStnData/AllGauge_QC.nc4';
FileDEMHigh='/datastore/GLOBALWATER/CommonData/GapFill_new/AuxiliaryData/NA_DEM_010deg_trim.asc';
FileTLR='/datastore/GLOBALWATER/CommonData/GapFill_new/AuxiliaryData/MERRA2_TLR.mat';
Inpath_rea={'/datastore/GLOBALWATER/CommonData/Prcp_GMET/ERA5_YearNC',...
    '/datastore/GLOBALWATER/CommonData/Prcp_GMET/JRA55_YearNC',....
    '/datastore/GLOBALWATER/CommonData/Prcp_GMET/MERRA2_YearNC'};
Outpath='/home/gut428/GapFill/Data/Reanalysis';

% mac path
% Inpath_gauge='/Users/localuser/Research/DataNew/AllGauge';
% Infile_gauge=[Inpath_gauge,'/GaugeInfo.mat'];
% FileDEMHigh='/Users/localuser/Google Drive/Research-Fields/2019 stochastic precipitation merging/NA asc/na_ele_010.asc';
% Inpath_rea={'/Volumes/Backup Plus/Data/ERA5/North America/test',...
%     '/Volumes/Backup Plus/Data/JRA-55/test',....
%     '/Volumes/Backup Plus/Data/MERRA2/test'};
% Outpath='/Volumes/Backup Plus';

prefixall{1}={'ERA5_prcp_','ERA5_tmin_','ERA5_tmax_','ERA5_tmean_'};
prefixall{2}={'JRA55_prcp_','JRA55_tmin_','JRA55_tmax_','JRA55_tmean_'};
prefixall{3}={'MERRA2_prcp_','MERRA2_tmin_','MERRA2_tmax_','MERRA2_tmean_'};
Vars={'prcp','tmin','tmax','tmean'};
prefixout={'ERA5','JRA55','MERRA2'};

years=1979;  % if the date is not complete, fill it using nan
yeare=2018;

date=datenum(years,1,1):datenum(yeare,12,31); date=date';
date=datestr(date,'yyyymmdd');
date=mat2cell(date,ones(length(date),1),8);
date=str2double(date);
% basic info of the study area and the extracted reanalysis data
DEMRea=arcgridread_tgq(FileDEMHigh);

tXll=DEMRea.xll2;  % top right
tYll=DEMRea.yll2;
Xll=DEMRea.xll;   % bottom left
Yll=DEMRea.yll;
cellsize=DEMRea.cellsize;
nrows=(tYll-Yll)/cellsize;
ncols=(tXll-Xll)/cellsize;
BasicInfo=[Xll,Yll,tXll,tYll,cellsize];
DEMRea=DEMRea.mask;

% load gauge info
ID=ncread(Infile_gauge,'ID');
LLE=ncread(Infile_gauge,'LLE');
rowg=floor((tYll-LLE(:,1))/cellsize)+1;
colg=floor((LLE(:,2)-Xll)/cellsize)+1;
indin=(rowg>=1&rowg<=nrows&colg>=1&colg<=ncols);

ID=ID(indin,:);
LLE=LLE(indin,:);
rowg=rowg(indin);
colg=colg(indin);
indexg=sub2ind([nrows,ncols],rowg,colg);
DEM_rea=DEMRea(indexg);

% extract temperature lapse rate that corresponding to each station
TLR_rea=f_TLR_extract(FileTLR,indexg,date);

%% get the matched data
for i=1:length(Inpath_rea)
    prefix=prefixall{i};
    Outfile=[Outpath,'/',prefixout{i},'.nc4'];
    if exist(Outfile,'file')
        continue;
    end
    for j=1:length(prefix)
        fprintf('%s--%s\n',prefixout{i},prefix{j});
        commj=[Vars{j},'=f_reanalysis_extract(Inpath_rea{i},prefix{j},rowg,colg,years,yeare);'];
        eval(commj);
    end
    
    % use the temperature lapse rate to adjust tmin tmax tmean
    tmin=f_TLRadjust(tmin,DEM_rea,LLE,TLR_rea);
    tmax=f_TLRadjust(tmax,DEM_rea,LLE,TLR_rea);
    tmean=f_TLRadjust(tmean,DEM_rea,LLE,TLR_rea);
    
    f_save_rea(Outfile,prcp,tmin,tmax,tmean,ID,LLE,date,BasicInfo,DEM_rea,TLR_rea);
end