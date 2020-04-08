function [scd_final,scd_finalsource,scd_fillmetric,scd_recometric,data_fill,data_reco,met_fill,met_reco]=f_scd_generate(infile1,infile2,varvv,doy,R_NR)
% load data
if ~exist(infile1,'file')
   error('File %s does not exist.',infile1);
end
if ~exist(infile2,'file')
   error('File %s does not exist.',infile2);
end

load(infile1,'VarFill_allg', 'VarFill_allgReco','data_stngg');
load(infile2,'VarFill_MLobs', 'VarFill_MLreco');
if ~exist('VarFill_allg','var')
    scd_final=[];scd_finalsource=[];scd_fillmetric=[];scd_recometric=[];data_fill=[];data_reco=[];met_fill=[];met_reco=[];
    return;
end
nday=length(data_stngg);

% For INT-1 (MLAD), there could be very large or small values due to
% regression problems. This problem will also affect INT-4.
% Thus, upper and lower bound must be set
data_int1=VarFill_allg(:,9); dtemp=VarFill_allg; dtemp(:,[9,12])=[];
min_temp=min(dtemp,[],2);
min_index=data_int1<min_temp;
max_temp=max(dtemp,[],2);
max_index=data_int1>min_temp;
VarFill_allg(min_index,9)=min_temp(min_index);
VarFill_allg(max_index,9)=max_temp(max_index);
VarFill_allg(:,12)=nanmedian(VarFill_allg(:,9:11),2);

data_int1=VarFill_allgReco(:,9); dtemp=VarFill_allgReco; dtemp(:,[9,12])=[];
min_temp=min(dtemp,[],2);
min_index=data_int1<min_temp;
max_temp=max(dtemp,[],2);
max_index=data_int1>min_temp;
VarFill_allgReco(min_index,9)=min_temp(min_index);
VarFill_allgReco(max_index,9)=max_temp(max_index);
VarFill_allgReco(:,12)=nanmedian(VarFill_allgReco(:,9:11),2);

% this is because processing of prcp and tmin/tmax are different
if exist('VarFill_MLobs','var')
    data_fill=[VarFill_allg,VarFill_MLobs];
    data_reco=[VarFill_allgReco,VarFill_MLreco];
else
    add1=VarFill_allg(:,1:2)*nan;
    data_fill=[VarFill_allg,add1];
    data_reco=[VarFill_allgReco,add1];
end

% outlier check-1
if strcmp(varvv,'prcp')
    bound=[0,1828.8];
    data_fill(data_fill<bound(1))=0;
    data_fill(data_fill>bound(2))=nan;
    data_reco(data_reco<bound(1))=0;
    data_reco(data_reco>bound(2))=nan;
elseif strcmp(varvv,'tmin') || strcmp(varvv,'tmax')
    bound=[-89.4,57.7]; 
    data_fill(data_fill<bound(1) | data_fill>bound(2))=nan;
    data_reco(data_reco<bound(1) | data_reco>bound(2))=nan;
end

% extract station data (30%) for reconstruction evaluation.
indexobs=find(~isnan(data_stngg));
data_stnggReco=data_stngg;  % RE: provide metric for reconstruction
data_stnggReco(1:indexobs(floor(length(indexobs)*0.7)))=nan;

% define observation and reconstruction periods
IndexFill0=zeros(length(data_stngg),1);
IndexFill0(indexobs(1):indexobs(end))=1;
for i=1:length(indexobs)-1
   if indexobs(i+1)-indexobs(i)-1>365 % if the gap between two valid observations >365 day, the gap should be considered as reconstruction period
       IndexFill0(indexobs(i)+1:indexobs(i+1)-1)=0;
   end
end
IndexReco=IndexFill0==0; % data belong to reconstruction beyond observation period
IndexFill=IndexFill0==1; % data belong to filling within observation period

% outlier check-2
% variance check
for i=1:nday
    if IndexReco(i)
       temp=data_fill(i,:);
       temp(temp>nanmean(temp)+2*nanstd(temp))=nan;
       data_fill(i,:)=temp;
       
       temp=data_reco(i,:);
       temp(temp>nanmean(temp)+2*nanstd(temp))=nan;
       data_reco(i,:)=temp;
    end
end

% evaluate the accuracy of data_fill and data_reco
met_fill=cell(size(data_fill,2),1);
met_reco=cell(size(data_fill,2),1);
met_fill(:)={nan*zeros(367,16)};
met_reco(:)={nan*zeros(367,16)};
for dd=1:366
    inddd=doy==dd;
    for i=1:size(data_fill,2)
        met_fill{i}(dd+1,:)=f_metric_cal(data_stngg(inddd),data_fill(inddd,i),R_NR);
        met_reco{i}(dd+1,:)=f_metric_cal(data_stnggReco(inddd),data_reco(inddd,i),R_NR);
    end
end
for i=1:size(data_fill,2)
    met_fill{i}(1,:)=f_metric_cal(data_stngg,data_fill(:,i),R_NR);
    met_reco{i}(1,:)=f_metric_cal(data_stnggReco,data_reco(:,i),R_NR);
end

% implement two merging strategies (MRG-1, MRG-2)
% IndexMerge=[1,2,3,5,6,7,10,11,12,14,15]; % only 11 independent strategies are used
IndexMerge=[1,2,3,5,6,7,9,10,11,13,14];
nmer=length(IndexMerge);
merge_fill=nan*zeros(nday,2);
merge_reco=nan*zeros(nday,2);
merge_met_fill=cell(2,1);
merge_met_fill(:)={nan*zeros(367,16)};
merge_met_reco=merge_met_fill;
for dd=1:366
    inddd=doy==dd;
    KGEfill=nan*zeros(nmer,1);
    KGEreco=nan*zeros(nmer,1);
    for i=1:nmer
        KGEfill(i)=met_fill{IndexMerge(i)}(dd+1,12); % 12 is KGE
        KGEreco(i)=met_reco{IndexMerge(i)}(dd+1,12);
    end
    if sum(isnan(KGEfill))>5 || sum(isnan(KGEreco))>5 % replace doy by year kge
       for i=1:nmer
            KGEfill(i)=met_fill{IndexMerge(i)}(1,12);
            KGEreco(i)=met_reco{IndexMerge(i)}(1,12);
        end 
    end
    
    merge_fill(inddd,1:2)=ff_MergeFill_DOY(KGEfill,data_fill(inddd,IndexMerge));
    merge_reco(inddd,1:2)=ff_MergeFill_DOY(KGEreco,data_reco(inddd,IndexMerge));
    
    for i=1:2
        merge_met_fill{i}(dd+1,:)=f_metric_cal(data_stngg(inddd),merge_fill(inddd,i),R_NR);
        merge_met_reco{i}(dd+1,:)=f_metric_cal(data_stnggReco(inddd),merge_reco(inddd,i),R_NR);
    end
end

for i=1:2
    merge_met_fill{i}(1,:)=f_metric_cal(data_stngg,merge_fill(:,i),R_NR);
    merge_met_reco{i}(1,:)=f_metric_cal(data_stnggReco,merge_reco(:,i),R_NR);
end

% merge data_fill/reco and merge_fill/reco
data_fill=[data_fill,merge_fill];
data_reco=[data_reco,merge_reco];
met_fill=cat(1,met_fill,merge_met_fill);
met_reco=cat(1,met_reco,merge_met_reco);


% generate the scd for filling and reconstruction periods
kge_fill=nan*zeros(367,length(met_fill)); kge_reco=nan*zeros(367,length(met_reco));
for i=1:length(met_fill)
    kge_fill(:,i)=met_fill{i}(:,12);
    kge_reco(:,i)=met_reco{i}(:,12);
end

[scd_fill,scd_fillsource,scd_fillmetric]=ff_Fill_decide_DOY(data_stngg,kge_fill,data_fill,doy,R_NR);
[~,scd_recosource,scd_recometric]=ff_Fill_decide_DOY(data_stnggReco,kge_reco,data_reco,doy,R_NR); % reco_metric and source should be based on data_reco
[scd_reco,~,~]=ff_Fill_decide_DOY(data_stnggReco,kge_reco,data_fill,doy,R_NR);  % scd_reco should be based on data_fill
if sum(isnan(scd_reco))>0
    scd_reco(isnan(scd_reco))=scd_fill(isnan(scd_reco)); % in case there are no enough observations in the reconstruction period for estimation
end

% generate the final scd
scd_final=nan*zeros(nday,1);
scd_finalsource=nan*zeros(nday,1);
scd_final(IndexFill)=scd_fill(IndexFill);
scd_finalsource(IndexFill)=scd_fillsource(IndexFill);
scd_final(IndexReco)=scd_reco(IndexReco);
scd_finalsource(IndexReco)=scd_recosource(IndexReco);

% check if the filled estimates are enough
% sometimes, observations data are only available in summer and wintertime
% cannot be filled
% sometimes, observations have too many zero values, resluting the failure
% of metric calculation and thus the failure in finding the best strategy
% to fill the SCD
numi=sum(~isnan(scd_final));
if numi<nday && numi>=nday*0.99 % the missing values are not so many. try to fill the missing values using SCD estimates from 15 strategies
    metd=nan*ones(length(met_fill),1);
    for n=1:length(met_fill)
        metd(n)=met_fill{n}(1,12); % this is KGE for all data
    end
    [metd,metdindex]=sort(metd,'descend');
    metdindex(isnan(metd))=[];

    indnan=isnan(scd_final);
    flag=1;
    while sum(indnan)>0 && flag<=length(metdindex)
        scd_final(indnan)=data_fill(indnan,metdindex(flag));
        scd_finalsource(indnan)=metdindex(flag);
        indnan=isnan(scd_final);
        flag=flag+1;
    end
end

% final check, if not satisfied, discard station
if sum(isnan(scd_final))>0 || sum(isnan(scd_fillmetric(:,2)))>20 % RMSE
    scd_final(:)=nan;
end
end




