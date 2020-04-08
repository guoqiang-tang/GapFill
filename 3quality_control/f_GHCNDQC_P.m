function Qflag_prcp=f_GHCNDQC_P(p,date,NEcal,Tmean)
% follow the GHCN-D quality control method
% paper: Comprehensive Automated Quality Assurance of Daily Surface Observations
% dbstop if error

% basic information
yyyy=floor(date/10000);
mm=floor(mod(date,10000)/100);
dd=floor(mod(date,100));
yyyymm=floor(date/100);
ddd=datenum(yyyy,mm,dd)-datenum(yyyy,1,1)+1;

% (1) Basic integrity checks
% naught check (or repetition)
% other stations may not report measurement flag of T (Trace), so naught
% check is not used here

% duplicate check
% the flag corresponds to "D" in GHCN-D quality flag
flag_dup=f_duplicate(p,yyyy,mm,yyyymm);

% World record exceedance check
% the flag corresponds to nothing in GHCN-D quality flag
flag_exc=zeros(size(p));
flag_exc(p<0|p>1828.8)=1;

% Identical value: streak and frequent-value check
% the flag corresponds to "K" in GHCN-D quality flag
[pcentbin,pcent]=f_pcent_cal(p,ddd); % pcentbin=[30,50,70,90,95];
flag_idv=f_indentical(p,pcent);

% (2) Outiler check
% gap check
% the flag corresponds to "G" in GHCN-D quality flag
flag_gap=f_gap(p,mm);

% climatological outlier check
% the flag corresponds to "O" in GHCN-D quality flag
pcent95=pcent{5};
flag_clo=f_climoutlier(p,pcent95,Tmean);

% (3) Internal and temporal consistency checks
% SNOW and PRCP are needed at the same time. so this step cannot be
% implemented here

% (4) Spatial consistency checks
% the flag corresponds to "S" in GHCN-D quality flag
[pnear,indnear]=f_neighbor(NEcal,date); % find neighbor stations within 75 km
flag_spc=f_spatialcorr(p,pnear,ddd);

% (5) Megaconsistency checks
% not for precipitation

% synthesize all flags. we use ascii values to represent characters
% 0 means no check is failed
Qflag_prcp0=zeros(length(p),6);
flag_dup(flag_dup==1)=int16('D');
flag_exc(flag_exc==1)=int16('E'); % defined by ourself and no corresponding in GHCN-D
flag_idv(flag_idv==1)=int16('K');
flag_gap(flag_gap==1)=int16('G');
flag_clo(flag_clo==1)=int16('O');
flag_spc(flag_spc==1)=int16('S');
Qflag_prcp0(:,1)=flag_dup;
Qflag_prcp0(:,2)=flag_exc;
Qflag_prcp0(:,3)=flag_idv;
Qflag_prcp0(:,4)=flag_gap;
Qflag_prcp0(:,5)=flag_clo;
Qflag_prcp0(:,6)=flag_spc;

% convert to one column
Qflag_prcp=zeros(length(p),1);
for i=6:-1:1
    temp=Qflag_prcp0(:,i);
    ind=temp~=0;
    Qflag_prcp(ind)=temp(ind);  % some flags could be replaced
end

end

%% start: function for Basic integrity checks
function flag_dup=f_duplicate(p,yyyy,mm,yyyymm)
flag_dup=zeros(size(p));
% (1) Between entire years
% All values in one year = all corresponding values in another year
% For years with at least three nonzero values
yu=unique(yyyy);
p1=nan*zeros(365,length(yu));
for i=1:length(yu)
    pi=p(yyyy==yu(i));
    if length(pi)>=365&&sum(pi>0)>=3
        p1(:,i)=pi(1:365);
    end
end
yearout=f_FindDuplicate(p1);
if sum(yearout)>0
    temp=yu(yearout==1);
    flag_dup(ismember(yyyy,temp))=1; % delete these years
end

%(2) Between different months within the same year
% All values in one month = all values in another month
% Compares all days up to the last day of the shorter month; minimum of three nonzero values in the month required for PRCP and SNOW
for i=1:length(yu)
    indi=yyyy==yu(i);
    pi=p(indi);
    mmi=mm(indi);
    mmiu=unique(mmi);
    p2=nan*zeros(31,length(mmiu));
    for j=1:length(mmiu)
        pj=pi(mmi==mmiu(j));
        if length(pj)>=28&&sum(pj>0)>=3
            p2(1:length(pj),j)=pj;
        end
    end
    monthout=f_FindDuplicate(p2);
    if sum(monthout)>0
        temp=mmiu(monthout==1);
        temp2=zeros(size(pi));
        temp2(ismember(mmi,temp))=1; 
        flag_dup(indi)=temp2; % delete these months
    end
end

% (3) For the same calendar month in different years
% All values in one month = all values in another month
% Compares all days up to the last day of the shorter month; minimum of three nonzero values in the month required for PRCP and SNOW
mmu=unique(mm);
for i=1:length(mmu)
    indi=mm==mmu(i);
    pi=p(indi);
    yyyymmi=yyyymm(indi);
    yyyymmiu=unique(yyyymmi);
    p3=nan*zeros(31,length(yyyymmiu));
    for j=1:length(yyyymmiu)
        pj=pi(yyyymmi==yyyymmiu(j));
        if length(pj)>=28&&sum(pj>0)>=3
            p3(1:length(pj),j)=pj;
        end
    end
    monthout=f_FindDuplicate(p3);
    if sum(monthout)>0
        temp=yyyymmiu(monthout==1);
        temp2=zeros(size(pi));
        temp2(ismember(yyyymmi,temp))=1; 
        flag_dup(indi)=temp2; % delete these months
    end
end
end

function colout=f_FindDuplicate(p1)
% for a matrix: [row--days;  col--years or months]
% find which column has the same values
colout=zeros(size(p1,2),1);

ndays=size(p1,1);
index=find(sum(~isnan(p1))==ndays);
indnum=length(index);
if indnum>1
    for i=1:indnum-1
        indexi=index(i);
        pi=p1(:,indexi);
        for j=i+1:indnum
            indexj=index(j);
            pj=p1(:,indexj);
            indij=~isnan(pi)&~isnan(pj);           
            if sum(pi(indij)==pj(indij))==ndays % the two years are the same. drop them.
                colout(indexi)=1;
                 colout(indexj)=1;
            end
        end
    end
end
end


function flag_idv=f_indentical(p,pcent)
flag_idv=zeros(size(p));
snum=length(p);
% (1) streak check
% 20 or more consecutive
% Missing values and zeros are skipped
indp=find(p>0);
indp(indp>snum-20)=[];
if length(indp)>=20
    for i=1:length(indp)-19
       ptemp=p(indp(i:i+19));
       if length(unique(ptemp))==1
           flag_idv(indp(i:i+19))=1;
       end
    end
end

% (2) frequent-value check
% 9 or more out of 10 consecutive values are identical and $ their respective 30th percentiles; 
% 8 or more out of 10 are identical and $50th percentile; 
% 7 or more out of 10 are identical and $70th percentile; 
% or 5 or more out of 10 are identical and $90th percentile
% Missing values and zeros are skipped; percentiles computed as for the percentile-based outlier check
indp=find(p>0);
indp(indp>snum-10)=[];
if length(indp)>=10
    for i=1:length(indp)-9
       ptemp=p(indp(i:i+9));
       ptabu=tabulate(ptemp);
       indtemp=ptabu(:,2)>=9;
       if sum(indtemp)>0&&ptabu(indtemp,1)>=max(pcent{1}(indp(i:i+9)))
           ftemp=zeros(size(ptemp));
           ftemp(ptemp==ptabu(indtemp,1))=1;
           flag_idv(indp(i:i+9))=ftemp;
           continue;
       end

       indtemp=ptabu(:,2)>=8;
       if sum(indtemp)>0&&ptabu(indtemp,1)>=max(pcent{2}(indp(i:i+9)))
           ftemp=zeros(size(ptemp));
           ftemp(ptemp==ptabu(indtemp,1))=1;
           flag_idv(indp(i:i+9))=ftemp;
           continue;
       end
       
       indtemp=ptabu(:,2)>=7;
       if sum(indtemp)>0&&ptabu(indtemp,1)>=max(pcent{3}(indp(i:i+9)))
           ftemp=zeros(size(ptemp));
           ftemp(ptemp==ptabu(indtemp,1))=1;
           flag_idv(indp(i:i+9))=ftemp;
           continue;
       end
       
       indtemp=ptabu(:,2)>=5;
       if sum(indtemp)>0
           if sum(indtemp)==1
               if ptabu(indtemp,1)>=max(pcent{4}(indp(i:i+9)))
                   ftemp=zeros(size(ptemp));
                   ftemp(ptemp==ptabu(indtemp,1))=1;
                   flag_idv(indp(i:i+9))=ftemp;
               end
           else
               for pp=1:2
                   if ptabu(pp,1)>=max(pcent{4}(indp(i:i+9)))
                       ftemp=zeros(size(ptemp));
                       ftemp(ptemp==ptabu(pp,1))=1;
                       flag_idv(indp(i:i+9))=ftemp;
                   end
               end
           end
       end 
    end
end

end
%% end: function for Basic integrity checks

%% start: function for outlier check
function flag_gap=f_gap(p,mm)
% Gap in nonzero PRCP distribution for station/calendar month $300 mm
% One-tailed check (check the large values)
flag_gap=zeros(size(p));
ind300=find(p>300,1);
if ~isempty(ind300)
    for m=1:12
        indm=mm==m;
        pm=p(indm);
        [psort,indsort]=sort(pm,'ascend');
        indsort(isnan(psort))=[];
        psort(isnan(psort))=[];
        
        ind300m=find(psort>300);
        if ~isempty(ind300m)
            flagm=zeros(size(pm));
            for i=1:length(ind300m)
                if psort(ind300m(i))-psort(ind300m(i)-1)>300
                    flagm(indsort(ind300m(i):end))=1;
                    break;
                end
            end
            flag_gap(indm)=flagm;
        end
    end
end
end

function flag_clo=f_climoutlier(p,pcent95,Tmean)
% PRCP >= 9 X 95th percentile when Tmean >=0
% PRCP >= 5 X 95th percentile when Tmean <0
% Requires a minimum of 20 nonzero values for the period of record in the 29-day window
flag_clo=zeros(size(p));
ratio=zeros(size(p));
ratio(Tmean>=0|isnan(Tmean))=9;
ratio(Tmean<0)=5;
flag_clo(p>=ratio.*pcent95)=1;
end
%% end: function for outlier check


%% start: Spatial consistency checks
function flag_spc=f_spatialcorr(p,pnear,ddd)
flag_spc=zeros(size(p));

numnear=size(pnear,2);
if numnear<3
   return; 
end
if numnear>7
   pnear(:,8:end)=[];
   numnear=7;
end

% (1) A ??minimum absolute target?neighbor difference?? is obtained from the 
% pairwise differences between the precipitation total being evaluated and
% each neighbor total within the 3-day window.
plag=cell(3,1); 
plag{1}=[nan;p(1:end-1)]; plag{2}=p; plag{3}=[p(2:end);nan];
mindiff0=zeros(length(p),3);
for i=1:3   
    prep=repmat(plag{i},1,numnear);
    pdiff=prep-pnear;
    induse=sum(pdiff<0,2)==numnear&sum(pdiff>0,2)==numnear;
    pdiff2=pdiff(induse,:);
    mindiff0(induse,i)=min(abs(pdiff2),[],2);
end
minPdiff=min(mindiff0,[],2);

% (2) The minimum absolute target?neighbor difference is
% then also determined from the climatological percent
% ranks of the respective totals.
prank=f_prank(p,ddd);
pnearrank=nan*zeros(size(pnear));
for i=1:numnear
    pnearrank(:,i)=f_prank(pnear(:,i),ddd);
end

plag=cell(3,1); 
plag{1}=[nan;prank(1:end-1)]; plag{2}=prank; plag{3}=[prank(2:end);nan];
mindiff0=zeros(length(p),3);
for i=1:3   
    prep=repmat(plag{i},1,numnear);
    pdiff=prep-pnearrank;
    induse=sum(pdiff<0,2)==numnear&sum(pdiff>0,2)==numnear;
    pdiff2=pdiff(induse,:);
    mindiff0(induse,i)=min(abs(pdiff2),[],2);
end
minRdiff=min(mindiff0,[],2);

% formula
threshold=-45.72*log(minRdiff)+269.24; % in matlab, minRdiff=0 will result in a Inf estimate which does not affect results
threshold(isnan(threshold))=269.24;
flag_spc(minPdiff>threshold)=1;
end


% find neighbor stations
function [pnear,indnear]=f_neighbor(NEcal,date)

tarind=NEcal.tarind;
lle=NEcal.lleall;
IDall=NEcal.IDall;
Inpath=NEcal.Inpath;

% find stations within 75 km
dist=lldistkm(lle(tarind,1),lle(tarind,2),lle(:,1),lle(:,2));
dist(tarind)=nan;
indnear=find(dist<=75);  %75
numnear=length(indnear);
if numnear>0  %%%%% start loop
    % sort ind75 from closest to farthest
    temp=sortrows([dist(indnear),indnear],1);
    indnear=temp(:,2);
    % read data for these gauges and reshape their date to be consistent with
    % Tar gauge
    ID75=IDall(indnear);
    pnear=nan*ones(length(date),numnear);
    for i=1:numnear
        filei=[Inpath,'/',ID75{i},'.mat'];
        load(filei,'data');
        datei=data(:,1);
        [indi1,indi2]=ismember(datei,date);
        indi2(indi2==0)=[];
        if ~isempty(indi2)
            pnear(indi2,i)=data(indi1,2); % 2nd col is prcp
        end
        clear data
    end
else
    pnear=[]; indnear=[];
end
end

% the rank of prcp for each day in the climatological window
function prank=f_prank(p,ddd)
prank=zeros(length(p),1);
for i=1:366
    % the calendar day for the whole period
    Daywindow=[i-14:i-1,i+1:i+14];
    ind1=Daywindow<1;
    ind2=Daywindow>366;
    Daywindow(ind1)=Daywindow(ind1)+366;
    Daywindow(ind2)=Daywindow(ind2)-366;
    Dayi=i;
    % prcp for window and target day i
    Indwindow=ismember(ddd,Daywindow);
    pwindow=p(Indwindow);
    [~,loci]=ismember(Dayi,ddd);
    loci(loci==0)=[];
    if isempty(loci); continue; end
    pi=p(loci); 
    
    pclim=[];
    pclim(:,1)=[pi;pwindow];
    pclim(:,2)=[loci;zeros(size(pwindow))];    
    
    pclim(isnan(pclim(:,1))|pclim(:,1)==0,:)=[]; % only use non-zero values
    pnum=size(pclim,1);
    if pnum>=20
        pclim=sortrows(pclim,1);
        temp=find(pclim(:,2)>0);
        pranki=temp/pnum;
        prank(pclim(temp,2))=pranki*100;
    end
end
end
%% end: Spatial consistency checks

%% start: auxiliary functions
function [pcentbin,pcent]=f_pcent_cal(p,ddd)
% Requires a minimum of 20 nonzero values for the period of record in the 29-day window
pcentbin=[30,50,70,90,95];
pcent=cell(length(pcentbin),1);
pcent(:)={nan*zeros(366,1)};
for i=1:366
    drangei=i-14:i+14;
    ind1=drangei<1;
    ind2=drangei>366;
    drangei(ind1)=drangei(ind1)+366;
    drangei(ind2)=drangei(ind2)-366;
    indin=ismember(ddd,drangei);
    pin=p(indin);
    pin(isnan(pin)|pin==0)=[];
    if length(pin)>=20
        for pr=1:length(pcentbin)
             pcent{pr}(i)=prctile(pin,pcentbin(pr));
        end
    end
end

% distribute the values to the whole period
for pr=1:length(pcentbin)
    temp=nan*zeros(size(p));
    for i=1:366
        temp(ddd==i)=pcent{pr}(i);
    end
    pcent{pr}=temp;
end
end
%% end: auxiliary functions

