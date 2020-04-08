function [scd_data,scd_source,scd_metric]=ff_Fill_decide_DOY(data_obs,met_in,data_in,doy,R_NR)
scd_data=nan*ones(size(data_in,1),1);
scd_source=nan*ones(size(data_in,1),1);

% find best filling for each month according to KGE
for dd=1:366
    indd=doy==dd;
    metd=met_in(dd+1,:);
    if sum(isnan(metd))>5
        metd=met_in(1,:);
    end

    [metd,metdindex]=sort(metd,'descend');
    metdindex(isnan(metd))=[];
    metd(isnan(metd))=[];
    if isempty(metd)
        continue;
    end

    data_dd=data_in(indd,:);
    
    filldd=data_dd(:,metdindex(1));
    sourcedd=zeros(length(filldd),1);
    sourcedd(:)=metdindex(1);
    
    % if there is still gap, fill it using the second best one
    indnan=isnan(filldd);
    flag=2;
    while sum(indnan)>0 && flag<=length(metdindex)
        filldd(indnan)=data_dd(indnan,metdindex(flag));
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
        metd=met_in(dd+1,reanum);
        indrea=find(metd==max(metd));
        if ~isempty(indrea)
            filldd(indnan)=data_dd(indnan,reanum(indrea(1)));
            sourcedd(indnan)=reanum(indrea(1));
        end
    end
    
    scd_data(indd)=filldd;
    scd_source(indd)=sourcedd;
end

% calculate the metric of the final scd
scd_metric=nan*zeros(367,16);
scd_metric(1,:)=f_metric_cal(data_obs,scd_data,R_NR);
for dd=1:366
    inddd=doy==dd;
    scd_metric(dd+1,:)=f_metric_cal(data_obs(inddd),scd_data(inddd),R_NR);
end
end