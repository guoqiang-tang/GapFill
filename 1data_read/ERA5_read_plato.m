clc;clear;close

% Plato path
Inpath={'/datastore/GLOBALWATER/CommonData/Prcp_GMET/ERA5/tp',... % precipitation path
    '/datastore/GLOBALWATER/CommonData/Prcp_GMET/ERA5TSF',...  % snowfall path
    '/datastore/GLOBALWATER/CommonData/Prcp_GMET/ERA5TSF',...  % Tmin
    '/datastore/GLOBALWATER/CommonData/Prcp_GMET/ERA5TSF',...  % Tmax
    '/datastore/GLOBALWATER/CommonData/Prcp_GMET/ERA5TSF'};    % Tmean
FileDEMLow='../DEM_process/ERA5_DEM2.mat';
FileDEMHigh='/home/gut428/GMET/NA_basic/MERIT_DEM/NA_DEM_010deg_trim.asc';
TLRfile='../MERRA2_TLR/MERRA2_TLR.mat';

Outpath={'/home/gut428/ERA5_YearNC2',...
    '/home/gut428/ERA5_YearNC2',...
    '/home/gut428/ERA5_YearNC2',...
    '/home/gut428/ERA5_YearNC2',...
    '/home/gut428/ERA5_YearNC2'};
for i=1:length(Outpath)
   if ~exist(Outpath{i},'dir')
      mkdir(Outpath{i}); 
   end
end

% basic information of target region
BasicInfo.tXll=-50;  % top right
BasicInfo.tYll=85;
BasicInfo.Xll=-180;   % bottom left
BasicInfo.Yll=5;
BasicInfo.cellsize=0.1;  % target resolution
% year=[1979,2018]; % start and end year
DataInfo.prefix={'ERA5_','ERA5_','ERA5_','ERA5_','ERA5_'}; % file name prefix
DataInfo.suffix={'','','','',''}; % file name suffix
DataInfo.varname={'tp','sf','mn2t','mx2t','t2m'}; % variable to read
DataInfo.imethod={'linear','linear','lapserate','lapserate','lapserate'}; % interpolation method
DataInfo.prefixout={'ERA5_prcp_','ERA5_snow_','ERA5_tmin_','ERA5_tmax_','ERA5_tmean_'}; % prefix for output file

% parfor year=1980:2018
for year=1980:2018
    f_ERA5_read(Inpath,FileDEMLow,FileDEMHigh,Outpath,year,BasicInfo,DataInfo,TLRfile);
end
