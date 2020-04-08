function f_SaveSCD(Inpathvv,Inpathvv_ML,FileGauge,PathMerge,OutPath,FileTLR,varvv,Overwrite,stnorder)
date=ncread(FileGauge,'date');
yyyy=floor(date/10000);
rd=floor(mod(date,10000)/100);
dd=mod(date,100);
doy=datenum(yyyy,rd,dd)-datenum(yyyy,1,1)+1;

if strcmp(varvv,'prcp')
    R_NR=0.5; % mm/d
else
    R_NR=nan;
end

load(FileTLR,'StnTLR');
StnTLR=single(StnTLR);

for i=stnorder(1):stnorder(2)
    fprintf('Processing station %s--%d--Total stations %d\n',varvv,i,stnorder(2));
    %%% read station i
    infile1=[Inpathvv,'/',num2str(i),'.mat'];
    infile2=[Inpathvv_ML,'/',num2str(i),'.mat'];
    load(infile1,'IDgg');
    if exist('IDgg','var')
        outfile=[OutPath,'/',IDgg,'.nc4']; clear IDgg
        if exist(outfile,'file') && Overwrite==0
            fprintf('File exists\n');
           continue; 
        end
    else
       continue; 
    end
    
    [scd_final,scd_finalsource,scd_fillmetric,scd_recometric,data_fill,data_reco,met_fill,met_reco]=f_scd_generate(infile1,infile2,varvv,doy,R_NR);
    if isempty(scd_final) || isnan(scd_final(1))
        continue;
    end
    
    % read obs data
    obs.data=ncread(FileGauge,varvv,[1,i],[14610,1]);
    obs.qflag1=ncread(FileGauge,[varvv,'_qfraw'],[1,i],[14610,1]);
    obs.qflag2=ncread(FileGauge,[varvv,'_qf'],[1,i],[14610,1]);
    tlr=StnTLR(:,i);
    
    % extract metric of all the N strategies
    load(infile1,'IDgg','LLEgg','date');
    est.IDgg=IDgg; est.LLEgg=LLEgg; est.date=date;
    clear IDgg LLEgg date
    est.all=data_fill;

    temp1=nan*zeros(length(met_fill),4); % only save KGE and its three components
    temp2=nan*zeros(length(met_fill),4);
    for n=1:length(met_fill)
        temp1(n,:)=met_fill{n}(1,12:15);
        temp2(n,:)=met_reco{n}(1,12:15);
    end
    est.metfill=temp1; 
    est.metreco=temp2;
    est.dfill=data_fill;
    est.dreco=data_reco;
    est.scd=scd_final;
    est.source=scd_finalsource;
    est.metric=nan*zeros(2,4);
    est.metric=[scd_fillmetric(1,12:15); scd_recometric(1,12:15)];

    %%% CDF and mean-value correction
    dref=obs.data; dref(obs.qflag1>0|obs.qflag2>0)=nan;
    dtar=est.scd;
    [dcorr,met_corr,cdfflag]=f_correction(dtar,dref,doy,varvv,R_NR);

    est.scd_corr=dcorr;
    est.metric_corr=met_corr(:,12:15); %[367,4]
    est.flag_corr=cdfflag;
    % save station i
    f_SaveStation(PathMerge,outfile,obs,est,tlr,varvv,Overwrite);
end

end
