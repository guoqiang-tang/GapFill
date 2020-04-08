function [m,s,data2]=ff_normalize(data)
m=mean(data);
s=std(data);
data2=(data-m)/s;
end

