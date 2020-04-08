function  Fill_met=ff_Fill_met_DOY(VarTar,Fill_var,doy)
Fill_met=nan*zeros(367,7); % Pearson CC, Spearman CC, KGE, r,gamma,beta, sample number
for dd=0:366
    if dd==0
        indd=doy>0;
    elseif dd==366
        indd=doy>=365;
    else
        indd=doy==dd;
    end
    ddi=[VarTar(indd),Fill_var(indd)];
    ddi(isnan(ddi(:,1))|isnan(ddi(:,2)),:)=[];
    if size(ddi,1)>2
        Fill_met(dd+1,1)=corr(ddi(:,1),ddi(:,2),'Type','Pearson');
        Fill_met(dd+1,2)=corr(ddi(:,1),ddi(:,2),'Type','Spearman');
        Fill_met(dd+1,3:6)=ff_KGE(ddi(:,1),ddi(:,2));
        Fill_met(dd+1,7)=size(ddi,1);
    end
end
end
