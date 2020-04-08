function f_position_merge(Inpath,Outpathmerge,outfile2,outfile3,Tdis)
% if exist(outfile3,'file')
%    return; 
% end

% basic information of stations from all sources
SourceName={'GHCN-D','GSOD','ECCC','Mexico'};
load(outfile2,'ID_ghcn','ID_gsod','ID_mexico','ID_eccc',...
       'flag_ghcn','flag_gsod','flag_eccc','flag_mexico',...
       'lle_ghcn','lle_gsod','lle_eccc','lle_mexico');
prod={'ghcn','gsod','eccc','mexico'};
for i=1:length(prod)
   command=['ID_',prod{i},'(flag_',prod{i},'~=1)=[];']; eval(command);
   command=['lle_',prod{i},'(flag_',prod{i},'~=1,:)=[];']; eval(command);
   command=['flag_',prod{i},'(flag_',prod{i},'~=1)=[];']; eval(command);
end
   
IDall=[ID_ghcn;ID_gsod;ID_eccc;ID_mexico];
LLEall=[lle_ghcn;lle_gsod;lle_eccc;lle_mexico];
SourceAll=[ones(length(ID_ghcn),1)*1;...
    ones(length(ID_gsod),1)*2;...
    ones(length(ID_eccc),1)*3;...
    ones(length(ID_mexico),1)*4];

% calculate distance between stations and find those < Tdis
filemerge=[Outpathmerge,'/mergeinfo.mat'];
if ~exist(filemerge,'file')
    [Overlap_IDNum,Overlap_Dis]=f_mini_dist(LLEall(:,1),LLEall(:,2),Tdis);
    save(filemerge,'Overlap_IDNum','Overlap_Dis');
else
    load(filemerge,'Overlap_IDNum','Overlap_Dis');
end

% flag stations with overlapped problems in the original databases
temp=Overlap_IDNum;
temp(isnan(temp))=[]; temp=temp(:);
IDallover=IDall(temp);
flag_ghcn(ismember(ID_ghcn,IDallover))=-2;
flag_gsod(ismember(ID_gsod,IDallover))=-2;
flag_eccc(ismember(ID_eccc,IDallover))=-2;
flag_mexico(ismember(ID_mexico,IDallover))=-2;

% output gauges that have overlapped problem
ID_merge=cell(size(Overlap_IDNum,1),2);
lle_merge=zeros(size(Overlap_IDNum,1),3);
ffi=1;
for i=1:size(Overlap_IDNum,1)
    fprintf('Merge --%d--%d\n',i,size(Overlap_IDNum,1));
    numin=Overlap_IDNum(i,:);
    numin(isnan(numin))=[];
    [data,mergeflag,lle,varname]=f_MergeDecideNew(numin,Inpath,IDall,SourceAll);  % mergeflag: 1 used in merging, 0 not used
    if ~isempty(data)
        IDoverlap=IDall(numin);  % all overlapped stations
        IDuse=IDoverlap(mergeflag==1);  % stations used for merging
        Sourceoverlap=SourceName(SourceAll(numin));
        ID=IDuse{1};
        
        if length(ID)==8
           ID=['999',ID]; 
        end
        
        Outfile=[Outpathmerge,'/',ID,'.mat']; % ME indicates that the gauge is merged from multiple gauges.
        save(Outfile,'data','ID','lle','IDuse','ID','IDoverlap','Sourceoverlap','varname');
        
        ID_merge{ffi,1}=ID;
        ID_merge{ffi,2}=IDoverlap;
        lle_merge(ffi,:)=lle;
        ffi=ffi+1;
    end
end
if ffi<=size(Overlap_IDNum,1)
    ID_merge(ffi:end,:)=[];
    lle_merge(ffi:end,:)=[];
end


flagvalue={'1-valid','0-fail ID check','-1: fail basic QC','-2: overlap with other stations'};
save(outfile3,'ID_ghcn','ID_gsod','ID_mexico','ID_eccc','ID_merge',...
    'flag_ghcn','flag_gsod','flag_eccc','flag_mexico',...
    'lle_ghcn','lle_gsod','lle_eccc','lle_mexico','lle_merge',...
    'flagvalue');
end


%% start: merge overlapped stations
function [dataout,mergeflag,lle,varname]=f_MergeDecideNew(gaugenum,Inpath,IDall,SourceAll)
sourcei=SourceAll(gaugenum);  % corresponding to which Inpath or data source to use
% read data for these overlapped gauges
datai=cell(length(gaugenum),1);
for ss=1:length(gaugenum)
    filess=[Inpath{sourcei(ss)},'/',IDall{gaugenum(ss)},'.mat'];
    load(filess,'data','lle','varname');
    datai{ss}=data;
    clear data
end

% merge these stations one by one
mergeflag=zeros(length(gaugenum),1);
for ss=1:length(gaugenum)-1
    P1=datai{ss}(:,2); date1=datai{ss}(:,1);
    P2=datai{ss+1}(:,2); date2=datai{ss+1}(:,1);
    flagss=f_compare(P1,date1,P2,date2);
    % flag==-1: the two gauges are abandoned
    % flag==0: merge the two gauges according to date
    % flag==1: % keep the first gauge, i.e., P
    % flag==2: % keep the second gauge, i.e., Pj
    switch flagss
        case -1 % the overlapped stations are abandoned
            datai{end}=[];
            mergeflag(:)=0;
            break;
        case 0
            mergeflag(ss)=1;
            mergeflag(ss+1)=1;
            datai{ss+1}=f_merge(datai{ss},datai{ss+1});
        case 1
            mergeflag(ss)=1;
            datai{ss+1}=datai{ss};
            datai{ss}=[];
        case 2
            mergeflag(ss+1)=1;
            datai{ss}=[];
    end
end

% output data
dataout=datai{end};
end


function data=f_merge(data1,data2)
temp=ismember(data1(:,1),data2(:,1));
data1(temp,:)=[];
data=cat(1,data1,data2);
data=sortrows(data,1); % sometimes, the date is really strange
end

function flag=f_compare(P,date,Pj,datej)
% flag==-1: the two gauges are abandoned
% flag==0: merge the two gauges according to date
% flag==1: % keep the first gauge, i.e., P
% flag==2: % keep the second gauge, i.e., Pj

P(P<0)=nan;
Pj(Pj<0)=nan;

[ind,indj]=ismember(datej,date);
indj(indj==0)=[];
if sum(ind)<30 % the two gauges have a very short or no overlapped period
    flag=0;
else
    Ptemp(:,1)=P(indj);
    Ptemp(:,2)=Pj(ind);
    Ptemp(isnan(Ptemp(:,1))|isnan(Ptemp(:,2)),:)=[];
    if isempty(Ptemp)
       flag=-1;
       return;
    end
    
    cc=corr(Ptemp(:,1),Ptemp(:,2),'Type','Spearman');
    if isnan(cc)
        flag=0; % the overlapped period cannot support the calculation of CC, so we can merge the two gauges
    elseif cc<0.7 % for the overlapped period, the two gauges show notable differences
        flag=-1;
    elseif cc>=0.7
        snum1=sum(P>=0);
        snum2=sum(Pj>=0);
        if snum1>=snum2
            flag=1;  % keep the first gauge, i.e., P
        else
            flag=2;  % keep the second gauge, i.e., Pj
        end
    elseif cc>=0.9
        flag=0;
    end
end
end

%% end: merge overlapped stations


%% start: distance calculate
function [IDnum,Dis]=f_mini_dist(latin,lonin,Tdis)
% when the gauge number is very large (such as 60000), the large distance
% matrix in f_minimum_dist cannot be generated
% opt: 1--lat1==lat2 (the distance between one gauge dataset), 2--different
% data sets
gnum=length(latin);

% ID is index for overlapped gauges
IDnum=nan*zeros(1000,10);  % columns represent stations that have overlapped location
Dis=nan*zeros(1000,9); % the distance between 2-10 columns with the first column
flag=1;
for i=1:gnum
    lat1i0=latin(i);
    lon1i0=lonin(i);
    if isnan(lat1i0)
       continue; 
    end
    
    lat2i=latin;
    lon2i=lonin;
    lat2i(i)=nan;
    lon2i(i)=nan;
    
    templ=length(lat2i);
    lat1i=repmat(lat1i0,templ,1);
    lon1i=repmat(lon1i0,templ,1);
    
    disi=lldistkm(lat1i,lon1i,lat2i,lon2i);
    indi=find(disi<Tdis);
    leni=length(indi);
    if leni>0
        IDnum(flag,1)=i;
        IDnum(flag,2:1+leni)=indi;
        Dis(flag,1:leni)=disi(indi);
        latin(indi)=nan; % once overlapped, delete the station from following computation
        lonin(indi)=nan;
        flag=flag+1;
    end
    if mod(i,500)==0
        fprintf('Min dis %d--%d\n',i,gnum);
    end
end

if size(IDnum,2)==10
    temp=sum(~isnan(IDnum));
    IDnum(:,temp==0)=[];
    temp=sum(~isnan(Dis));
    Dis(:,temp==0)=[];
end

if size(IDnum,1)==1000
   temp=isnan(IDnum(:,1));
   IDnum(temp,:)=[];
   Dis(temp,:)=[];
end
end

function d1km=lldistkm(lat1,lon1,lat2,lon2)
radius=6371;
lat1=lat1*pi/180;
lat2=lat2*pi/180;
lon1=lon1*pi/180;
lon2=lon2*pi/180;
deltaLat=lat2-lat1;
deltaLon=lon2-lon1;
a=sin((deltaLat)/2).^2 + cos(lat1).*cos(lat2) .* sin(deltaLon/2).^2;
c=2*atan2(sqrt(a),sqrt(1-a));
d1km=radius*c;    %Haversine distance

% x=deltaLon.*cos((lat1+lat2)/2);
% y=deltaLat;
% d2km=radius*sqrt(x.*x + y.*y); %Pythagoran distance
end

%% end: distance calculate
