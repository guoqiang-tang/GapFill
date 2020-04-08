clc;clear;close
% Path in Plato
Inpath='/datastore/GLOBALWATER/CommonData/Prcp_GMET/Mexico_data';
Outpath='/home/gut428/GapFill/Data/mexico';
Infile_mask='/home/gut428/GMET/NA_basic/MERIT_DEM/NA_DEM_010deg_trim.asc';
Outfile_gaugeAll=[Outpath,'/GaugeValid.mat'];

% Basic settings
BasicInfo.period_range=[1979,2018]; % [start year, end year]
BasicInfo.period_len=[8,100]; % the least number of years that are within period_range
BasicInfo.VarRead={'prcp','tmin','tmax'};
BasicInfo.VarOut={'Date(yyyymmdd)','Precipitation(mm)','Tmin(C)','Tmax(C)'};

% two ways for to extract rain gauges
% (1) lat/lon extent
% SR.seflag=1;
% SR.lat_range=[0,90]; % latitude range
% SR.lon_range=[-180,0]; % longitude range
% (2) spatial mask
BasicInfo.seflag=2;
BasicInfo.maskfile=Infile_mask;

f_Mexico_read(Inpath,Outpath,Outfile_gaugeAll,BasicInfo);