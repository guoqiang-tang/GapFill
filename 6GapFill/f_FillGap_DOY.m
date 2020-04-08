function f_FillGap_DOY(OutpathFillvv,FileGauge,FileRea,IDne_numvv,IDne_ccvv,IDne_distvv,varvv,Validnum,StnTLR,stnorder)
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
nday=length(date);

coun=ID(:,1:2);
coun=num2cell(coun,2);
indME=find(ismember(coun,'ME'));
qqff=zeros(32590,1);
qqff(indME)=1;
for i=1:32590
    temp=squeeze(IDne_numvv(i,:,:));
    if sum(ismember(temp(:),indME))>0
       qqff(i)=1; 
    end
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

%2. read reanalysis data
num_rea=length(FileRea);
% data_rea=cell(num_rea,1);
% for i=1:length(FileRea)
%     tempi=ncread(FileRea{i},varvv);
%     if strcmp(varvv,'prcp')
%         tempi(tempi<0)=0; % sometimes there are very small negative values
%     end
%     data_rea{i}=tempi;
% end

%3. initialization of outputs
for gg=stnorder(1):stnorder(2)
    fprintf('Filling: %s--current %d--total %d\n',varvv,gg,stnorder(2));
    IDgg=ID(gg,:); LLEgg=LLE(gg,:);
    outfilegg=[OutpathFillvv,'/',num2str(gg),'.mat'];
    if qqff(gg)==0
        if exist(outfilegg,'file'); continue; end
    end
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
    [CDFstngg,CDFvstngg]=ff_CDF_DOY(data_stngg,doy);
    
    temp=find(~isnan(data_stngg));
    data_stnggReco=data_stngg;  % RE: provide metric for reconstruction
    data_stnggReco(temp(floor(length(temp)*0.7)):end)=nan;
    [CDFstnggReco,CDFvstnggReco]=ff_CDF_DOY(data_stnggReco,doy);
    
    if isempty(CDFstngg)
        save(outfilegg,'gg');
        continue;
    end
    
    %4.1 read data: read NE (neighboring) stations and cdf data (all doy 1-366)
    IDne_numggall=squeeze(IDne_numvv(gg,:,:)); %[366,30]
    IDne_numggall=unique(IDne_numggall);
    IDne_numggall(isnan(IDne_numggall))=[];
    [data_stn_ne_all,CDFstn_ne_all,CDFvstn_ne_all]=ff_NE_read_DOY(IDne_numggall,data_stn,doy);
    flagemp=zeros(length(IDne_numggall),1);
    for id=1:length(IDne_numggall)
        if isempty(CDFstn_ne_all{id})
            flagemp(id)=1;
        end
    end
    indemp=flagemp==1;
    if sum(indemp)>0
        IDne_numggall(indemp)=[];
        data_stn_ne_all(:,indemp)=[];
        CDFstn_ne_all(indemp)=[];
        CDFvstn_ne_all(indemp)=[];
    end

    % calculate temperatrue difference between the target
    %station and neighboring stations
    EleDiff=(LLE(gg,3)-LLE(IDne_numggall,3))/1000; % km
    TEMPdiff_ne_all=zeros(nday,length(EleDiff));
    if strcmp(varvv,'tmin') || strcmp(varvv,'tmax')
        for i=1:length(EleDiff)
            TEMPdiff_ne_all(:,i)=EleDiff(i)*tlr_stngg;
        end
    end
    
    %4.1 read data: read reanalysis data and calculate cdf
    data_reagg=nan*zeros(nday,num_rea);
    CDF_reagg=cell(num_rea,1);
    CDFv_reagg=cell(num_rea,1);
    for i=1:num_rea
        tempi=ncread(FileRea{i},varvv,[1,gg],[Inf,1]);
        if strcmp(varvv,'prcp')
            tempi(tempi<0)=0; % sometimes there are very small negative values
        end
        data_reagg(:,i)=tempi;
        [cdf,cdfv]=ff_CDF_DOY(data_reagg(:,i),doy);
        CDF_reagg{i}=cdf;
        CDFv_reagg{i}=cdfv;
    end

    % Start gap filling
    
    % initialization
    VarFill_allg=nan*zeros(nday,12);
    VarFill_allgReco=nan*zeros(nday,12);    
    for dd=1:366
        % 4.2 for DOY: extract some basic information
        inddd=doy==dd;
        ndaydd=sum(inddd);
        CDFstnggd=CDFstngg{dd};
        CDFvstnggd=CDFvstngg{dd};
        data_stnggdd=data_stngg(inddd);
        CDFstnggRecod=CDFstnggReco{dd};
        CDFvstnggRecod=CDFvstnggReco{dd};
        data_stnggRecodd=data_stnggReco(inddd);
        
        ddrange=dd-15:dd+15;
        if dd<=15
            ddrange(ddrange<1)=ddrange(ddrange<1)+366;
        end
        if dd>=352
            ddrange(ddrange>366)=ddrange(ddrange>366)-366;
        end
        indddrange=ismember(doy,ddrange);
        
        %4.3 for DOY: read neighboring stations and cdf data
        IDne_numgg=squeeze(IDne_numvv(gg,dd,:)); %[1,30]
        indno=isnan(IDne_numgg);
        IDne_numgg(indno)=[];
        if ~isempty(IDne_numgg)
            [~,indtemp]=ismember(IDne_numgg,IDne_numggall);
            indtempno=indtemp==0;
            indtemp(indtempno)=[];
            data_stn_ne=data_stn_ne_all(:,indtemp);
            TEMPdiff_ne=TEMPdiff_ne_all(:,indtemp);
            CDFstn_ne=CDFstn_ne_all(indtemp);
            CDFvstn_ne=CDFvstn_ne_all(indtemp);
            
            
            flagemp=zeros(length(indtemp),1);
            for id=1:length(indtemp)
                CDFstn_ne{id}=CDFstn_ne{id}{dd};
                CDFvstn_ne{id}=CDFvstn_ne{id}{dd};
                if isempty(CDFstn_ne{id})||isempty(CDFvstn_ne{id})
                    flagemp(id)=1;
                end
            end
            CCstn_ne=squeeze(IDne_ccvv(gg,dd,~indno));
            CCstn_ne(indtempno)=[];
            DISTstn_ne=squeeze(IDne_distvv(gg,dd,~indno));
            DISTstn_ne(indtempno)=[];
            % delete empty CDFstn_ne
            indemp=flagemp==1;
            if sum(indemp)>0
                data_stn_ne(:,indemp)=[];
                TEMPdiff_ne(:,indemp)=[];
                CDFstn_ne(indemp)=[];
                CDFvstn_ne(indemp)=[];
                CCstn_ne(indemp)=[];
                DISTstn_ne(indemp)=[];
            end
            data_stn_nedd=data_stn_ne(inddd,:);
        else
            data_stn_ne=[];CDFstn_ne=[];CDFvstn_ne=[];CCstn_ne=[];DISTstn_ne=[]; TEMPdiff_ne=[]; data_stn_nedd=[];
        end
        
        
        %5. Gap Filling start...
        %5.1 Fill the gap using neareast neighbor (NE) stations
        FillName1={'Closest NE station','Weight-mean using CC','Weight-mean using distance','Median of the three'};
        if ~isempty(CDFstnggd) && ~isempty(CDFstn_ne)
            VarFill_NEdd=ff_NEfill_DOY(data_stn_nedd,CDFstnggd,CDFvstnggd,CDFstn_ne,CDFvstn_ne,CCstn_ne,DISTstn_ne);
            VarFill_allg(inddd,1:4)=VarFill_NEdd;
        end
        if ~isempty(CDFstnggRecod) && ~isempty(CDFstn_ne)
            VarFill_NERecodd=ff_NEfill_DOY(data_stn_nedd,CDFstnggRecod,CDFvstnggRecod,CDFstn_ne,CDFvstn_ne,CCstn_ne,DISTstn_ne);
            VarFill_allgReco(inddd,1:4)=VarFill_NERecodd;
        end
        
        %5.2 Fill the gap using reanalysis
        FillName2={'ERA5','JRA55','MERRA2','Median of the three'};
        VarFill_REAdd=nan*zeros(ndaydd,num_rea+1); %[ndays,4]
        VarFill_REARecodd=nan*zeros(ndaydd,num_rea+1); %[ndays,4]  
        if ~isempty(CDFstnggd)
            % 5.2.1 Fill using ERA5 JRA55 MERRA2
            CCrea=nan*zeros(num_rea,1);
            CCreaReco=nan*zeros(num_rea,1);
            for i=1:num_rea
                VarREArr=data_reagg(inddd,i);
                CDFREAi=CDF_reagg{i};
                CDFvREAi=CDFv_reagg{i};
                for rd=1:ndaydd
                    VarFill_REAdd(rd,i)=ff_cdfMatch(CDFstnggd,CDFvstnggd,CDFREAi{dd},CDFvREAi{dd},VarREArr(rd));     
                    if ~isempty(CDFstnggRecod)
                        VarFill_REARecodd(rd,i)=ff_cdfMatch(CDFstnggRecod,CDFvstnggRecod,CDFREAi{dd},CDFvREAi{dd},VarREArr(rd));
                    end
                end
                % calculate the CC for merging
                if strcmp(varvv,'prcp')
                    CCrea(i)=corr(VarFill_REAdd(:,i),data_stnggdd,'Type','Spearman','rows','complete');
                    CCreaReco(i)=corr(VarFill_REARecodd(:,i),data_stnggRecodd,'Type','Spearman','rows','complete');
                else
                    CCrea(i)=corr(VarFill_REAdd(:,i),data_stnggdd,'Type','Pearson','rows','complete');
                    CCreaReco(i)=corr(VarFill_REARecodd(:,i),data_stnggRecodd,'Type','Pearson','rows','complete');
                end
            end

            %5.2.2 Fill using median
            VarFill_REAdd(:,num_rea+1)=nanmedian(VarFill_REAdd(:,1:num_rea),2);
            VarFill_REARecodd(:,num_rea+1)=nanmedian(VarFill_REARecodd(:,1:num_rea),2);

            VarFill_allg(inddd,5:8)=VarFill_REAdd;
            VarFill_allgReco(inddd,5:8)=VarFill_REARecodd;
        end
        
        %5.3 Fill gap using interpolation method
        FillName3={'MLAD interpolation','Normal Ratio interpolation','IDW interpolation','Median of the three'};
        if ~isempty(data_stn_ne)
            xdata=data_stn_ne(indddrange,:)+TEMPdiff_ne(indddrange,:); % TLR correction. For prcp, VarFill_INTRecodd is always 0
            ydata=data_stngg(indddrange);
            VarFill_INTdd=ff_INTfill_DOY(data_stn_nedd+TEMPdiff_ne(inddd,:),CCstn_ne,DISTstn_ne,xdata,ydata,1);
            
            ydata=data_stnggReco(indddrange);
            VarFill_INTRecodd=ff_INTfill_DOY(data_stn_nedd+TEMPdiff_ne(inddd,:),CCstn_ne,DISTstn_ne,xdata,ydata,0);
            if strcmp(varvv,'prcp')
                VarFill_INTRecodd(VarFill_INTRecodd<0)=0;
                VarFill_INTdd(VarFill_INTdd<0)=0;
            end
            VarFill_INTRecodd(:,2:3)=VarFill_INTdd(:,2:3); % don't need to do statistical interpolation again
            VarFill_INTRecodd(:,4)=nanmedian(VarFill_INTdd(:,1:3),2);

            VarFill_allg(inddd,9:12)=VarFill_INTdd;
            VarFill_allgReco(inddd,9:12)=VarFill_INTRecodd;
        end
    end
 
    KGE=nan*zeros(size(VarFill_allg,2),2);
    for i=1:size(VarFill_allg,2)
       temp=ff_KGE(data_stngg, VarFill_allg(:,i));
       KGE(i,1)=temp(1);
       temp=ff_KGE(data_stnggReco, VarFill_allgReco(:,i));
       KGE(i,2)=temp(1); 
    end
    
    FillName={FillName1,FillName2,FillName3};
    save(outfilegg,...
        'VarFill_allg','VarFill_allgReco',...
        'data_stngg','date','IDgg','LLEgg','KGE',...
        'FillName','-v7.3');
end
end


