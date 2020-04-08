function TLR_rea=f_TLR_extract(FileTLR,indexg,date)
TLR_rea=nan*zeros(length(date),length(indexg));

load(FileTLR,'TLR010','year'); % each month has a map
yyyymm=floor(date/100);
yyyymmu=unique(yyyymm);

yyyymm2=nan*zeros(length(year)*12,1);
flag=1;
for i=1:length(year)
   for j=1:12
       yyyymm2(flag)=year(i)*100+j;
       flag=flag+1;
   end
end

for i=1:length(yyyymmu)
    indi=find(yyyymm2==yyyymmu(i));
    if isempty(indi)
        indi=mod(yyyymmu(i),100); % the first 12 months (1979) is climatological mean
    end
    TLRi=TLR010(:,:,indi);
    TLRi2=TLRi(indexg);
    TLRi2=TLRi2';
    
    indfill=yyyymm==yyyymmu(i);
    TLRi2=repmat(TLRi2,sum(indfill),1);
    
    TLR_rea(indfill,:)=TLRi2;    
end

end