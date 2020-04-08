function flag_clo=f_climoutlier(T,ddd)
flag_clo=zeros(size(T));

[ME,STD]=f_climate_MESTD(T,ddd,1);

Tnorm=(T-ME)./STD;
flag_clo(abs(Tnorm)>=6)=1;
end