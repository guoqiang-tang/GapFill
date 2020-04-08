function CCrea=f_CCrea(FileGauge,FileRea,varvv)
if strcmp(varvv,'prcp')
    CCtype='Spearman';
else
    CCtype='Pearson';
end
% read station data
dstn=ncread(FileGauge,varvv);
nstn=size(dstn,2);
qf1=ncread(FileGauge,[varvv,'_qf']);
qf2=ncread(FileGauge,[varvv,'_qfraw']);
dstn(qf1>0|qf2>0)=nan; clear qf1 qf2

CCrea=nan*zeros(length(FileRea),nstn);
for pp=1:length(FileRea)
    FileReapp=FileRea{pp};
    % read analysis data
    drea=ncread(FileReapp,varvv);
    if strcmp(varvv,'prcp')
       drea(drea<0)=0; 
    end
    for g=1:nstn
        if mod(g,100)==0
            fprintf('CCrea--var %s--product %d--station %d\n',varvv,pp,g);
        end
        dg=[dstn(:,g),drea(:,g)];
        dg(isnan(dg(:,1))|isnan(dg(:,2)),:)=[];
        if length(dg)>3
            CCrea(pp,g)=corr(dg(:,1),dg(:,2),'Type',CCtype);
        end
    end
end
end