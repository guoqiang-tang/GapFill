function [TLRout,TLRdate]=f_TLR_process(TLRfile,XX1,YY1)
load(TLRfile,'TLRori','latM0','lonM0','year');
% -180 to 180 --- 0 to 360
if max(XX1(:))>180
    lonM0=lonM0+360;
end

% add one year (1979)
TLRclim=nan*zeros(size(TLRori,1),size(TLRori,2),12);
for i=1:12
    temp=TLRori(:,:,i:12:end);
    TLRclim(:,:,i)=nanmean(temp,3);
end
TLRori=cat(3,TLRclim,TLRori);

TLRout=nan*zeros(size(XX1,1),size(XX1,2),40*12);
for i=1:480
    temp=TLRori(:,:,i);
    temp2=interp2(latM0,lonM0,temp,YY1,XX1,'nearest');
    TLRout(:,:,i)=temp2;
end

TLRdate=zeros(480,1);
flag=1;
for i=1979:2018
    for j=1:12
        TLRdate(flag)=i*100+j;
        flag=flag+1;
    end
end
end