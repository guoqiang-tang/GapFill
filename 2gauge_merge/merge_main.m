% three step
% 1. merge ECCC, mexico with GHCN-D for the same stations.
% 2. basic quality control, produce a netcdf file
% that contains all station data from all sources with their quality flag
% 3. merge stations with same locations

clc;clear;close all
Inpath={'/datastore/GLOBALWATER/CommonData/GapFill_new/RawStnData/ghcn-d',...
    '/datastore/GLOBALWATER/CommonData/GapFill_new/RawStnData/gsod',...
    '/datastore/GLOBALWATER/CommonData/GapFill_new/RawStnData/eccc',...
    '/datastore/GLOBALWATER/CommonData/GapFill_new/RawStnData/mexico'};
SourceName={'GHCN-D','GSOD','ECCC','Mexico'};
Outpath='/home/gut428/GapFill/Data';

%% Step1: merge ECCC, mexico with GHCN-D for the same stations
% flag=1: valid station; flag=0: don't use
outfile1='f_IDmerge.mat';
Inpath_GHCN=Inpath{1}; Inpath_ECCC=Inpath{3}; Inpath_Mexico=Inpath{4};
[ID_ghcn,ID_eccc,ID_mexico,flag_ghcn,flag_eccc,flag_mexico]=f_IDmerge(Inpath_GHCN,Inpath_ECCC,Inpath_Mexico,outfile1);

%% Step2: basic quality control to reduce the useless stations
% flag=-1: don't use
outfile2='f_IDBQC.mat';
BQC.validsample=2050; % [prpc tmin tmax]. this could be better than ratio. 2050 is about the 70% ratio of 8 years
BQC.ylen=[8,100]; % least number of years
BQC.yrange=1979:2018;
[ID_ghcn,ID_gsod,ID_mexico,ID_eccc,flag_ghcn,flag_gsod,flag_eccc,flag_mexico]=f_basic_QC(Inpath,outfile1,outfile2,BQC);

%% Step3: merge stations with same locations
outfile3='f_position_merge.mat';
Tdis=0.001; % the threshold (km) of distance between gauges. If dis<Tdis, the two gauges are deemed the same in space
Outpathmerge=[Outpath,'/GGEM_merge'];
if ~exist(Outpathmerge,'dir'); mkdir(Outpathmerge); end
f_position_merge(Inpath,Outpathmerge,outfile2,outfile3,Tdis);

%% Step4: read and save all station data in one netcdf file
Inpath2=[Inpath,Outpathmerge];
Year=[1979,2018]; % all data will be unified to this year range
Outpathunify=[Outpath,'/AllGauge'];
if ~exist(Outpathunify,'dir'); mkdir(Outpathunify); end
FileAllgauge=[Outpathunify,'/GaugeInfo.mat'];
f_unify_save(Outpathunify,FileAllgauge,Inpath2,outfile3,Year);
