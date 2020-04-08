function f_FillGap_ML(OutpathFillvv,FileGauge,FileRea,IDne_numvv,varvv,Validnum,StnTLR,LSTMflag,stnorder)
% dbstop if error
%1. read station data
% basic information
ID=ncread(FileGauge,'ID');
LLE=ncread(FileGauge,'LLE');
date=ncread(FileGauge,'date');
yyyy=floor(date/10000);
rd=floor(mod(date,10000)/100);
dd=mod(date,100);
doy=datenum(yyyy,rd,dd)-datenum(yyyy,1,1)+1;

gstn=size(ID,1);
nday=length(date);
num_rea=length(FileRea);

if strcmp(varvv,'prcp')
    R_NR=0.5; % mm/d
else
    R_NR=nan;
end

% find if all files have been generated
dirout=dir(fullfile(OutpathFillvv,'*.mat'));
if length(dirout)==gstn
    return;
end

% variable data. only using data with flag==0
data_stn=ncread(FileGauge,varvv);
data_stn=single(data_stn);
command=['flag1=ncread(FileGauge,''',varvv,'_qf'');'];  %_QC: quality control data
eval(command);
command=['flag2=ncread(FileGauge,''',varvv,'_qfraw'');'];  %_QC: quality control data
eval(command);
data_stn(flag1>0)=nan; data_stn(flag2>0)=nan;
clear flag1 flag2

% basic control of stations using Validnum
samnum1=sum(~isnan(data_stn));
indexfill=samnum1>=Validnum.all;
data_stn(:,~indexfill)=nan;

%3. initialization of outputs
for gg=stnorder(1):stnorder(2)
    fprintf('Filling: %s--current %d--total %d\n',varvv,gg,stnorder(2));
    IDgg=ID(gg,:); LLEgg=LLE(gg,:);
    outfilegg=[OutpathFillvv,'/',num2str(gg),'.mat'];
    if exist(outfilegg,'file'); continue; end
    
    % 4. gap filling preparation
    %4.1 basic identification
    if ~indexfill(gg)  % the station does not satisfy Validnum
        save(outfilegg,'gg');
        continue;
    end
    
    %4.1 read data: read target station data and its cdf data
    % separte it into two parts
    data_stngg=data_stn(:,gg);
    tlr_stngg=StnTLR(:,gg);
    
    %4.1 read data: read NE (neighboring) stations and cdf data (all doy 1-366)
    IDne_numgg=IDne_numvv(gg,:); %[30]
    IDne_numgg(isnan(IDne_numgg))=[];
    if ~isempty(IDne_numgg)
        data_stn_negg=data_stn(:,IDne_numgg);
        
        % calculate temperatrue difference between the target
        %station and neighboring stations
        
        EleDiff=(LLE(gg,3)-LLE(IDne_numgg,3))/1000; % km
        TEMPdiff_ne_all=zeros(nday,length(EleDiff));
        if strcmp(varvv,'tmin') || strcmp(varvv,'tmax')
            for i=1:length(EleDiff)
                TEMPdiff_ne_all(:,i)=EleDiff(i)*tlr_stngg;
            end
            data_stn_negg=data_stn_negg+TEMPdiff_ne_all;
        end
    else
        data_stn_negg=[];
    end
    %4.1 read data: read reanalysis data and calculate cdf
    data_reagg=nan*zeros(nday,num_rea);
    for i=1:num_rea
        tempi=ncread(FileRea{i},varvv,[1,gg],[Inf,1]);
        data_reagg(:,i)=tempi;
    end
    if strcmp(varvv,'prcp')
        data_reagg(data_reagg<0)=0; % sometimes there are very small negative values
    end
    
    % Start gap filling
    % initialization
    if LSTMflag==1
        FillName_ML={'ANN','RF','LSTM','Median of ANN/RF/LSTM'};
    else
        FillName_ML={'ANN','RF'};
    end
    numML=length(FillName_ML);
    VarFill_MLobs=nan*zeros(nday,numML);
    VarFill_MLreco=nan*zeros(nday,numML);
    MetFill_name.dim1={'all year, and doy 1 to 366'};
    MetFill_name.dim2={'CC','ME','RMSE','BIAS','MAE','ABIAS','POD','FOH','FAR','CSI','HSS','KGE', 'r', 'gamma', 'beta', 'sample number'};
    MetFill_MLobs=cell(numML,1);
    MetFill_MLobs(:)={nan*zeros(367,16)};
    MetFill_MLreco=MetFill_MLobs; % for identifying reconstruction filling source
    
    % Machine learning filling:
    % Data preparation:
    [xdata,ydata,xcomb]=ff_MLdata(data_reagg,data_stn_negg,data_stngg);
    if isempty(xdata)
        save(outfilegg,'gg');
        continue;
    end
    % estimate
% % %     [ANNscd,RFscd,LSTMscd]=f_MLfill(xdata,ydata,xcomb,varvv,LSTMflag); 
    [~,~,LSTMscd]=f_MLfill(xdata,ydata,xcomb,varvv,LSTMflag);
    fileexist=['../FillData/ML_',varvv,'/',num2str(gg),'.mat'];
    load(fileexist,'VarFill_MLobs','VarFill_MLreco');
    
% % %     VarFill_MLobs(:,1)=ANNscd(:,1);
% % %     VarFill_MLobs(:,2)=RFscd(:,1);
    if LSTMflag==1
        VarFill_MLobs(:,3)=LSTMscd(:,1);
        VarFill_MLobs(:,4)=nanmedian(VarFill_MLobs(:,1:3),2);
    end
    
% % %     VarFill_MLreco(:,1)=ANNscd(:,2);
% % %     VarFill_MLreco(:,2)=RFscd(:,2);
    if LSTMflag==1
        VarFill_MLreco(:,3)=LSTMscd(:,2);
        VarFill_MLreco(:,4)=nanmedian(VarFill_MLreco(:,1:3),2);
    end
    
    % evaluate
    for i=1:numML
        metricyy=f_metric_cal(data_stngg,VarFill_MLobs(:,i),R_NR);
        MetFill_MLobs{i}(1,:)=metricyy;
        metricyy=f_metric_cal(data_stngg,VarFill_MLreco(:,i),R_NR);
        MetFill_MLreco{i}(1,:)=metricyy;
        for dd=1:366
            inddd=doy==dd;
            metricdd=f_metric_cal(data_stngg(inddd),VarFill_MLobs(inddd,i),R_NR);
            MetFill_MLobs{i}(dd+1,:)=metricdd;
            metricdd=f_metric_cal(data_stngg(inddd),VarFill_MLreco(inddd,i),R_NR);
            MetFill_MLreco{i}(dd+1,:)=metricdd;
        end
    end
    NumComb=size(xcomb,1);
    save(outfilegg,'VarFill_MLobs','VarFill_MLreco','MetFill_MLobs','MetFill_MLreco','FillName_ML','MetFill_name','IDgg','LLEgg','gg','data_stngg','NumComb','-v7.3');
end
end


