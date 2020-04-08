function f_GaugeCDF_DOY(FileGauge,StnCDFpath_DOY,prob,varnames,Validnum)
% dbstop if error
ID=ncread(FileGauge,'ID');
LLE=ncread(FileGauge,'LLE');
date=ncread(FileGauge,'date');
yyyy=floor(date/10000);
mm=floor(mod(date,10000)/100);
dd=mod(date,100);
doy=datenum(yyyy,mm,dd)-datenum(yyyy,1,1)+1;
Nprob=length(prob);
nstn=size(ID,1); % gauge number
nchar=size(ID,2);

for vv=1:length(varnames)
    StnCDFfile=[StnCDFpath_DOY,'/CDF_DOY_366.nc4'];
    if exist(StnCDFfile,'file')
        continue;
    end
    
    % read the data
    varvv=varnames{vv};
    command=['datavv=ncread(FileGauge,''',varvv,''');'];  %_QC: quality control data
    eval(command);
    command=['flag1=ncread(FileGauge,''',varvv,'_qf'');'];  %_QC: quality control data
    eval(command);
    command=['flag2=ncread(FileGauge,''',varvv,'_qfraw'');'];  %_QC: quality control data
    eval(command);
    datavv(flag1>0)=nan;
    datavv(flag2>0)=nan;
    clear flag1 flag2
    
    % find stations that don't satisfy Validnum
    temp1=sum(~isnan(datavv));
    indno=temp1<Validnum.all;
    datavv(:,indno)=nan;
    
    for dd=1:366
        StnCDFfile=[StnCDFpath_DOY,'/CDF_DOY_',num2str(dd),'.nc4'];
        if exist(StnCDFfile,'file')
            info=ncinfo(StnCDFfile);
            var=info.Variables;
            flag=0;
            for iv=1:length(var)
                if strcmp(var(iv).Name,[varvv,'_CDF'])
                    flag=1;
                    break;
                end
            end
           if flag==1
            continue; 
           end
        end
        
        ddrange=dd-15:dd+15;
        if dd<=15
            ddrange(ddrange<1)=ddrange(ddrange<1)+366;
        end
        if dd>=352
            ddrange(ddrange>366)=ddrange(ddrange>366)-366;
        end
        inddd=ismember(doy,ddrange);
        % initialize CDF
        data_CDF=nan*zeros(nstn,Nprob);
        
        % loop for stations
        for gg=1:nstn
            fprintf('var %d--dd %d--i %d--nstn %d\n',vv,dd,gg,nstn);
            datai=datavv(inddd,gg);
            datai(isnan(datai))=[];
            if length(datai)<100
                continue;
            end

            [probi,probvi]=ecdf(datai); % probability and probability corresponded var value
            CDFi=interp1(probi,probvi,prob); % interpolate the empirical cdf to regular probability increments
            data_CDF(gg,:)=CDFi;
        end
        
        % save data
        var1=[varvv,'_CDF'];
        
        data_CDF(isnan(data_CDF))=-999;
        nccreate(StnCDFfile,var1,'Datatype','double',...
            'Dimensions',{'nstn',size(data_CDF,1),'probs',size(data_CDF,2)},...
            'Format','netcdf4','DeflateLevel',9,'FillValue',-999);
        ncwrite(StnCDFfile,var1,data_CDF);
        ncwriteatt(StnCDFfile,var1,'description','The CDF of stations for DOY');
        
        if vv==1
            nccreate(StnCDFfile,'ID','Datatype','char','Dimensions',{'nstn',nstn,'nchar',nchar},'Format','netcdf4','DeflateLevel',9);
            ncwrite(StnCDFfile,'ID',ID);
            ncwriteatt(StnCDFfile,'ID','description','station IDs');
            ncwriteatt(StnCDFfile,'ID','Char1-2','station source. GH: ghcn-d, GS: gsod, EC: eccc, ME: mexico, MR: merge');
            ncwriteatt(StnCDFfile,'ID','Char3-end','ID from original sources. For ME, it is Char6-end.');
            ncwriteatt(StnCDFfile,'ID','MergeInfo','MR merges stations with same lat/lon and Char3-end of MR is from the source in order of GH GS EC ME');

            nccreate(StnCDFfile,'LLE','Datatype','double',...
                'Dimensions',{'nstn',nstn,'dimLLE',size(LLE,2)},...
                'Format','netcdf4','DeflateLevel',9,'FillValue',-999);
            ncwrite(StnCDFfile,'LLE',LLE);
            ncwriteatt(StnCDFfile,'LLE','description','latitude, longitude, and elevation');
        end 
    end
end

end