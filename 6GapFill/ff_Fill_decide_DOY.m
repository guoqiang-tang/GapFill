function [VarFill_final,SourceFill_final,MetFill_final]=ff_Fill_decide_DOY(data_stngg,MetFill_all,VarFill_all,doy,R_NR)
VarFill_final=nan*ones(size(VarFill_all,1),1);
SourceFill_final=nan*ones(size(VarFill_all,1),1);

% find best filling for each month according to KGE
for dd=1:366
    metd=nan*ones(length(MetFill_all),1);
    for n=1:length(MetFill_all)
        metd(n)=MetFill_all{n}(dd+1,12); % this is KGE
    end
    % for prcp, sometimes all prcp for a DOY is zero, making metrics absent
    % for this case, using yearly metric
    if sum(~isnan(metd))==0
        metd=nan*ones(length(MetFill_all),1);
        for n=1:length(MetFill_all)
            metd(n)=MetFill_all{n}(1,12); % this is KGE
        end
    end

    [metd,metdindex]=sort(metd,'descend');
    metdindex(isnan(metd))=[];
    metd(isnan(metd))=[];
    if isempty(metd)
        continue;
    end
    indd=doy==dd;
    
    VarFill_alldd=VarFill_all(indd,:);
    filldd=VarFill_alldd(:,metdindex(1));
    sourcedd=zeros(length(filldd),1);
    sourcedd(:)=metdindex(1);
    indnan=isnan(filldd);
    
    % if there is still gap, fill it using the second best one
    flag=2;
    while sum(indnan)>0 && flag<=length(metdindex)
        filldd(indnan)=VarFill_alldd(indnan,metdindex(flag));
        sourcedd(indnan)=metdindex(flag);
        indnan=isnan(filldd);
        flag=flag+1;
    end

    % even after that, filldd can still have gap because reanalysis filled
    % data may not have metrics sometimes (i.e., all reanalysis filled data
    % are zero)
    indnan=isnan(filldd);
    if sum(indnan)>0
        reanum=[5,6,8,9]; % MERRA2 does not have data for 1979. To be simple, don't use it
        metd=nan*ones(length(reanum),1);
        for n=1:length(reanum)
            metd(n)=MetFill_all{reanum(n)}(1,12); % this is KGE
        end
        indrea=find(metd==max(metd));
        if ~isempty(indrea)
            fillrea=VarFill_alldd(:,reanum(indrea(1)));
            filldd(indnan)=fillrea(indnan);
            sourcedd(indnan)=reanum(indrea(1));
        end
    end
    
    VarFill_final(indd)=filldd;
    SourceFill_final(indd)=sourcedd;
end

% calculate the yearly metric of the final filled value
MetFill_final=nan*zeros(367,16);
metricyy=f_metric_cal(data_stngg,VarFill_final,R_NR);
MetFill_final(1,:)=metricyy;
for dd=1:366
    inddd=doy==dd;
    metricdd=f_metric_cal(data_stngg(inddd),VarFill_final(inddd),R_NR);
    MetFill_final(dd+1,:)=metricdd;
end
end