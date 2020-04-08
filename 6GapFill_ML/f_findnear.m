function IDne_num=f_findnear(FileGauge,varvv,radius,leastne,Validnum,filevv,CCreavv)
if exist(filevv,'file')
    fprintf('IDne information file exists. Loading...\n');
    load(filevv,'IDne_num');
    return;
end
if strcmp(varvv,'prcp')
    CCtype='Spearman';
else
    CCtype='Pearson';
end
% min CCreavv
CCreavvmin=nanmin(CCreavv);

% this version is based on v2, but use .nc4 as inputs and can handle every
% variable
overyear=8; % the nearest gauge must have more than 5-year overlap period with the target gauges

% read the variable data
% variable data. only using data with flag==0
dstn=ncread(FileGauge,varvv);
command=['flag1=ncread(FileGauge,''',varvv,'_qf'');'];  %_QC: quality control data
eval(command);
command=['flag2=ncread(FileGauge,''',varvv,'_qfraw'');'];  %_QC: quality control data
eval(command);
dstn(flag1>0)=nan; dstn(flag2>0)=nan;
clear flag1 flag2

lle=ncread(FileGauge,'LLE');
lat=lle(:,1);
lon=lle(:,2);
gnum=length(lat);
IDnum=(1:gnum)';

% find stations that don't satisfy Validnum
temp1=sum(~isnan(dstn));
indno=temp1<Validnum.all;
dstn(:,indno)=nan;
lat(indno)=nan;
lon(indno)=nan;

% initialization
IDne_num=nan*zeros(gnum,30);
IDne_cc=nan*zeros(gnum,30);
IDne_dist=nan*zeros(gnum,30);
for i=1:gnum
    fprintf('%s Find Near Gauge %d--%d\n',varvv,i,gnum);
   
    % calculate distance
    disi=zeros(gnum,2);
    disi(:,1)=IDnum;
    disi(:,2)=f_lldistkm(lat(i),lon(i),lat,lon);
    disi(i,2)=100000;
    % exclude too far gagues
    disi(disi(:,2)>radius|isnan(disi(:,2)),:)=[];
    IDne=disi(:,1);
    
    % calculate the CC between target and neighboring stations
    vtar=dstn(:,i);
    vne=dstn(:,IDne);
    CCne=nan*zeros(length(IDne),1);
    for in=1:length(IDne)
        dg=[vne(:,in),vtar];
        dg(isnan(dg(:,1))|isnan(dg(:,2)),:)=[];
        if size(dg,1)>overyear*365
            CCne(in)=corr(dg(:,1),dg(:,2),'Type',CCtype);
        end
    end
    
    % exclude some stations
    indi=CCne<CCreavvmin(i) | isnan(CCne);
    disi(indi,:)=[];
    CCne(indi)=[];
    numne=length(CCne);
    
    if numne>=leastne
        [CCne,indsort]=sort(CCne,'descend');
        disi=disi(indsort,:);
        numne=min(numne,30);
        IDne_num(i,1:numne)=disi(1:numne,1);
        IDne_cc(i,1:numne)=CCne(1:numne);
        IDne_dist(i,1:numne)=disi(1:numne,2);
    end    
end
save(filevv,'IDne_num','IDne_cc','IDne_dist','-v7.3');

end
