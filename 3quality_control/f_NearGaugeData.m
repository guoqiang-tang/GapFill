function pne=f_NearGaugeData(Inpath,IDne,datetar)
pne=nan*zeros(length(datetar),length(IDne));
for i=1:length(IDne)
   file=[Inpath,'/',IDne{i},'.mat'];
   load(file,'data');
   datei=data(:,1);
   [x1,x2]=ismember(datei,datetar);
   x2(x2==0)=[];
   pne(x2,i)=data(x1,2); % precipitation
   clear data
end
end