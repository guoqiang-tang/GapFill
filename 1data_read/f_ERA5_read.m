function f_ERA5_read(Inpath,FileDEMLow,FileDEMHigh,Outpath,year,BasicInfo,DataInfo,TLRfile)
% read ERA5 data and conduct resolution transform
% ERA5 data is stored by month

% basic information of file characteristics and reading
prefix=DataInfo.prefix;
suffix=DataInfo.suffix;
varname=DataInfo.varname;
imethod=DataInfo.imethod;
prefixout=DataInfo.prefixout;
varnum=length(varname);

% basic information of target region
tXll=BasicInfo.tXll;  % top right
tYll=BasicInfo.tYll;
Xll=BasicInfo.Xll;   % bottom left
Yll=BasicInfo.Yll;
cellsize=BasicInfo.cellsize;  % new resolution
Ncol=(tXll-Xll)/cellsize;
Nrow=(tYll-Yll)/cellsize;
X1=(Xll+cellsize/2):cellsize:(Xll+cellsize*Ncol-cellsize/2); % lat/lon of grid centers
Y1=(Yll+cellsize*Nrow-cellsize/2):-cellsize:(Yll+cellsize/2);
[XX1,YY1]=meshgrid(X1,Y1);

% varables for saving into the structure (info)
varsav={'tXll','tYll','Xll','Yll','Nrow','Ncol','cellsize'};
for i=1:length(varsav)
    command=['info.',varsav{i},'=',varsav{i},';'];
    eval(command);
end

% read temperature lapse rate information
[TLR,TLRdate]=f_TLR_process(TLRfile,XX1,YY1);

for vv=1:varnum  % for each var, re-read the basic information
    % basic information of original ERA5 data. All data in this directory must
    % have the same information
    Infile=[Inpath{vv},'/',prefix{vv},num2str(year(1)),num2str(1,'%.2d'),suffix{vv},'.nc'];
    latori=ncread(Infile,'latitude');
    lonori=ncread(Infile,'longitude');
    latori=sort(latori,'descend'); lonori=sort(lonori,'ascend');
    [XX0,YY0]=meshgrid(lonori,latori);
    REAinfo.Xsize=abs(lonori(2)-lonori(1));
    REAinfo.Ysize=abs(latori(2)-latori(1));
    REAinfo.xll=min(lonori)-REAinfo.Xsize/2;
    REAinfo.yll=min(latori)-REAinfo.Ysize/2;
    REAinfo.nrows=size(XX0,1);
    REAinfo.ncols=size(XX0,2);
    
    % if there exists lapserate in imethod, calcualte temperature changes in
    % each reanalysis grid pixel
    % repeat this part of code in case that different variables have
    % different spatial extent
    if ismember('lapserate',imethod)
        % read DEM data
        % DEMLow must have larger or equal spatial extent compared with DEMhigh,
        % otherwise it is hard to downscale
        % DEMhigh must have the same spatial extent with BasicInfo
        load(FileDEMLow,'DEM','Info');
        DEMLow=DEM;
        InfoLow=Info;
        clear DEM Info
        
        mm=arcgridread_tgq(FileDEMHigh);
        DEMHigh=mm.mask;
        clear mm
        % interpolate DEMLow to match reanalysis. Theoretically, DEMLow should
        % totally match reanalysis. But sometimes due to marginal differences,
        % interpolation is necessary.
        latLow=(InfoLow.yll+InfoLow.Ysize*InfoLow.nrows-InfoLow.Ysize/2):-InfoLow.Ysize:(InfoLow.yll+InfoLow.Ysize/2);
        lonLow=(InfoLow.xll+InfoLow.Xsize/2):InfoLow.Xsize:(InfoLow.xll+InfoLow.Xsize*InfoLow.ncols-InfoLow.Xsize/2);
        [XXLow,YYLow]=meshgrid(lonLow,latLow);
        DEMLow=interp2(XXLow,YYLow,DEMLow,XX0,YY0,'linear');
    end
      
    method=imethod{vv};
    for yy=year(1):year(end)
        Outfile=[Outpath{vv},'/',prefixout{vv},num2str(yy),'.nc4'];
        if ~exist(Outfile,'file')
            fprintf('ERA5 Data in process. Var %d; Year %d--%d\n',vv,yy,year(end));
            % read, hour 2 day, unit conversion, interpolation
            daysyy=datenum(yy,12,31)-datenum(yy,1,1)+1;
            data=zeros(Nrow,Ncol,daysyy);
            flag=1;
            for mm=1:12
                Infile=[Inpath{vv},'/',prefix{vv},num2str(yy),num2str(mm,'%.2d'),suffix{vv},'.nc'];
                if yy==1979&&mm==1&&ismember(varname{vv},{'tp'})
                    varmd=f_ERA5_VarRead(Infile,varname{vv},1);
                else
                    varmd=f_ERA5_VarRead(Infile,varname{vv},0); 
                end
                
                if strcmp(method,'lapserate')
                    varint0=ff_interpolate(varmd,XX0,YY0,XX1,YY1,'near');
                    % find the lapse rate for this month
                    TLRym=TLR(:,:,TLRdate==yy*100+mm);
                    Tadd=ff_Tdownscale_lp(XX1,YY1,REAinfo,DEMHigh,DEMLow,TLRym);
                    
                    varint=ff_Tdownscale_add(varint0,Tadd);
                    varint(isnan(varint))=varint0(isnan(varint)); % over pixels without dem
                else
                    varint=ff_interpolate(varmd,XX0,YY0,XX1,YY1,method);
                end
                daysmm=size(varint,3);
                data(:,:,flag:flag+daysmm-1)=varint;
                flag=flag+daysmm;
            end
            % save data
%             save(Outfile,'data','BasicInfo','REAinfo','-v7.3');
            f_save_nc(Outfile,data,BasicInfo,DEMHigh);
        else
            fprintf('ERA5 Data already exist. Var %d; Year %d--%d\n',vv,yy,year(end));
        end
    end
end

end

function vardd=f_ERA5_VarRead(Infile,varname,flag)
varhh=ncread(Infile,varname); % hourly data
varhh=permute(varhh,[2,1,3]); % to the normal lat/lon map
if flag==1
    add=nan*zeros(size(varhh,1),size(varhh,2),7);
    varhh=cat(3,add,varhh);
end

switch varname
    case 'tp'
        method='sum';
    case 'sf'
        method='sum';
    case 'mn2t'
        method='min';
    case 'mx2t'
        method='max';
    case 't2m'
        method='mean';
end
vardd=f_h2d(varhh,method);

% unit conversion
switch varname
    case {'tp','sf'}
        vardd=vardd*1000; % m to mm
    case {'mn2t','mx2t','t2m'}
        vardd=vardd-273.15; % K to C
end
end

function dout=f_h2d(din,method)
% hourly data to daily data by method--mean min max sum
% unit conversion
days=size(din,3)/24;
dout=nan*zeros(size(din,1),size(din,2),days);

for dd=1:days
    vd=din(:,:,dd*24-23:dd*24); % hourly to daily
    switch method
        case 'mean'
            vd=nanmean(vd,3);
        case 'min'
            vd=min(vd,[],3);
        case 'max'
            vd=max(vd,[],3);
        case 'sum'
            vd=nansum(vd,3);
    end
    dout(:,:,dd)=vd;
end
end