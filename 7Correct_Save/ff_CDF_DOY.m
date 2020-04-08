function [cdf,cdfv]=ff_CDF_DOY(data,doy)
indno=isnan(data);
data(indno)=[]; doy(indno)=[];
if isempty(data)
    cdf=[]; cdfv=[];
   return; 
end

cdf=cell(366,1);
cdfv=cell(366,1);
for dd=1:366
    ddrange=dd-15:dd+15;
    if dd<=15
        ddrange(ddrange<1)=ddrange(ddrange<1)+366;
    end
    if dd>=352
        ddrange(ddrange>366)=ddrange(ddrange>366)-366;
    end
    inddd=ismember(doy,ddrange);
    
    datadd=data(inddd);
    if length(datadd)<200
        datadd=data;
    end
    
    [cdfd,cdfvd]=ecdf(datadd);
    if cdfvd(1)==cdfvd(2) % that almost always happens
        cdfd(1)=[];
        cdfvd(1)=[];
    end
    
    cdf{dd}=cdfd;
    cdfv{dd}=cdfvd;
end
end

