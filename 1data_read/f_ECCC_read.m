function f_ECCC_read(Inpath,Infile_list,Outpath,Outfile_gauge,BasicInfo)
% The code is aimed to extract ECCC data that satisfy some criteria
% output variables include:
% lle--[latitude, longitude, elevation (m)]
% ID--gauge ID

varname=ECCCinfo.VarOut;
source='ECCC';

% read basic gauge information
Ginfo=readtable(Infile_list);
Gauge.CID=Ginfo.ClimateID;
Gauge.ID=str2double(Ginfo.StationID);
Gauge.lle=[str2double(Ginfo.Latitude_DecimalDegrees_),...
    str2double(Ginfo.Longitude_DecimalDegrees_),...
    str2double(Ginfo.Elevation_m_)];

% screening criteria
if BasicInfo.seflag==2&& ~exist(Outfile_gauge,'file')
    Infile_mask=BasicInfo.maskfile;
    mask=arcgridread_tgq(Infile_mask); % note: mask is a structure
    BasicInfo.mask=mask;
end
Gauge=f_MaskScreen(Gauge,BasicInfo);

% read gaue
Indir=dir(fullfile(Inpath,'*.csv'));
GaugeValid.ID=cell(length(Indir),1);
GaugeValid.lle=nan*zeros(length(Indir),3);
GaugeValid.period=nan*zeros(length(Indir),2);
Gnum=length(Indir);
flagg=1;
for i=1:Gnum
    ID=Indir(i).name(1:11);
    fprintf('Processing ECCC gauge %s--%d---Total gauges: %d\n',ID,i,Gnum);
    Outfile=[Outpath,'/',Indir(i).name(1:end-4),'.mat'];
    if ~exist(Outfile,'file')
        Infilei=[Inpath,'/',Indir(i).name];
        CIDi=Indir(i).name(5:11);
        % date extent
        datai=readtable(Infilei);
        datei=datestr(datai.Date_Time,'yyyymmdd');
        datei=str2double(num2cell(datei,2));
        yeari=floor(datei/10000);
        indin=yeari>=BasicInfo.period_range(1)&yeari<=BasicInfo.period_range(2);
        yearuni=unique(yeari(indin));
        period_len=length(yearuni); % the number of years that are within period_range
        if period_len<BasicInfo.period_len(1)||period_len>BasicInfo.period_len(2)
            fprintf('%s has shorter/longer time period compared to the predefined length.\n',Indir(i).name);
            continue;
        end
        datei=datei(indin);
        datai=datai(indin,:);
        % lat lon elev
        [~,indi]=ismember(CIDi,Gauge.CID);
        if indi==0
            fprintf('%s is outside the region.\n',Indir(i).name);
           continue; 
        end
        
        lle=Gauge.lle(indi,:);
        
        if sum(isnan(lle))>0
            fprintf('%s has missing lat or lon or ele.\n',Indir(i).name);
            continue;
        end
        
        % extract variables and scaling
        data=nan*zeros(length(datei),length(BasicInfo.VarRead));
        qflag=char(ones(length(datei),length(BasicInfo.VarRead))*'~');
        data(:,1)=datei;
        for vv=1:length(BasicInfo.VarRead)
            sfvv=BasicInfo.scalefactor(vv);
            data(:,vv+1)=datai{:,BasicInfo.VarRead{vv}}*sfvv;
            
            flagname=regexp(BasicInfo.VarRead{vv},'_','split'); flagname=[flagname{1},'Flag'];
            temp=datai{:,flagname};
            if iscell(temp)
                for ff=1:length(temp)
                   if isempty(temp{ff})  % many flag values are empty
                      temp{ff}='~'; 
                   end
                end
                qflag(:,vv)=cell2mat(temp);
            else
               qflag(:,vv)=char(ones(length(temp),1)*'-');  % all flag values is NaN 
            end
            
        end
        % sometimes, years do not have any valid value. we should delete
        % these years
        yearout=ones(size(yeari));
        for yy=1:length(yearuni)
            indyy=yeari==yearuni(yy);
            datayy=data(indyy,2:end);
            if sum(~isnan(datayy(:)))==0
                yearout(indyy)=0;
            end
        end
        data(yearout==0,:)=[];
        qflag(yearout==0,:)=[];
        yeari(yearout==0)=[];
        period_len=length(unique(yeari));
        if period_len<BasicInfo.period_len(1)||period_len>BasicInfo.period_len(2)
            fprintf('%s has shorter/longer time period compared to the predefined length.\n',Indir(i).name);
            continue;
        end
        
        save(Outfile,'data','qflag','lle','ID','varname','source');
        GaugeValid.ID{flagg}=ID;
        GaugeValid.lle(flagg,:)=lle;
        GaugeValid.period(flagg,:)=minmax(yearuni');
        flagg=flagg+1;
    else
        load(Outfile,'data','lle','ID','varname','source');
        GaugeValid.ID{flagg}=ID;
        GaugeValid.lle(flagg,:)=lle;
        datei=data(:,1); yeari=floor(datei/10000);
        GaugeValid.period(flagg,:)=minmax(yeari');
        flagg=flagg+1;
    end
    
end
if flagg<length(Indir)
    GaugeValid.ID(flagg:end)=[];
    GaugeValid.lle(flagg:end,:)=[];
    GaugeValid.period(flagg,:)=[];
end
GaugeValid.SR=BasicInfo;
save(Outfile_gauge,'GaugeValid')
end

function Gauge=f_MaskScreen(Gauge,BasicInfo)
latlon=Gauge.lle;
if BasicInfo.seflag==1
    ind2=(latlon(:,1)>=BasicInfo.lat_range(1)&latlon(:,1)<=BasicInfo.lat_range(2)&...
        latlon(:,2)>=BasicInfo.lon_range(1)&latlon(:,2)<=BasicInfo.lon_range(2));
elseif BasicInfo.seflag==2
    mask=BasicInfo.mask;
    row=floor((mask.yll2-latlon(:,1))/mask.cellsize)+1;
    col=floor((latlon(:,2)-mask.xll)/mask.cellsize)+1;
    ind21=(row<1|row>mask.nrows|col<1|col>mask.ncols);
    Gauge.lle(ind21,:)=[];
    Gauge.ID(ind21,:)=[];
    Gauge.CID(ind21,:)=[];
    row(ind21)=[];
    col(ind21)=[];
    indtemp=sub2ind([mask.nrows,mask.ncols],row,col);
    ind2=isnan(mask.mask(indtemp));
else
    error('Wrong SR.seflag');
end
Gauge.lle(ind2,:)=[];
Gauge.ID(ind2,:)=[];
Gauge.CID(ind2,:)=[];
end