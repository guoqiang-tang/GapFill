function INDEX=f_metric_cal(Rain_G,Rain_S,R_NR)
%Rain_G: Gauge Precipitation
%Rain_S: Satellite Precipitation
indno=isnan(Rain_G)|isnan(Rain_S);
Rain_G(indno)=[]; Rain_S(indno)=[];

INDEX=nan*zeros(1,16); 
if length(Rain_G)>2
    INDEX(1)=corr(Rain_G,Rain_S,'Type','Pearson');  %CC
    INDEX(2)=sqrt(sum((Rain_G-Rain_S).^2)/length(Rain_S)); %RMSE
    INDEX(3)=sum(Rain_S-Rain_G)/length(Rain_S);  %ME
    INDEX(4)=sum(Rain_S-Rain_G)/sum(Rain_G);     %BIAS
    INDEX(5)=sum(abs(Rain_S-Rain_G))/length(Rain_S);  %MAE 
    INDEX(6)=sum(abs(Rain_S-Rain_G))/sum(Rain_G);  %ABIAS 
end


% R_NR: Rain or No Rain
% POD(Probability of Detection),FOH(frequency of hit)
% FAR(False Alarm Ratio),CSI(Critical Success Index,HSS(Heidke’s skill
% score),Ebert et al. [2007]
% [Rain_G,Rain_S]=Data_screening(Rain_G,Rain_S);  %筛选原始数据
if length(Rain_G)>2 && ~isnan(R_NR)
    n11=sum((Rain_G>=R_NR&Rain_S>=R_NR));
    n10=sum((Rain_G<R_NR&Rain_S>=R_NR));
    n01=sum((Rain_G>=R_NR&Rain_S<R_NR));
    n00=sum((Rain_G<R_NR&Rain_S<R_NR));

    INDEX(7)=n11/(n11+n01);  %POD,perfect value 1
    INDEX(8)=n11/(n11+n10);  %FOH,perfect value 1
    INDEX(9)=1-INDEX(8);     %FAR,perfect value 0
    INDEX(10)=n11/(n11+n01+n10);     %CSI,perfect value 1
    INDEX(11)=2*(n11*n00-n10*n01)/((n11+n01)*(n01+n00)+(n11+n10)*(n10+n00));  %HSS
end

% KGE
KGEgroup=ff_KGE(Rain_G,Rain_S);
INDEX(12:15)=KGEgroup;

INDEX(16)=length(Rain_G);
end