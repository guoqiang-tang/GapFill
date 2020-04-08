function f_GHCN_read(Inpath,Infile_inventory,Infile_station,BasicInfo,Outpath,Outfile_station,Overwrite)
% The code is aimed to extract GHCN-D data that satisfy some criteria
% The path of ghcnd_all which is ghcnd_all.tar.gz located in the home path
% of GHCN-D ftp website
% lle--[latitude, longitude, elevation (m)]
% ID--gauge ID

varname=BasicInfo.VarOut;
Var=BasicInfo.VarRead;
source='GHCN-D';

% screening criteria
if BasicInfo.seflag==2&&Overwrite==1
    Infile_mask=BasicInfo.maskfile;
    mask=arcgridread_tgq(Infile_mask); % note: mask is a structure    
    BasicInfo.mask=mask;
end

% main function for reading
% 1. screen stations
GaugeValid=f_ScreenGauge(Infile_inventory,Infile_station,Outfile_station,BasicInfo,Overwrite);

% 2. read various variables from original files
% Example of variables
% Var={'PRCP',... % Precipitation (tenths of mm)
%     'SNOW',... % Snowfall (mm)
%     'SNWD',... % Snow depth (mm)
%     'TMAX',... % Maximum temperature (tenths of degrees C)
%     'TMIN',... % Minimum temperature (tenths of degrees C)
%     ...  % the above are five core elements
%     'TAVG',... % Average temperature (tenths of degrees C)
%     'AWND',... % Average daily wind speed (tenths of meters per second)
%     'WESF',... % Water equivalent of snowfall (tenths of mm)
%     'WT**',... % Weather Type where ** has one of the following values
%     };

nstn=length(GaugeValid.ID);
% parfor i=1:nstn % parallel is allowed
for i=1:nstn
    Infile=[Inpath,'/',GaugeValid.ID{i},'.dly'];
    Outfile=[Outpath,'/',GaugeValid.ID{i},'.mat'];
    lle=GaugeValid.lle(i,:);
    ID=GaugeValid.ID{i};
    if ~exist(Outfile,'file')
        if ~exist(Infile,'file')
            fprintf('Error: The station does not exist--ID: %s\n',GaugeValid.ID{i});
        else
            [data,mqsflag]=f_readSingleGauge(Infile,Var);
            % delete data outside BasicInfo.period_range
            dyear=floor(data(:,1)/10000);
            indout=dyear<BasicInfo.period_range(1) | dyear>BasicInfo.period_range(2);
            data(indout,:)=[];
            for ff=1:length(mqsflag)
                mqsflag{ff}(indout,:)=[];
            end
            
            % change missing value to NaN
            for vv=1:size(data,2)-1
                temp=data(:,vv+1); % first column is date
                temp(temp==BasicInfo.missingvalue(vv))=nan;
                data(:,vv+1)=temp*BasicInfo.scalefactor(vv);
            end       
            
            % save file
            f_saveGHCND(Outfile,data,mqsflag,lle,ID,varname,source);
        end
    end
    fprintf('Processing GHCN-D gauge %s--%d---Total gauges: %d\n',ID,i,nstn);
end

end

function days=f_days(year,month)
switch month
    case {1,3,5,7,8,10,12}
        days=31;
    case {4,6,9,11}
        days=30;
    case 2
        if (mod(year,4)==0&&mod(year,100)~=0)||mod(year,400)==0
            days=29;
        else
            days=28;
        end
end
end

function [Gdata,Gflag]=f_readSingleGauge(file,Var)
% obtain the start and end years because the year range provided in
% inventory is not always correct
fid=fopen(file,'r');
lio=fgetl(fid);
years=str2double(lio(12:15));
fseek(fid,-270,'eof');
lio=fgetl(fid);
yeare=str2double(lio(12:15));
fseek(fid,0,'bof');

% initialization
daysf=(yeare-years+1)*12*31; % fake day numbers, every month has 31 values in files
data=nan*zeros(daysf,length(Var));
date=nan*zeros(daysf,1);
temp=char(ones(daysf,1) * 'XXX'); % MFLAG,QFLAG,SFLAG
Gflag=cell(length(Var),1);
Gflag(:)={temp}; clear temp

% read data
dateold='000000';
samid=-30;
while ~feof(fid)
    li=fgetl(fid);
    if length(li)==269
        % decide whether the code comes to a new month
        datenew=li(12:17);
        if ~strcmp(datenew,dateold)
            dateold=datenew;
            samid=samid+31;  
            date(samid:samid+30)=str2double(datenew);
        end
        % which var is under processing
        vari=li(18:21);
        [ism,varid]=ismember(vari,Var);
        if ism
            % extract values
            temp1=nan*zeros(31,1);
            temp2=char(ones(31,1) * 'XXX');
            li=li(22:end);
            for dd=1:31
                temp1(dd)=str2double(li((dd-1)*8+1:(dd-1)*8+5));
                temp2(dd,:)=li((dd-1)*8+6 : (dd-1)*8+8);
%                 qflag0=li((dd-1)*8+7);
%                 if strcmp(qflag0,' ')
%                     temp2(dd)=1; % good quality
%                 else
%                     temp2(dd)=0; % unsure or bad quality
%                 end
            end
            data(samid:samid+30,varid)=temp1;
            Gflag{varid}(samid:samid+30,:)=temp2;
        end
        clear li
    else
        clear li
    end
end
fclose(fid);
if samid+30<daysf
    data(samid+31:end,:)=[];
    date(samid+31:end,:)=[];
    for i=1:length(Gflag)
        Gflag{i}(samid+31:end,:)=[];
    end
end
% delete fake dates
months=length(date)/31;
indd=zeros(length(date),1);
for i=1:months
    year=floor(date(i*31-1)/100);
    month=date(i*31-1)-year*100;
    daynumi=f_days(year,month);
    indd(i*31-30:i*31+daynumi-31)=1;
    
    % convert date from yyyymm to yyyymmdd
    tempdate=date(i*31-30:i*31+daynumi-31);
    dayser=(1:daynumi)';
    tempdate=tempdate*100+dayser;
    date(i*31-30:i*31+daynumi-31)=tempdate;
end

indd2=indd==0;
data(indd2,:)=[];
date(indd2,:)=[];
for i=1:length(Gflag)
    Gflag{i}(indd2,:)=[];
end
Gdata=[date,data];
end


function GaugeValid=f_ScreenGauge(Infile_inventory,Infile_station,Outfile_station,BasicInfo,Overwrite)
fprintf('Extracting valid gauges...\n');
if exist(Outfile_station,'file')&&Overwrite~=1
    load(Outfile_station,'GaugeValid');
else
    DataAll=importdata(Infile_inventory);  %Infile_inventory
    Gperiod=DataAll.data;
    Ginfo=DataAll.textdata; % ID
    clear DataAll
    
    % Note: the order of processing is important
    % for each station, find the variables belonging to BasicInfo.VarRead
    indno=~ismember(Ginfo(:,4),BasicInfo.VarRead);
    Ginfo(indno,:)=[];
    Gperiod(indno,:)=[];
    
    % period range. delete all stations that cannot meet the requirement of
    % least gauge number
    basicyear=BasicInfo.period_range(1):BasicInfo.period_range(2);
    period_len=zeros(size(Gperiod,1),1);
    for i=1:size(Gperiod,1)
        tempi=Gperiod(i,1):Gperiod(i,2);
        period_len(i)=sum(ismember(tempi,basicyear));
        if mod(i,1000)==0
           fprintf('%d\n',i); 
        end
    end
    ind1=period_len<BasicInfo.period_len(1)|period_len>BasicInfo.period_len(2);
    Gperiod(ind1,:)=[];
    Ginfo(ind1,:)=[];

    % delete repeated stations variables    
    [~,Gind]=unique(Ginfo(:,1));
    Ginfo=Ginfo(Gind,:);  % overwrite
    Gperiod=Gperiod(Gind,:);  
    % lat/lon range or mask range
    snum=size(Ginfo,1); % sample number
    latlon=zeros(snum,2);
    for i=1:snum
        lati=str2double(Ginfo{i,2});
        loni=str2double(Ginfo{i,3});
        latlon(i,1)=lati;
        latlon(i,2)=loni;
    end
    if BasicInfo.seflag==1    
        ind2=(latlon(:,1)>=BasicInfo.lat_range(1)&latlon(:,1)<=BasicInfo.lat_range(2)&...
            latlon(:,2)>=BasicInfo.lon_range(1)&latlon(:,2)<=BasicInfo.lon_range(2));
    elseif BasicInfo.seflag==2
        mask=BasicInfo.mask;
        row=floor((mask.yll2-latlon(:,1))/mask.cellsize)+1;
        col=floor((latlon(:,2)-mask.xll)/mask.cellsize)+1;
        ind21=(row<1|row>mask.nrows|col<1|col>mask.ncols);
        Gperiod(ind21,:)=[];
        Ginfo(ind21,:)=[];
        latlon(ind21,:)=[];
        row(ind21)=[];
        col(ind21)=[];       
        indtemp=sub2ind([mask.nrows,mask.ncols],row,col);
        ind2=isnan(mask.mask(indtemp));
    else
        error('Wrong SR.seflag');
    end
    Gperiod(ind2,:)=[];
    Ginfo(ind2,:)=[];
    latlon(ind2,:)=[];
    
    % read the elevation of those stations
    Ginfo2=cell(200000,2); % for Infile_station 
    fid=fopen(Infile_station,'r');
    flag=1;
    while ~feof(fid)
       li=fgetl(fid);
       Ginfo2{flag,1}=li(1:11);
       Ginfo2{flag,2}=li(31:37);
       flag=flag+1;
    end
    fclose(fid);
    if flag<=200000
        Ginfo2(flag:end,:)=[];
    end
    [ind1,ind2]=ismember(Ginfo2(:,1),Ginfo(:,1));
    ind2(ind2==0)=[];
    Ele=nan*zeros(size(latlon,1),1);
    Ele(ind2)=str2double(Ginfo2(ind1,2));
    
    % output gauge infomation
    GaugeValid.ID=Ginfo(:,1);
    GaugeValid.lle=[latlon,Ele];
    GaugeValid.period=Gperiod;
    GaugeValid.SR=BasicInfo;
    save(Outfile_station,'GaugeValid')
end
end

function f_saveGHCND(Outfile,data,mqsflag,lle,ID,varname,source)
   save(Outfile,'data','mqsflag','lle','ID','varname','source')
end