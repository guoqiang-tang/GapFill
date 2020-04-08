% save independent station files in one netcdf4 file
clc;clear;close all
Inpath='/home/gut428/GapFill/Data/AllGauge_QC';
Outfile='/home/gut428/GapFill/Data/AllGauge_QC.nc4';

% mac path
% Inpath='/Users/localuser/Research/AllGauge_QC';
% Outfile='/Users/localuser/Research/AllGauge_QC.nc4';

Year=[1979,2018];

% station infomation
FileInfo=[Inpath,'/GaugeInfo.mat'];
load(FileInfo,'ID','LLE');
nstn=length(ID);

% date information
date=datenum(Year(1),1,1):datenum(Year(2),12,31);
nday=length(date);
date=datestr(date,'yyyymmdd');
date=mat2cell(date,ones(nday,1),8);
date=str2double(date);

% initialize all variables
prcp=single(nan*zeros(nday,nstn));  tmin=single(nan*zeros(nday,nstn));  tmax=single(nan*zeros(nday,nstn));
prcp_qfraw=single(nan*zeros(nday,nstn));  tmin_qfraw=single(nan*zeros(nday,nstn));  tmax_qfraw=single(nan*zeros(nday,nstn));
prcp_qf=single(nan*zeros(nday,nstn));  tmin_qf=single(nan*zeros(nday,nstn));  tmax_qf=single(nan*zeros(nday,nstn));
mflag=single(nan*zeros(nday,nstn));
% read all kinds of station data for different sources
for i=1:nstn
    fprintf('reading %d--%d\n',i,nstn);
    filei=[Inpath,'/',ID{i},'.mat'];
    sourcei=ID{i}(1:2);
    
    [datai,qfrawi,qfi,mfi]=f_read(filei,sourcei,date);
    prcp(:,i)=datai(:,1); tmin(:,i)=datai(:,2); tmax(:,i)=datai(:,3);
    prcp_qfraw(:,i)=qfrawi(:,1); tmin_qfraw(:,i)=qfrawi(:,2); tmax_qfraw(:,i)=qfrawi(:,3);
    prcp_qf(:,i)=qfi(:,1); tmin_qf(:,i)=qfi(:,2); tmax_qf(:,i)=qfi(:,3);
    mflag(:,i)=mfi;
end

overwrite=1;
f_save_stn(Outfile,ID,LLE,date,prcp,tmin,tmax,...
    prcp_qfraw,tmin_qfraw,tmax_qfraw,...
    prcp_qf,tmin_qf,tmax_qf,mflag,overwrite);


