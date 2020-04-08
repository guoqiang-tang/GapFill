function scdout=f_cdf_corr(scdin,obsin,doy,doycorr)

if doycorr==1
    [CDFstn,CDFvstn]=ff_CDF_DOY(obsin,doy);
    [CDFfill,CDFvfill]=ff_CDF_DOY(scdin,doy);
    
    scdout=nan*zeros(size(scdin));
    for dd=1:366
        inddd=doy==dd;
        d1=obsin(inddd);
        d2=scdin(inddd);
        d2corr=d2*nan;
        for i=1:length(d1)
            valuei=ff_cdfMatch(CDFstn{dd},CDFvstn{dd},CDFfill{dd},CDFvfill{dd},d2(i));
            d2corr(i)=valuei;
        end
        scdout(inddd)=d2corr;
    end
    scdout(isnan(scdout))=scdin(isnan(scdout));
else
    [CDFstn,CDFvstn]=ecdf(obsin);
    [CDFfill,CDFvfill]=ecdf(scdin);
    if CDFvstn(1)==CDFvstn(2) % that almost always happens
        CDFstn(1)=[];
        CDFvstn(1)=[];
    end
    if CDFvfill(1)==CDFvfill(2) % that almost always happens
        CDFfill(1)=[];
        CDFvfill(1)=[];
    end
    scdout=nan*zeros(size(scdin));
    for i=1:length(scdin)
        valuei=ff_cdfMatch(CDFstn,CDFvstn,CDFfill,CDFvfill,scdin(i));
        scdout(i)=valuei;
    end
end
end