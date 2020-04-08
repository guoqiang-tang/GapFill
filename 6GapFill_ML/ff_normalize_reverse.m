function data2=ff_normalize_reverse(data,m,s)
data2=data*s+m;
data2(data2<0)=0;
end