clc;clear;close all

% Path in Plato
Inpath='/datastore/GLOBALWATER/CommonData/Prcp_GMET/GSOD/data';
Outpath='/home/gut428/GapFill/Data/gsod';
Infile_mask='/home/gut428/GMET/NA_basic/MERIT_DEM/NA_DEM_010deg_trim.asc';
Outfile_gaugeAll=[Outpath,'/GaugeValidAll.mat'];
Outfile_gauge=[Outpath,'/GaugeValid.mat'];

% Basic settings
Overwrite=1; % 1: overwrite files in Outpath. Otherwise: skip existing files in Outpath.
BasicInfo.period_range=[1979,2018]; % [start year, end year]
BasicInfo.period_len=[8,100]; % the least/most number of years that are within period_range
BasicInfo.VarRead={'PRCP','MIN','MAX'};
BasicInfo.SnowfallEstimation=0; % 1: transfer weather code to snowfall; other values: don't transfer
BasicInfo.missingvalue=[99.99,9999.9,9999.9]; % filling values of GSOD
BasicInfo.scalefactor=[25.4, 1234, 1234, 1234]; % 1234 means from F to C
BasicInfo.VarOut={'Date(yyyymmdd)','Precipitation(mm)','Tmin(C)','Tmax(C)'};

% two ways for to extract rain gauges
% (1) lat/lon extent
% SR.seflag=1;
% SR.lat_range=[0,90]; % latitude range
% SR.lon_range=[-180,0]; % longitude range
% (2) spatial mask
BasicInfo.seflag=2;
BasicInfo.maskfile=Infile_mask;

% start reading
f_GSOD_read(Inpath,Outpath,Outfile_gaugeAll,Outfile_gauge,BasicInfo);
