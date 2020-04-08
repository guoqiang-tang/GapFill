function StnTLR=f_GaugeTLR(FileTLRin,FileTLRout,LLE,date)
if exist(FileTLRout,'file')
   load(FileTLRout,'StnTLR');
   return;
end

load(FileTLRin,'TLRori','latM0','lonM0');
% fill 1979
TLRtemp=nan*zeros(size(TLRori,1),size(TLRori,2),12);
for i=1:12
    temp=TLRori(:,:,i:12:end);
    TLRtemp(:,:,i)=nanmean(temp,3);
end
TLRori=cat(3,TLRtemp,TLRori);

% calculate the location of station in the gridded map
row=floor((LLE(:,2)-lonM0(1))/0.625)+1;
col=floor((LLE(:,1)-latM0(1))/0.5)+1;
indrc=sub2ind([size(TLRori,1),size(TLRori,2)],row,col);

% station tlr
StnTLR=nan*zeros(length(date),length(LLE));
yyyymm=floor(date/100);
yyyymmu=unique(yyyymm);
if length(yyyymmu)~=size(TLRori,3)
   error('Error date of TLR'); 
end

for i=1:length(yyyymmu)
    tlri=TLRori(:,:,i);
    stntlri=tlri(indrc);
    
    indi=yyyymm==yyyymmu(i);
    numi=sum(indi);
    stntlri=repmat(stntlri(:)',numi,1);
    StnTLR(indi,:)=stntlri;
end

save(FileTLRout,'StnTLR','date','LLE','-v7.3');
end