function [dcorr,met_corr,cdfflag]=f_correction(dtar,dref,doy,varvv,R_NR)
% cdf correction
doycorr=0;
cdfflag=1;
dcorr=f_cdf_corr(dtar,dref,doy,doycorr);
kge0=ff_KGE(dref,dtar); kge0=kge0(1);
kgecorr=ff_KGE(dref,dcorr); kgecorr=kgecorr(1);
if kgecorr<kge0 && strcmp(varvv,'prcp')
    cdfflag=0;
    % Quantile mapping leads to worse accuracy
    % Use Beck 2019's method, but for eacy DOy
    ind=dtar>=0&dref>=0;
    dstn=dref(ind);
    dfill=dtar(ind);
    wdaystn=sum(dstn>=0.5);
    wdayfill=sum(dfill>=0.5);
    deltav=0;
    while wdayfill>wdaystn
        deltav=deltav+0.01;
        dfill2=dfill-deltav; dfill2(dfill2<0)=0;
        ratio=nansum(dfill)/nansum(dfill2);
        dfill2=dfill2*ratio;
        wdayfill=sum(dfill2>=0.5);
    end
    
    dcorr=dtar;
    dcorr=dcorr-deltav;
    dcorr(dcorr<0)=0;
end


% mean value correction
if strcmp(varvv,'prcp') % ratio-based correction
    indg=~isnan(dref)&~isnan(dcorr);
    ratio=sum(dref(indg))/sum(dcorr(indg));
    if isnan(inf)
        dcorr=dtar;
        ratio=sum(dref(indg))/sum(dcorr(indg));
    end
    
    if ~isnan(ratio) && ~isinf(ratio)
        dcorr=dcorr*ratio;
    end
else  % difference-based correction
    indg=~isnan(dref)&~isnan(dcorr);
    diff=mean(dref(indg))-mean(dcorr(indg));
    dcorr=dcorr+diff;
end

% calculate metric
met_corr=nan*zeros(367,16);
met_corr(1,:)=f_metric_cal(dref,dcorr,R_NR);
for dd=1:366
    inddd=doy==dd;
    met_corr(dd+1,:)=f_metric_cal(dref(inddd),dcorr(inddd),R_NR);
end
end

