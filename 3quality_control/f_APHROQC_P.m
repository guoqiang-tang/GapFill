% quality control of daily gauges
% this method is mainly from "An Automated Quality Control Method for Daily
% Rain-gauge Data" by Atsushi HAMADA et al. 2011 which is used by APHRODITE
% for the zero value check, this code adpots the method used by MSWEP V2.0
% by Beck et al. 2019 on BAMS
% the number is the same as Hamada 2011 (H2011)
function Qflag_prcp=f_APHROQC_P(p,pne,date)
dbstop if error
% date from yyyymmmdd to yyyy mm dd
yyyy=floor(date/10000);
mm=floor((date-yyyy*10000)/100);

% 3.1 Errors in station metadata
% Errors in station location may cause a significant error in a gridded analysis
% %fprintf('3.1 Do not check station metadata.\n');

% 3.2 Errors detected in single station records
% 3.2.1 Erroneous values inherent to particular data sources
% %fprintf('3.2.1 Do not check inherent values.\n');

% 3.2.2 Values exceeding national/regional records
% H2011 uses a maximum precipitation value for each country accoridng to
% Burt 2007. Since I have no access to Burt 2007, a 1,825 mm/d threshold is
% used which is observed at La Réunion Island (Arizona State University/
% World Meteorological Organization 2011).
%fprintf('3.2.2 Check extreme values.\n');
% p(p>1825)=nan;
% 
% if sum(p>0)==0
%    p(:)=nan;
%    return
% end

% 3.2.3 Contamination with different weather elements
% %fprintf('3.2.3 Do not check contamination with different weather elements.\n');

% 3.2.4 Repetition of constant values
% (1)non-zero repetition
% daily measurements are judged to be in error if constant values over 10 mm/d
% persist for more than four days. 
% (2)zero repetition
% based on Beck 2019 BAMS
flag_repno0=zeros(size(p));
p2=f_repetition_no0(p);
flag_repno0(isnan(p2)&~isnan(p))=1;

flag_rep0=zeros(size(p));
p2=f_repetition_0(p,yyyy,mm);
flag_rep0(isnan(p2)&~isnan(p))=1;

% 3.2.5 Duplication of monthly or sub-monthly records
flag_dup=zeros(size(p));
p2=f_mduplication(p,yyyy,mm);
flag_dup(isnan(p2)&~isnan(p))=1;

% 3.2.6  Outliers
flag_out=zeros(size(p));
p2=f_outlier(p);
flag_out(isnan(p2)&~isnan(p))=1;

% 3.2.7 Homogeneity test
% %fprintf('3.2.6 Do not check outliers.\n');

% 3.3 Error detection using multiple station records
% 3.3.1 Spatiotemporally isolated values
% pne: precipitation from neighboring stations [date,station number]
% date of pne is adjuted to be same with p
% done against up to ten neighboring stations within 400 km. 
flag_iso=zeros(size(p));
p2=f_isolate(p,pne);
flag_iso(isnan(p2)&~isnan(p))=1;

%fprintf('3.3.1 Check spatiotemporally isolated values.\n');

% 3.3.2 Errors in units of measurement
% %fprintf('3.3.2 Do not check unit errors.\n');

% 3.3.3 Ambiguity in recorded date
% %fprintf('3.3.2 Do not check date errors. Use Beck method.\n');

% 4. Additional quality control
flag_add=zeros(size(p));
p2=f_Beck(p);
flag_add(isnan(p2)&~isnan(p))=1;

% synthesize all flags. we use ascii values to represent characters
% 0 means no check is failed
Qflag_prcp0=zeros(length(p),6);
Qflag_prcp0(flag_repno0==1,1)=33;  % space ' ' is 32. so we start from 33 to aviod overlap with GHCN characters
Qflag_prcp0(flag_rep0==1,2)=34;
Qflag_prcp0(flag_dup==1,3)=35;
Qflag_prcp0(flag_out==1,4)=36;
Qflag_prcp0(flag_iso==1,5)=37;
Qflag_prcp0(flag_add==1,6)=38;

% convert to one column
Qflag_prcp=zeros(length(p),1);
for i=6:-1:1
    temp=Qflag_prcp0(:,i);
    ind=temp~=0;
    Qflag_prcp(ind)=temp(ind);  % some flags could be replaced
end

end

function p=f_repetition_no0(p)
% (1)non-zero repetition
% daily measurements are judged to be in error if constant values over 10 mm/d
% persist for more than four days. 
ind=find(p>10);
ind(ind>length(p)-4)=[];
len1=length(ind);
for i=1:len1
    pi1=p(ind(i));
    pi2_5=p(ind(i)+1:ind(i)+4);
    if sum(pi2_5==pi1)==4
       p(ind(i):ind(i)+4)=nan; 
    end
end
end

function p=f_repetition_0(p,yyyy,mm)
% (2)zero repetition
% based on Beck 2019 BAMS
yyyymm=yyyy*100+mm;
yyyymmu=unique(yyyymm);
fD=nan*zeros(length(yyyymmu),1); 
for i=1:length(yyyymmu)
    indi=(yyyymm==yyyymmu(i));
    pi=p(indi); % daily data for a specific month
    pid=sum(isnan(pi));
    if pid<5
        fD(i)=sum(pi==0)/(length(pi)-pid); % the fraction of days without P 
    end
end

if sum(~isnan(fD))>=1 % 1 months effective data is the least requirement
    fDmean=nanmean(fD(fD~=1));
    fDstd=nanstd(fD(fD~=1));
    % if the CDF of the normal distribution with ? and
    % ? evaluated at fD = 0.9 exceeds 0.85, the gauge was
    % considered to be sufficiently “wet? for detecting the
    % erroneous zeros, and we proceeded to the next step
    cdft=normcdf(0.9,fDmean,fDstd); 
    
    if cdft>0.85
        yyyy2=floor(yyyymmu/100);
        yyyy2u=unique(yyyy2);
        for i=1:length(yyyy2u)
            fDi=fD(yyyy2==yyyy2u(i));
            if nanmedian(fDi)>0.9
               % the current year is erroneous
               % 6 months preceding and following each erroneous year are also erroneous
               yearErr=yyyy2u(i);
               temp1=yearErr*ones(12,1)*100+(1:12)';
               temp2=(yearErr-1)*ones(6,1)*100+(7:12)';
               temp3=(yearErr+1)*ones(6,1)*100+(1:6)';
               yyyymmErr=[temp1;temp2;temp3];
               p(ismember(yyyymm,yyyymmErr))=nan;
            end
        end
    end   
end


end

function p=f_mduplication(p,yyyy,mm)
% the code is different from the method described in the paper
yyyymm=yyyy*100+mm;
yyyymmu=unique(yyyymm);

p2=p;
p2(p2==0)=nan;
for i=1:length(yyyymmu)-1
    ind1=yyyymm==yyyymmu(i);
   data1=p2(ind1);
   days1=length(data1);
   ind2=yyyymm==yyyymmu(i+1);
   data2=p2(ind2);
   days2=length(data2);
   if days2<5
      continue; 
   end
   
   if days1>days2
       data2(end+1:end+days1-days2)=nan;
   elseif days1<days2
       data1(end+1:end+days2-days1)=nan;
   end
   temp1=abs(data1-data2);
   temp2=abs(data1-[data2(2:end);nan]);
   temp3=abs(data1-[nan;data2(1:end-1)]);
   % use <0.01 to replace ==0
   % if condition is true, the two successive months are the same
   if sum(temp1<0.01)>5||sum(temp2<0.01)>5||sum(temp3<0.01)>5
       p(ind1)=nan;
       p(ind2)=nan;
   end
end
end

function p=f_outlier(p)
flag=1;
lenp=length(p);
while flag
    flag=0;
    ind=find(p>5); % it is impossible that precipitation under 5 mm/day is outlier
    for i=1:length(ind)
        indi=ind(i);
        if indi<=15
            startind=1;
            endind=31;
        elseif indi>lenp-15
            startind=lenp-30;
            endind=lenp;
        else
            startind=indi-15;
            endind=indi+15;
        end
        pwin=p(startind:endind);
        mm=nanmean(pwin);
        sd=nanstd(pwin);
        if p(ind(i))>9*sd+mm
            p(ind(i))=nan;
            flag=1;
        end
    end
end
end

function p=f_isolate(p,pne)
if ~isempty(pne)
    nsta=size(pne,2);
    % differences between the target
    % and each neighboring station through all available
    % periods and then found the value that corresponded to the
    % 99.99 percentile of those differences
    Sdiff=[];
    for i=1:nsta
        temp=p-pne(:,i);
        temp(isnan(temp)|temp<0)=[];
        Sdiff=cat(1,Sdiff,temp);
    end
    if length(Sdiff)>1000 
        Sthres=prctile(Sdiff,99.99);
    else
%         Sthres=2000; % a very large value
        % if there is not enough sample, return without isolate check
        return
    end
    % difference between precipitations at the target station for two successive days
    p2=[p(2:end);nan];
    Tdiff=abs(p-p2);
    Tdiff(isnan(Tdiff))=[];
    if length(Tdiff)>1000
        Tthres=prctile(Tdiff,99.99);
    else
%         Tthres=2000;
        % if there is not enough sample, return without isolate check
        return
    end
    
    % determine..
    ind=find(p>5); % assumption: 5 mm/day cannot be an error
    indlen=length(ind);
    if ~isempty(ind)
        for i=1:indlen
            indi=ind(i);
            pi=p(indi);
            pnei=pne(indi,:);
            % three conditions
            diff1=pi-pnei;
            diff1=diff1';
            if indi==1
                diff2=pi-p(indi+1);
            elseif indi==length(p)
                diff2=pi-p(indi-1);
            else
                diff2=[pi-p(indi-1); pi-p(indi+1)];
            end
            if all(diff1>Sthres)&&all(diff2>Tthres)
                p(indi)=nan;
            end
        end
    end
end
end

function p=f_Beck(p)
flag=1;
% Check errors using part of Becks criteria
pu=unique(p);
if length(pu)<15
    flag=0;
end

if flag==1
    pratio=sum(p>=0.5)/sum(p>=0);
    if pratio<=0.005
        flag=0;
    end
end

if flag==1
    p2=p;
    m1=max(p2);
    ind1=p2==m1;
    num1=sum(ind1);
    
    p2(ind1)=nan;
    m2=max(p2);
    ind2=p2==m2;
    num2=sum(ind2);
    if num1>3||num2>3
        flag=0;
    end
end

if flag==0
   p(:)=nan; % if one or more conditions are met, p is deleted by assigning nan values 
end

end