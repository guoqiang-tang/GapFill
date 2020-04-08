function [cdf,cdfv]=f_ecdf(data)
data=data(:);
data(isnan(data))=[];
if isempty(data)
    cdf=[]; cdfv=[];
    return;
end

data=sort(data,'ascend');
prob=(1:length(data))'/length(data);
t = (diff(data) == 0);

data(t)=[];
prob(t)=[];

cdfv=[data(1);data];
cdf=[0;prob];
end