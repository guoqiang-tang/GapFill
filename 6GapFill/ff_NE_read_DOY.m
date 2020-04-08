function [VarNe,CDFNe,CDFvNe]=ff_NE_read_DOY(IDne_numgg,data_stn,doy)
indno=isnan(IDne_numgg);
IDne_numgg(indno)=[];

if isempty(IDne_numgg)
    VarNe=[];CDFNe=[];CDFvNe=[];
    return;
end

VarNe=data_stn(:,IDne_numgg);  %[date,nearest number]

CDFNe=cell(length(IDne_numgg),1);
CDFvNe=cell(length(IDne_numgg),1);
for i=1:length(IDne_numgg)
    [cdf,cdfv]=ff_CDF_DOY(VarNe(:,i),doy);
    CDFNe{i}=cdf;
    CDFvNe{i}=cdfv;
end

end
