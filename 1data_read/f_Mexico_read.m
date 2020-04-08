function f_Mexico_read(Inpath,Outpath,Outfile_gauge,BasicInfo)
varname=BasicInfo.VarOut;
vars=BasicInfo.VarRead;
Indir=dir(fullfile(Inpath,'*.txt'));
source='Mexico';
% read station IDs and LLE
IDLLE=cell(length(vars),1);
for vv=1:length(vars)
    IDLLEvv=[];
    for i=1:length(Indir)
        if strcmp(Indir(i).name(end-11:end-4),[vars{vv},'_stn'])
            file=[Inpath,'/',Indir(i).name];
            IDllei=f_basic_read(file);
            IDLLEvv=cat(1,IDLLEvv,IDllei);
        end
    end
    IDLLE{vv}=IDLLEvv;
end

IDLLEall=[];
for vv=1:length(vars)
    IDLLEall=cat(1,IDLLEall,IDLLE{vv});
end
IDLLEall=unique(IDLLEall,'rows');
ID=IDLLEall(:,1);
LLE=IDLLEall(:,2:4);

% screening criteria
if BasicInfo.seflag==2&& ~exist(Outfile_gauge,'file')
    Infile_mask=BasicInfo.maskfile;
    mask=arcgridread_tgq(Infile_mask); % note: mask is a structure
    BasicInfo.mask=mask;
end
[ID,LLE]=f_MaskScreen(ID,LLE,BasicInfo);

% read variables

for vv=1:length(vars)
    for i=1:length(Indir)
        fprintf('%d--%d--%d\n',vv,i,length(Indir));
        if strcmp(Indir(i).name(end-11:end-4),[vars{vv},'_dat'])
            file=[Inpath,'/',Indir(i).name];
            [IDu,dataout]=f_var_read(file,BasicInfo,ID);
            % saving data
            for g=1:length(dataout)
                IDgg=IDu(g);
                lle=LLE(ID==IDgg,:);
                Outfile=[Outpath,'/',num2str(IDgg),'.mat'];
                command=[vars{vv},'=dataout{g};']; eval(command);
                if ~exist(Outfile,'file')
                    save(Outfile,vars{vv},'source','IDgg','lle','varname');
                else
                    save(Outfile,vars{vv},'source','IDgg','lle','varname','-append');
                end
            end
        end
    end
end

% unify the variable
indir=dir(fullfile(Outpath,'*.mat'));
for i=1:length(indir)
    fprintf('%d--%d\n',i,length(indir));
    filei=[Outpath,'/',indir(i).name];
    load(filei,'prcp','tmin','tmax','source','IDgg','lle','varname');
    if ~exist('IDgg','var')
        continue;
    end
    ID=IDgg;
    dataall=cell(3,1);
    flag=0;
    if exist('prcp','var'); dataall{1}=prcp; else; dataall{1}=[nan,nan]; flag=flag+1; end
    if exist('tmin','var'); dataall{2}=tmin; else; dataall{2}=[nan,nan]; flag=flag+1;  end
    if exist('tmax','var'); dataall{3}=tmax; else; dataall{3}=[nan,nan]; flag=flag+1;  end
    clear prcp tmin tmax
    if flag==3; continue; end  % the three variables don't exist
    
    date=[];
    for vv=1:3
        date=union(date, dataall{vv}(:,1));
    end
    date(isnan(date))=[];
    data=nan*zeros(length(date),4);
    data(:,1)=date;
    
    for vv=1:3
        datevv=dataall{vv}(:,1);
        [ind1,ind2]=ismember(datevv,date);
        ind2(ind2==0)=[];
        if ~isempty(ind2)
            data(ind2,vv+1)=dataall{vv}(ind1,2);
        end
    end
    
    delete(filei);
    save(filei,'data','source','ID','lle','varname');
    
    clear data source IDgg lle varname
end
end

function [ID,LLE]=f_MaskScreen(ID,LLE,BasicInfo)
if BasicInfo.seflag==1
    ind2=(LLE(:,1)>=BasicInfo.lat_range(1)&LLE(:,1)<=BasicInfo.lat_range(2)&...
        LLE(:,2)>=BasicInfo.lon_range(1)&LLE(:,2)<=BasicInfo.lon_range(2));
elseif BasicInfo.seflag==2
    mask=BasicInfo.mask;
    row=floor((mask.yll2-LLE(:,1))/mask.cellsize)+1;
    col=floor((LLE(:,2)-mask.xll)/mask.cellsize)+1;
    ind21=(row<1|row>mask.nrows|col<1|col>mask.ncols);
    ID(ind21,:)=[];
    LLE(ind21,:)=[];
    row(ind21)=[];
    col(ind21)=[];
    indtemp=sub2ind([mask.nrows,mask.ncols],row,col);
    ind2=isnan(mask.mask(indtemp));
else
    error('Wrong SR.seflag');
end
LLE(ind2,:)=[];
ID(ind2,:)=[];
end

function IDlle=f_basic_read(file)
ID=nan*zeros(500,1);
lle=nan*zeros(500,3);
flag=1;
fid=fopen(file,'r');
fgetl(fid); fgetl(fid);
while ~feof(fid)
    linei=fgetl(fid);
    l2=regexp(linei,' ','split');
    l2(ismember(l2,{''}))=[];
    ID(flag)=str2double(l2{1});
    lat=l2{end-2}; 
    lat=regexp(lat,':','split'); 
    lat=str2double(lat{1})+str2double(lat{2})/60; % lat is positive
    lon=l2{end-1}; 
    lon=regexp(lon,':','split');
    lon=str2double(lon{1})-str2double(lon{2})/60; % lon is negative
    ele=l2{end}; ele=str2double(ele); ele=ele/3.2808; % feet to meter
    lle(flag,:)=[lat,lon,ele];
    flag=flag+1;
end
fclose(fid);
if flag<=500
    ID(flag:end)=[];
    lle(flag:end,:)=[];
end

IDlle=[ID,lle];
end


function [IDu,dataout]=f_var_read(file,BasicInfo,IDall)
dd=readtable(file);
dd(1,:)=[];
ID=dd.COOPID;
ID=str2double(ID);
YEARMO=dd.YEARMO;
YEARMO=str2double(YEARMO);
varname=dd.ELEM{1};
data=nan*zeros(length(YEARMO),31);
for i=1:31
    data(:,i)=str2double(dd{:,['DAY',num2str(i,'%.2d')]});
end
data(data==-99999)=nan;

switch varname
    case 'PRCP'
        data=data/100*25.4;
    case {'TMIN','TMAX'}
        data=(data-32)*5/9;
end

% delete some data
indi=(~ismember(ID,IDall)|...
    YEARMO<BasicInfo.period_range(1)*100|...
    YEARMO>(BasicInfo.period_range(2)+1)*100);
ID(indi)=[];
YEARMO(indi)=[];
data(indi,:)=[];

% flatten variables and attribute it to different stations
IDu=unique(ID);
gnum=length(IDu);
dataout=cell(gnum,1);

flagout=nan*zeros(gnum,1);
for g=1:gnum
    indg=ID==IDu(g);
    YEARMOg=YEARMO(indg);
    datag=data(indg,:);
    % generate date
    temp1=min(YEARMOg); temp2=max(YEARMOg);
    ylen=floor(temp2/100)-floor(temp1/100)+1;
    if ylen<BasicInfo.period_len(1) || ylen>BasicInfo.period_len(2)  % time length control
        flagout(g)=1;
       continue; 
    end
    
    date=datenum(floor(temp1/100),mod(temp1,100),1):datenum(floor(temp2/100),mod(temp2,100),31);
    date=datestr(date,'yyyymmdd');
    date=mat2cell(date,ones(size(date,1),1),8);
    date=str2double(date);
    date2=floor(date/100);
    
    % data 
    dataoutg=nan*zeros(length(date),2);
    dataoutg(:,1)=date;
    for i=1:length(YEARMOg)
        indi=date2==YEARMOg(i);
        ndays=sum(indi);
        dataoutg(indi,2)=datag(i,1:ndays);
    end
    dataout{g}=dataoutg;
end

dataout(flagout==1)=[];
IDu(flagout==1)=[];
end

