function [IDne_numDOY,IDne_ccDOY,IDne_distDOY]=f_findnear_DOY(FileGauge,varname,radius,leastne,Validnum,filevv,stnorder)
% this code find nearest stations for each day of year using a 31-day
% window to calcualte Spearman CC
if exist(filevv,'file')
    fprintf('IDne information file exists. Loading...\n');
    load(filevv,'IDne_numDOY','IDne_ccDOY','IDne_distDOY');
    return;
end
% this version is based on v2, but use .nc4 as inputs and can handle every
% variable
overyear=8; % the nearest gauge must have more than 5-year overlap period with the target gauges

% read the variable data
% variable data. only using data with flag==0
dataall=ncread(FileGauge,varname);
command=['flag1=ncread(FileGauge,''',varname,'_qf'');'];  %_QC: quality control data
eval(command);
command=['flag2=ncread(FileGauge,''',varname,'_qfraw'');'];  %_QC: quality control data
eval(command);
dataall(flag1>0)=nan; dataall(flag2>0)=nan;
clear flag1 flag2

lle=ncread(FileGauge,'LLE');
date=ncread(FileGauge,'date');
yyyy=floor(date/10000);
mm=floor(mod(date,10000)/100);
dd=mod(date,100);
doy=datenum(yyyy,mm,dd)-datenum(yyyy,1,1)+1;
lat=lle(:,1);
lon=lle(:,2);
gnum=length(lat);
IDnum=(1:gnum)';

% find stations that don't satisfy Validnum
temp1=sum(~isnan(dataall));
indno=temp1<Validnum.all;
dataall(:,indno)=nan;
lat(indno)=nan;
lon(indno)=nan;

outdir=['../DOY_IDinfo_',varname];
if ~exist(outdir,'dir')
    mkdir(outdir);
end
for i=stnorder(1):stnorder(2)
    fprintf('%s Find Near Gauge %d--%d\n',varname,i,gnum);
    outfilei=[outdir,'/',num2str(i),'.mat'];
    if exist(outfilei,'file')
        continue;
    end
    % initialization
    IDne_numi=nan*zeros(366,30);
    IDne_cci=nan*zeros(366,30);
    IDne_disti=nan*zeros(366,30);
    % calculate distance
    disi=zeros(gnum,2);
    disi(:,1)=IDnum;
    disi(:,2)=f_lldistkm(lat(i),lon(i),lat,lon);
    disi(i,2)=100000;
    % exclude too far gagues
    disi(disi(:,2)>radius|isnan(disi(:,2)),:)=[];
    IDne=disi(:,1);
    if length(IDne)>=leastne % leastne is the least number of nearest gauges
        % calculate spearman rank correlations (src) or pearson cc for each DOY
        vtar=dataall(:,i);
        vne=dataall(:,IDne);
        CCdoy=f_CCcal(vtar,vne,doy,overyear,varname);
        
        % sort gauges using src for each month
        for dd=1:366
            temp=[IDne,CCdoy(:,dd),disi(:,2)]; % [ID number, correlation, distance]
            temp(isnan(temp(:,2)),:)=[];
            num_m=size(temp,1);
            if num_m>=leastne
                temp=sortrows(temp,2,'descend');
                num_mm=min(30,num_m);
                IDne_numi(dd,1:num_mm)=temp(1:num_mm,1);
                IDne_cci(dd,1:num_mm)=temp(1:num_mm,2);
                IDne_disti(dd,1:num_mm)=temp(1:num_mm,3);
            end
        end
    end
    %     f_parsave(outfilei,IDne_numi,IDne_cci,IDne_disti);
    save(outfilei,'IDne_numi','IDne_cci','IDne_disti','-v7.3');
end

% save data
IDne_numDOY=nan*zeros(gnum,366,30);
IDne_ccDOY=nan*zeros(gnum,366,30);
IDne_distDOY=nan*zeros(gnum,366,30);
if stnorder(1)==1&&stnorder(2)==gnum
    for i=1:gnum
        fprintf('%s Find Near Gauge %d--%d\n',varname,i,gnum);
        outfilei=[outdir,'/',num2str(i),'.mat'];
        load(outfilei,'IDne_numi','IDne_cci','IDne_disti');
        IDne_numDOY(i,:,:)=IDne_numi;
        IDne_ccDOY(i,:,:)=IDne_cci;
        IDne_distDOY(i,:,:)=IDne_disti;
    end
    save(filevv,'IDne_numDOY','IDne_ccDOY','IDne_distDOY','-v7.3');
end
end

function CCdoy=f_CCcal(vtar,vne,doy,overyear,varname)
CCdoy=nan*zeros(size(vne,2),366);
for j=1:size(vne,2)
    vnej=vne(:,j);
    conum=sum(~isnan(vtar)&~isnan(vnej));
    if conum>365*overyear
        for dd=1:366
            ddrange=dd-15:dd+15;
            if dd<=15
                ddrange(ddrange<1)=ddrange(ddrange<1)+366;
            end
            if dd>=352
                ddrange(ddrange>366)=ddrange(ddrange>366)-366;
            end
            
            inddd=ismember(doy,ddrange);
            vtarjm=vtar(inddd);
            vnejm=vnej(inddd);
            
            src=f_cc(vtarjm,vnejm,varname);
            CCdoy(j,dd)=src;
        end
    end
end
end

function src=f_cc(X,Y,varname)
%spearman rank correlations (src)
ind=isnan(X)|isnan(Y);
X(ind)=[];
Y(ind)=[];
if length(X)>2
    if strcmp(varname,'prcp')
        src=corr(X,Y,'Type','Spearman');
    else
        src=corr(X,Y,'Type','Pearson');
    end
else
    src=nan;
end
end
