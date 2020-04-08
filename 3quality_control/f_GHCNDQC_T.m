function [Qflag_tmin,Qflag_tmax]=f_GHCNDQC_T(Tmin,Tmax,date,NEcal)
% follow the GHCN-D quality control method
% paper: Comprehensive Automated Quality Assurance of Daily Surface Observations
% dbstop if error
ind=isnan(Tmin)|isnan(Tmax);
Tmin(ind)=nan;
Tmax(ind)=nan;

snum=length(Tmin);
yyyy=floor(date/10000);
mm=floor(mod(date,10000)/100);
dd=floor(mod(date,100));
yyyymm=floor(date/100);
ddd=datenum(yyyy,mm,dd)-datenum(yyyy,1,1)+1;
tarind=NEcal.tarind;
lle=NEcal.lleall;
IDall=NEcal.IDall;
Inpath=NEcal.Inpath;

Ftmin=cell(10,1);
Ftmax=cell(10,1);
% (1) Basic integrity checks
% duplicate check, TMAX = TMIN on 10 or more days within a month
% the flag corresponds to "D" in GHCN-D quality flag
Ftmin{1}=f_duplicate(Tmin,Tmax,yyyymm);
Ftmax{1}=Ftmin{1};  % 1 is for Tmin and 2 is for Tmax

% World record exceedance check
% the flag corresponds to nothing in GHCN-D quality flag. E in this code
flag_exc1=zeros(size(Tmin));
flag_exc1(Tmin<-89.4|Tmin>57.7)=1;
Ftmin{2}=flag_exc1;

flag_exc2=zeros(size(Tmax));
flag_exc2(Tmax<-89.4|Tmax>57.7)=1;
Ftmax{2}=flag_exc2;

% Identical value: streak check
% the flag corresponds to "K" in GHCN-D quality flag
Ftmin{3}=f_indentical(Tmin);
Ftmax{3}=f_indentical(Tmax);


% (2) Outiler check
% gap check
% the flag corresponds to "G" in GHCN-D quality flag
Ftmin{4}=f_gap(Tmin,mm);
Ftmax{4}=f_gap(Tmax,mm);


% Climatological outlier check, z-score
% the flag corresponds to "O" in GHCN-D quality flag
Ftmin{5}=f_climoutlier(Tmin,ddd);
Ftmax{5}=f_climoutlier(Tmax,ddd);

% (3) Internal and temporal consistency checks
% internal consistency check (TOBS is not used here, so the method is not complete)
% the flag corresponds to "I" in GHCN-D quality flag
[Ftmin{6},Ftmax{6}]=f_internalcons(Tmin,Tmax);

% temporal consistency check (Spike/dip check)
% the flag corresponds to "T" in GHCN-D quality flag
Ftmin{7}=f_temporalcons(Tmin);
Ftmax{7}=f_temporalcons(Tmax);

% Lagged temperature range check
% the flag corresponds to "R" in GHCN-D quality flag
Ftmin{8}=f_lagrange(Tmin,Tmax);
Ftmax{8}=Ftmin{8};

% (4) spatial consistency checks
% the flag corresponds to "S" in GHCN-D quality flag
[Tminnear,Tmaxnear]=f_neighbor(NEcal,date);  % find neighbor stations within 75 km
Ftmin{9}=f_spatialcons(Tmin,Tminnear,yyyymm,ddd);
Ftmax{9}=f_spatialcons(Tmax,Tmaxnear,yyyymm,ddd);


% (5) Megaconsistency checks
% the flag corresponds to "M" in GHCN-D quality flag
[Ftmin{10},Ftmax{10}]=f_megaconsistency(Tmin,Tmax,mm);


% synthesize all flags. we use ascii values to represent characters
% 0 means no check is failed
Qflag_tmin0=zeros(length(Tmin),10);
Qflag_tmax0=zeros(length(Tmax),10);
flagchar={'D','E','K','G','O','I','T','R','S','M'};
for i=1:10
    temp=Ftmin{i};
    temp(temp==1)=int16(flagchar{i});
    Qflag_tmin0(:,i)=temp;
    
    temp=Ftmax{i};
    temp(temp==1)=int16(flagchar{i});
    Qflag_tmax0(:,i)=temp;
end

% convert to one column
Qflag_tmin=zeros(length(Tmin),1);
Qflag_tmax=zeros(length(Tmax),1);

for i=10:-1:1
    temp=Qflag_tmin0(:,i);
    ind=temp~=0;
    Qflag_tmin(ind)=temp(ind);  % some flags could be replaced
    
    temp=Qflag_tmax0(:,i);
    ind=temp~=0;
    Qflag_tmax(ind)=temp(ind);  % some flags could be replaced
end

end

%% start: Basic integrity checks
function flag_dup=f_duplicate(Tmin,Tmax,yyyymm)
flag_dup=zeros(size(Tmin));
ymu=unique(yyyymm);
Tdiff=Tmax-Tmin;
for i=1:length(ymu)
    indi=yyyymm==ymu(i);
    Tdiffi=Tdiff(indi);
    if sum(~isnan(Tdiffi))>=10        
        flagi=f_repeatsame(Tdiffi,0,10);
        flag_dup(indi)=flagi;
    end
end
end

function flag_idv=f_indentical(T)
flag_idv=zeros(size(T));
indi=~isnan(T);
T2=T(indi);
Tdiff=T2-[nan;T2(1:end-1)];
flagi=f_repeatsame(Tdiff,0,19); % 20 same values have 19 zeros
flag_idv(indi)=flagi;
end
%% end: Basic integrity checks

%% start: function for outlier check
function flag_gap=f_gap(T,mm)
% Gap in nonzero PRCP distribution for station/calendar month $300 mm
% One-tailed check (check the large values)
flag_gap=zeros(size(T));

for m=1:12
    indm=mm==m & ~isnan(T);
    Tm=T(indm);
    flagm=zeros(size(Tm));
    
    if length(Tm)>3
        [Tsort,indsort]=sort(Tm);
        % proceeding upward and downward from the median
        menum=floor(length(Tm)/2);
        Tsortu=Tsort(menum:end);
        indsortu=indsort(menum:end);
        Tgap=Tsortu(2:end)-Tsortu(1:end-1);
        indgap=find(Tgap>10);
        if ~isempty(indgap)
            indori=indsortu(indgap(1)+1:end);
            flagm(indori)=1;
        end

        Tsortd=Tsort(1:menum-1);
        indsortd=indsort(1:menum-1);
        Tgap=Tsortd(2:end)-Tsortd(1:end-1);
        indgap=find(Tgap>10);
        if ~isempty(indgap)
            indori=indsortd(1:indgap(end));
            flagm(indori)=1;
        end
    end
    flag_gap(indm)=flagm;
end

end


function flag_clo=f_climoutlier(T,ddd)
flag_clo=zeros(size(T));

[ME,STD]=f_climate_MESTD(T,ddd,1);

Tnorm=(T-ME)./STD;
flag_clo(abs(Tnorm)>=6)=1;
end
%% end: function for outlier check

%% start: Internal and temporal consistency checks
function [flag_itc1,flag_itc2]=f_internalcons(Tmin,Tmax)
% make it in a simpler way than the literature because TOBS is not included here
flag_itc1=zeros(size(Tmin));
flag_itc1(Tmax<Tmin)=1;
flag_itc2=flag_itc1;
end

function flag_tec=f_temporalcons(T)
flag_tec=zeros(size(T));

temp1=[nan;T(1:end-1)];
temp2=[T(2:end,:);nan];
flag_tec(abs(T-temp1)>=25&abs(T-temp2)>=25)=1;
end

function flag_lgr=f_lagrange(Tmin,Tmax)
flag_lgr=zeros(size(Tmin));
TT=[Tmin,Tmax];
for i=1:2
   t1=TT(:,i);
   t2=TT(:,3-i);
   t21=[nan;t2(1:end-1)];
   t22=[t2(2:end);nan];
   indi= abs(t1-t2)>=40|abs(t1-t21)>=40|abs(t1-t22)>40;
   flag_lgr(indi)=1;
end
end
%% end: Internal and temporal consistency checks

%% start: spatial consistency checks
% find neighbor stations
function [Tminnear,Tmaxnear]=f_neighbor(NEcal,date)
tarind=NEcal.tarind;
lle=NEcal.lleall;
IDall=NEcal.IDall;
Inpath=NEcal.Inpath;

% before checking, find the nearest gauges
% find stations within 75 km
d1km=lldistkm(lle(tarind,1),lle(tarind,2),lle(:,1),lle(:,2));
d1km(tarind)=nan;
ind75=find(d1km<=75);  %75
num75=length(ind75);
if num75>=3  %%%%% start loop
    % sort ind75 from closest to farthest
    temp=sortrows([d1km(ind75),ind75],1);
    ind75=temp(:,2);
    % read data for these gauges and reshape their date to be consistent with
    % Tar gauge
    ID75=IDall(ind75);
    Tminnear=nan*ones(length(date),num75);
    Tmaxnear=nan*ones(length(date),num75);
    for i=1:num75
        filei=[Inpath,'/',ID75{i},'.mat'];
        load(filei,'data');
        datei=data(:,1);
        [indi1,indi2]=ismember(datei,date);
        indi2(indi2==0)=[];
        if ~isempty(indi2)
            Tminnear(indi2,i)=data(indi1,3);
            Tmaxnear(indi2,i)=data(indi1,4);
        else
            
        end
        clear data
    end
else
    Tminnear=[];Tmaxnear=[];
end
end


function flag_spc=f_spatialcons(Ttar,Tnear,yyyymm,ddd)
flag_spc=zeros(size(Ttar));
if isempty(Tnear)
   return; 
end
ymu=unique(yyyymm);

% Regression check
% loop for each month window
flag_reg=zeros(size(Ttar));
for i=1:length(ymu)
    indi=find(yyyymm==ymu(i));
    flagi=zeros(size(indi));
    if i==1
        fi=1;
        indi2=indi(1):(indi(end)+15);
    elseif i==length(ymu)
        fi=2;
        indi2=(indi(1)-15):indi(end);
    else
        fi=3;
        indi2=(indi(1)-15):(indi(end)+15);
    end
    indi2(indi2<0|indi2>length(Ttar))=[];
    % find qualified nearest gauges
    dataTari=Ttar(indi2);
    if sum(~isnan(dataTari))<40
       continue; % 40 days data are necessary 
    end
    
    data75i=Tnear(indi2,:);
    ind75in=sum(~isnan(data75i))>=40;
    if sum(ind75in)<3
        continue; % not enough nearest gauges, don't do quality control
    end
    data75i2=data75i(:,ind75in);
    indargi=f_index_agreement(dataTari,data75i2);
    [indargi,tempind]=sort(indargi,'descend');
    tempind(isnan(indargi))=[];
    indargi(isnan(indargi))=[];
    data75i2=data75i2(:,tempind);  % sort the nearest gauges according to index of agreement
    if size(data75i2,2)>7
        data75i2(:,8:end)=[];
        indargi(8:end)=[];
    end
    % get the regressed Tar data for each neighboring gauges and then
    % averaging them using index of agreement
    data75i3=f_linear_regression(dataTari,data75i2);
    for ii=1:length(indargi)
        data75i3(:,ii)=data75i3(:,ii)*indargi(ii);
    end
    dataTariFit=sum(data75i3,2)/sum(indargi);
    % come to the regression check
    res=dataTari-dataTariFit;
    resnorm=(res-nanmean(res))/nanstd(res);
    
    switch fi
        case 1
            res(end-14:end)=[]; resnorm(end-14:end)=[];
        case 2
            res(1:15)=[]; resnorm(1:15)=[];
        case 3
            res(1:15)=[]; resnorm(1:15)=[];
            res(end-14:end)=[]; resnorm(end-14:end)=[];
    end
    
    flagi(abs(res)>=8&abs(resnorm)>=4)=1;
    flag_reg(indi)=flagi;
end

% Spatial corroboration check
flag_corr=zeros(size(Ttar));
if size(Tnear,2)>7
   Tnear(:,8:end)=[]; 
end

[MEtar,~]=f_climate_MESTD(Ttar,ddd,0);
MEne=nan*zeros(size(Tnear));
for i=1:size(Tnear,2)
    MEne(:,i)=f_climate_MESTD(Tnear(:,i),ddd,0);
end

anomTar=Ttar-MEtar;
anomTar=repmat(anomTar,1,size(Tnear,2));

anomME1=Tnear-MEne;
addme=nan*ones(1,size(Tnear,2));
anomME2=[addme;anomME1(1:end-1,:)];
anomME3=[anomME1(2:end,:);addme];

anomDiff1=abs(anomTar-anomME1);
anomDiff2=abs(anomTar-anomME2);
anomDiff3=abs(anomTar-anomME3);

indnan=all(anomDiff1>=10,2)&all(anomDiff2>=10,2)&all(anomDiff3>=10,2);

flag_corr(indnan)=1;

% final
flag_spc(flag_reg==1|flag_corr==1)=1;
end


function indagr=f_index_agreement(dobs,dpred)
indagr=nan*zeros(size(dpred,2),1);
for i=1:size(dpred,2)
    dd=[dobs,dpred(:,i)];
    dd(isnan(dd(:,1))|isnan(dd(:,2)),:)=[];
    if length(dd)>10
        me1=mean(dd(:,1));
        indexi=1-sum(abs(dd(:,1)-dd(:,2)))/sum(abs(dd(:,2)-me1)+abs(dd(:,1)-me1));
        indagr(i)=indexi;
    end
end
end

function dout=f_linear_regression(dobs,dpred)
dout=dpred*nan;
dobs2=repmat(dobs,1,3);
for i=1:size(dpred,2)
    dp0=dpred(:,i);
    dp1=[dp0(1);dp0(1:end-1)];  % 3-day window. find the one closest to observation
    dp2=[dp0(2:end);dp0(end)];
    dp012=[dp0,dp1,dp2];
    
    diff=abs(dobs2-dp012);
    dpredi=dp0*nan;
    for j=1:length(dpredi)
        diffj=diff(j,:);
        indj=diffj==min(diffj);
        dj=dp012(j,indj);
        if ~isempty(dj)
            dpredi(j)=dj(1);
        end
    end
    
    % exclude nan values
    dini=[dpredi,dobs];
    [rri,cci]=find(isnan(dini));
    dini(rri,:)=[];
    if length(dini)>3
        pii=polyfit(dini(:,1),dini(:,2),2);
        dout(:,i)=pii(1)+pii(2)*dpredi;
    end
    
end
end
%% end: spatial consistency checks

%% start: megaconsistency checks
function [flag_meg1,flag_meg2]=f_megaconsistency(Tmin,Tmax,mm)
flag_meg1=zeros(size(Tmin));
flag_meg2=zeros(size(Tmax));

minmin=nan*Tmin;
maxmax=nan*Tmax;
for i=1:12
    indi=mm==i;
    Tmini=Tmin(indi);
    Tmaxi=Tmax(indi);
    if sum(~isnan(Tmini))>=140
       minmin(indi)=min(Tmini);
    end
    if sum(~isnan(Tmaxi))>=140
       maxmax(indi)=max(Tmaxi);
    end
end

flag_meg1(Tmin>maxmax)=1;
flag_meg2(Tmax<minmin)=1;
end
%% end: megaconsistency checks


%% start: auxiliary function
function flagsame=f_repeatsame(data,value,num)
flagsame=zeros(size(data));
datalen=length(data);
indvv=find(data==value);
indvv(indvv+num>datalen)=[];
while ~isempty(indvv)
    ss=indvv(1);
    ee=ss+num-1;    
    datai=data(ss:ee);
    if all(datai==value)
        flagsame(ss:ee)=1;
        indvv(indvv<ee)=[];
    else
        indvv(1)=[];
    end
end
end

function [ME,STD]=f_climate_MESTD(T,ddd,cal_std)
ME=nan*T;
STD=nan*T;
for i=1:366
    drangei=i-7:i+7;
    ind1=drangei<1;
    ind2=drangei>366;
    drangei(ind1)=drangei(ind1)+366;
    drangei(ind2)=drangei(ind2)-366;
    indwindow=ismember(ddd,drangei);
     
    Ti=T(indwindow);
    Ti(isnan(Ti))=[];
    if length(Ti)<100
       continue; 
    end
    
    indi=ddd==i;
    temp=mean(Ti);
    ME(indi)=temp;
    
    if cal_std==1
        STD(indi)=std(Ti);
    end
end
end
%% end: auxiliary function