function f_GSOD_read(Inpath,Outpath,Outfile_gaugeAll,Outfile_gauge,BasicInfo)
% read GSOD files by year and save data for each rain gauge
% the code can be stopped anytime and continue run again.
% ID--gauge ID

% screening criteria
period_range=BasicInfo.period_range; % [start year, end year]
period_len=BasicInfo.period_len;
yearnum=period_range(2)-period_range(1)+1;

if BasicInfo.seflag==2
    Infile_mask=BasicInfo.maskfile;
    mask=arcgridread_tgq(Infile_mask); % note: mask is a structure    
    BasicInfo.mask=mask;
end

%1. build a repository of gauges using data in the most recent year
%this repository contains most gauges among all years and should be
%relatively complete.
%repo contains gauges in and not in the region
if ~exist(Outfile_gaugeAll,'file')
    Inpathi=[Inpath,'/',num2str(period_range(2)-1)];
    [gauge_ID,status]=f_GaugeID(Inpathi);
    [gauge_latlonele,status]=f_GaugeLLE(Inpathi,gauge_ID); %lat lon elevation
    IndIn=f_InOrNot(gauge_latlonele,BasicInfo); % within the region or not
    gauge_flag=zeros(length(gauge_ID),1);
    gauge_flag(IndIn)=1;  % 1--gauges are valid, i.e., satisfying the criteria
    readstatus_flag=zeros(length(gauge_ID),1); %1--have read; 0--not read yet
    save(Outfile_gaugeAll,'gauge_ID','gauge_latlonele','gauge_flag','readstatus_flag');
else
    load(Outfile_gaugeAll,'gauge_ID','gauge_latlonele','gauge_flag','readstatus_flag');
end

%2. loop by year
for i=1:yearnum
    yeari=period_range(1)+i-1;
    Inpathi=[Inpath,'/',num2str(yeari)];
    [IDi,status]=f_GaugeID(Inpathi);
    %2.1 divide gauges in yeari into two groups and decide whether they are
    %valid
    [indexIDi,indexrepo]=ismember(IDi,gauge_ID);
    indexrepo(indexrepo==0)=[];
    
    IDi1=IDi(indexIDi); % in
    gauge_flagi=gauge_flag(indexrepo);
    gauge_llei=gauge_latlonele(indexrepo,:);
    readstatusi=readstatus_flag(indexrepo);
    %gauge_filei1=gauge_file(indexrepo);
    
    IDi2=IDi(~indexIDi); % not in
    %2.1.1 first group: gauges belonging to repo
    if ~isempty(IDi1)
        %divide ID1 into two subgroups
        IndexIn1=(gauge_flagi==1&readstatusi==0);
        %first subgroup: within the region
        if sum(IndexIn1)>0
            GaugeReadflag=f_readsave(Inpath,period_range,IDi1(IndexIn1),yeari,period_len,gauge_llei(IndexIn1,:),Outpath,BasicInfo);
            gauge_flagi(IndexIn1)=GaugeReadflag;
            gauge_flag(indexrepo)=gauge_flagi;  % some gauges are not read due to some reasons
        end
        %second subgroup: outside the region, we do nothing in this case
    end
    readstatus_flag(indexrepo)=1;
    
    %2.1.2 second group: gauges not belonging to repo
    if ~isempty(IDi2)
        % add the gauges into the repo
        [add_LLE,status]=f_GaugeLLE(Inpathi,IDi2);
        add_ID=IDi2;
        add_gaugeflag=zeros(length(IDi2),1);
        add_readstatus=ones(length(IDi2),1);
        %divide ID2 into two subgroups, within and outside the region
        %         IndexIn2=f_InOrNot(add_LLE,lat_range,lon_range);
        IndexIn2=f_InOrNot(add_LLE,BasicInfo);
        if sum(IndexIn2)>0 % there some gauges within the region
            % update status and output the data
            GaugeReadflag=f_readsave(Inpath,period_range,add_ID(IndexIn2),yeari,period_len,add_LLE(IndexIn2,:),Outpath,BasicInfo);
            add_gaugeflag(IndexIn2)=GaugeReadflag;         
        end
        % update repo
        gauge_ID=cat(1,gauge_ID,add_ID);
        gauge_latlonele=cat(1,gauge_latlonele,add_LLE);
        gauge_flag=cat(1,gauge_flag,add_gaugeflag);
        readstatus_flag=cat(1,readstatus_flag,add_readstatus);
    end
    save(Outfile_gaugeAll,'gauge_ID','gauge_latlonele','gauge_flag','readstatus_flag');  % update each year
    fprintf('Year %d--Total years %d\n',i,yearnum);
end
% 3. save repo file
GaugeValid.ID=gauge_ID(gauge_flag==1);
GaugeValid.lle=gauge_latlonele(gauge_flag==1,:);
save(Outfile_gauge,'GaugeValid');
end

function readflag=f_readsave(Inpath,period_range,IDall,year,period_len,LLEall,Outpath,BasicInfo)
% period_range is the whole period needing to be read
period_range(1)=year;
% var to read
VarRead=BasicInfo.VarRead;
varMissing=BasicInfo.missingvalue;
varname=BasicInfo.VarOut;
source='GSOD';

IDstr=num2str(IDall,'%.11d');
readflag=zeros(length(IDall),1);
for i=1:length(IDall)
    ID=IDstr(i,:);
    lle=LLEall(i,:);
    if sum(isnan(lle))>0
       continue; 
    end
    
    Outfilei=[Outpath,'/',ID,'.mat'];
    fprintf('Reading %s\n',ID);
    if exist(Outfilei,'file')
        readflag(i)=1;
    else
        % first to decide if there is enough years of data
        period_leni=0;
        for yy=period_range(1):period_range(2)
            Infilei=[Inpath,'/',num2str(yy),'/',ID,'.csv'];
            if exist(Infilei,'file')
                period_leni=period_leni+1;
            end
        end
        if period_leni>=period_len(1)&&period_leni<=period_len(2)
            % then read data
            data=[];
            attribute=[];
            for yy=period_range(1):period_range(2)
                Infilei=[Inpath,'/',num2str(yy),'/',ID,'.csv'];
                if exist(Infilei,'file')
                    % year infomation
                    datey=datenum(yy,1,1):datenum(yy,12,31);
                    datey=datey';
                    days=length(datey);
                    dateys=datestr(datey,'yyyymmdd');
                    dateyy=zeros(days,1);
                    for dd=1:days
                        dateyy(dd)=str2double(dateys(dd,:));
                    end
                    
                    % read the csv data
                    Data=readtable(Infilei);
                    datayy=zeros(size(Data,1),length(VarRead));
                    attyy=char(ones(size(Data,1),length(VarRead))*'~');
                    for j=1:length(VarRead)
                        datayy(:,j)=str2double(Data{:,VarRead{j}});
                        attyy(:,j)=cell2mat(Data{:,[VarRead{j},'_ATTRIBUTES']});
                    end
                    datei=zeros(size(Data,1),1);
                    datei0=table2cell(Data(:,2));
                    for j=1:size(Data,1)
                        datei(j)=datenum(datei0{j});
                    end  

                    % convert datei to cover every day in the year
                    if length(datei)<days
                        dcomplete=nan*zeros(days,length(VarRead));
                        attcomplete=char(ones(days,length(VarRead))*'~');
                        
                        [ind1,ind2]=ismember(datei,datey);
                        ind2(ind2==0)=[];
                        dcomplete(ind2,:)=datayy(ind1,:);
                        attcomplete(ind2,:)=attyy(ind1,:);
                        datayy=dcomplete;
                        attyy=attcomplete;
                        clear attcomplete dcomplete
                    end
                    
                    % attach date
                    datayy=cat(2,dateyy,datayy);
                    data=cat(1,data,datayy);
                    attribute=cat(1,attribute,attyy);
                end
            end
            
            % scale factor and missing
            for vv=1:length(VarRead)
                tempvv=data(:,vv+1);
                tempvv(tempvv==varMissing(vv))=nan;
               sfvv=BasicInfo.scalefactor(vv);
               if sfvv==1234 % temperature
                   data(:,vv+1)=(tempvv-32)*5/9;
               else
                   data(:,vv+1)=tempvv*sfvv;
               end
            end       
            save(Outfilei,'data','attribute','lle','ID','varname','source');
            readflag(i)=1;
        end
    end
end
end

function [latlonele,status]=f_GaugeLLE(Inpath,varargin)
% lat lon elevation
if nargin==1
    Indir=dir(fullfile(Inpath,'*.csv'));
    len=length(Indir);
elseif nargin==2
    ID=varargin{1}; % number vector
    len=length(ID);
end
status=cell(len,1);
latlonele=nan*zeros(len,3);
flag=1;
for i=1:len
    if nargin==1
        Infilei=fullfile(Inpath,Indir(i).name);
    elseif nargin==2
        Infilei=[Inpath,'/',num2str(ID(i),'%.11d'),'.csv'];
    end
    fid=fopen(Infilei,'r');
    tempnouse=fgetl(fid); % header
    temp=fgetl(fid); % first row of data
    fclose(fid);
    if ~isempty(temp)
        temp=erase(temp,'"');
        temp=regexp(temp,',','split');
        latlonele(i,:)=str2double(temp(3:5));
    else
        status{flag}=['Error2: ',Indir(i).name,'---lat/lon are absent'];
        fprintf(status{flag});
        fprintf('\n');
        flag=flag+1;
    end
end
status(flag:end)=[];
end

function [ID,status]=f_GaugeID(Inpath)
Indir=dir(fullfile(Inpath,'*.csv'));
dirlen=length(Indir);
ID=zeros(dirlen,1);
status=cell(dirlen,1);
flag=1;
for i=1:dirlen
    idi=str2double(Indir(i).name(1:end-4));
    if ~isnan(idi)
        ID(i)=idi;
    else
        status{flag}=['Error1: ',Indir(i).name,'--Name contains characters'];
        fprintf(status{flag});
        fprintf('\n');
        flag=flag+1;
    end
end
ID=int64(ID);
ID(ID==0)=[];
status(flag:end)=[];
end

function IndexIn=f_InOrNot(latlon,BasicInfo)
if BasicInfo.seflag==1
    lat_range=BasicInfo.lat_range;
    lon_range=BasicInfo.lon_range;
    IndexIn=latlon(:,1)>=lat_range(1)&latlon(:,1)<=lat_range(2)&...
        latlon(:,2)>=lon_range(1)&latlon(:,2)<lon_range(2);
elseif BasicInfo.seflag==2
    mask=BasicInfo.mask;
    IndexIn0=zeros(size(latlon,1),1);
    
    row=floor((mask.yll2-latlon(:,1))/mask.cellsize)+1;
    col=floor((latlon(:,2)-mask.xll)/mask.cellsize)+1;
    %step1
    ind21=(row<1|row>mask.nrows|col<1|col>mask.ncols);
    IndexIn0(ind21)=nan;
    %step2
    for i=1:size(IndexIn0,1)
        if ~isnan(IndexIn0(i))&&~isnan(row(i))&&~isnan(col(i))
            indtemp=sub2ind([mask.nrows,mask.ncols],row(i),col(i));
            IndexIn0(i)=mask.mask(indtemp);
        end
        %     fprintf('%d\n',i);
    end
    IndexIn=~isnan(IndexIn0);
end
end

% function S=f_snowfallestimation(P,snowflag0)
% snowflag=num2str(snowflag0,'%.6d');
% snowflag=snowflag(:,3);
% snowflag(isnan(snowflag0))='9';
% snowflag=mat2cell(snowflag,ones(length(snowflag),1),1);
% snowflag=str2double(snowflag);
% snowflag=snowflag==1; % snowflag==1 means snowfall, all precipitation transfers to snowfall
% 
% prcpflag=num2str(snowflag0,'%.6d');
% prcpflag=prcpflag(:,2);
% prcpflag(isnan(snowflag0))='9';
% prcpflag=num2cell(prcpflag,2);
% prcpflag=str2double(prcpflag);
% prcpflag=prcpflag==1; % prcp==1 means precipitation/drizzle
% 
% prcpzero=P==0;
% 
% S=nan*P;
% S(snowflag)=P(snowflag);
% S(prcpzero)=0; % zero precipitation means zero snowfall
% S(prcpflag)=0; % rain/drizzle means snowfall does not occur
% end