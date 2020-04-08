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