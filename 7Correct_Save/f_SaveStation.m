function f_SaveStation(PathMerge,outfile,obs,est,tlr,varvv,Overwrite)
% save all necessary information in one file for one station
% ID: identification of the station
% IDmerge: stations used if the current station merges data from several stations
% LLE: latitude, longitude, and elevation
% date: yyyymmdd for each day from 1979 to 2018
% tlr: monthly temperature lapse rate derived from MERRA-2 data
% prcp_obs: original observed precipitation
% tmin_obs: original observed minimum temperature
% tmax_obs: original observed maximum temperature
% prcp_qflag: quality flag of precipitation (first column: raw flag; second column: extra flag)
% tmin_qflag: quality flag of tmin (first column: raw flag; second column: extra flag)
% tmax_qflag: quality flag of tmax (first column: raw flag; second column: extra flag)
% prcp_est: filled/reconstructed precipitation using multiple strategies
% tmin_est: filled/reconstructed tmin using multiple strategies
% tmax_est: filled/reconstructed tmax using multiple strategies
% prcp_scd: merged serially complete dataset (scd) of precipitation
% tmin_scd: merged serially complete dataset (scd) of tmin
% tmax_scd: merged serially complete dataset (scd) of tmax
% prcp_source: source of scd from prcp_est
% tmin_source: source of scd from tmin_est
% tmax_source: source of scd from tmax_est
% tmin_source: merged serially complete dataset (scd) of tmin
% tmax_source: merged serially complete dataset (scd) of tmax
% prcp_metric: accuracy metrics (first column: filled; second column: reconstructed)
% tmin_metric: accuracy metrics (first column: filled; second column: reconstructed)
% tmax_metric: accuracy metrics (first column: filled; second column: reconstructed)

%0. get all variables if outfile exists
varold={};
if exist(outfile,'file')
    info=ncinfo(outfile);
    for i=1:length(info.Variables)
        varold=cat(1,varold,info.Variables(i).Name);
    end
end


%define dimension names
dim_day={'nday',14610};
dim_est={'nest',size(est.dfill,2)}; % number of strategies used for estimation
dim_met1={'nmet1',4}; % KGE, three components
dim_met2={'nmet2',2};
dim_met3={'nmet3',367};
dim_cont={'cont',1};

%1. write basic information
if ~exist(outfile,'file')
    %%%
    nccreate(outfile,'ID','Datatype','char','Dimensions',{'nchar',13},'Format','netcdf4','DeflateLevel',9);
    ncwrite(outfile,'ID',est.IDgg);
    ncwriteatt(outfile,'ID','description','station ID');
    ncwriteatt(outfile,'ID','Char1-2','station source. GH: ghcn-d, GS: gsod, EC: eccc, ME: mexico, MR: merge');
    ncwriteatt(outfile,'ID','Char3-13','ID from original sources. For the Mexico database, it is Char6-13');
    ncwriteatt(outfile,'ID','MRdescription','MR merges stations with same lat/lon. Char3-13 of MR is from the source in order of GH GS EC ME');
    
    %%%
    if strcmp(est.IDgg(1:2),'MR')
        filemerge=[PathMerge,'/',est.IDgg(3:end),'.mat'];
        if exist(filemerge,'file')
            load(filemerge,'IDoverlap');
            if ~exist('IDoverlap','var')
                IDall=[];
                for i=1:length(IDoverlap)
                    IDall=[IDall,'/',IDoverlap{i}];
                end
                IDall(1)=[];
                nccreate(outfile,'IDmerge','Datatype','char',...
                    'Dimensions',{'nmr',length(IDall)},...
                    'Format','netcdf4','DeflateLevel',9);
                ncwrite(outfile,'IDmerge',IDall);
                ncwriteatt(outfile,'IDmerge','description','original station IDs that are used in the merged station');
            end
        end
    end
    
    %%%
    nccreate(outfile,'LLE','Datatype','single',...
        'Dimensions',{'dimLLE',3},...
        'Format','netcdf4','DeflateLevel',9,'FillValue',-999);
    ncwrite(outfile,'LLE',est.LLEgg);
    ncwriteatt(outfile,'LLE','description','latitude, longitude, elevation (LLE)');
    
    %%%
    nccreate(outfile,'date','Datatype','int32','Dimensions',dim_day,'Format','netcdf4','DeflateLevel',9);
    ncwrite(outfile,'date',est.date);
    ncwriteatt(outfile,'date','description','yyyymmdd');
    
    %%%
    nccreate(outfile,'tlr','Datatype','single','Dimensions',dim_day,'Format','netcdf4','DeflateLevel',9);
    ncwrite(outfile,'tlr',tlr);
    ncwriteatt(outfile,'tlr','description','monthly temperature lapse rate derived from MERRA-2 data');
end

%2. write observations
% var_obs
varname=[varvv,'_obs'];
if ~ismember(varname,varold) || Overwrite==1
    if ~ismember(varname,varold); ov=1; else; ov=0; end
    value=obs.data;
    dim=dim_day;
    att={'description','raw observed data'};
    f_writevariable(outfile,varname,value,dim,att,ov);
end

% var_qflag1
varname=[varvv,'_qflag1'];
if ~ismember(varname,varold) || Overwrite==1
    if ~ismember(varname,varold); ov=1; else; ov=0; end
    value=obs.qflag1;
    dim=dim_day;
    att={'description','quality flag from raw database';...
        'value','0:good, >0:fail in quality control'};
    f_writevariable(outfile,varname,value,dim,att,ov);
end

% var_qflag2
varname=[varvv,'_qflag2'];
if ~ismember(varname,varold) || Overwrite==1
    if ~ismember(varname,varold); ov=1; else; ov=0; end
    value=obs.qflag2;
    dim=dim_day;
    att={'description','quality flag added by developers';...
        'value','0:good, >0:fail in quality control'};
    f_writevariable(outfile,varname,value,dim,att,ov);
end

% var_est1
varname=[varvv,'_est1'];
if ~ismember(varname,varold) || Overwrite==1
    if ~ismember(varname,varold); ov=1; else; ov=0; end
    value=est.dfill;
    dim=cat(2,dim_day,dim_est);
    att={'description','estimates of all strategies based on all station records';...
        'strategy','QMN-1 to 4,QMR-1 to 5, INT-1 to 4, MAL-1 to 2, MRG-1 to 2'};
    f_writevariable(outfile,varname,value,dim,att,ov);
end

% var_est2
varname=[varvv,'_est2'];
if ~ismember(varname,varold) || Overwrite==1
    if ~ismember(varname,varold); ov=1; else; ov=0; end
    value=est.dreco;
    dim=cat(2,dim_day,dim_est);
    att={'description','estimates of all strategies based on 70% station records';...
        'strategy','QMN-1 to 4,QMR-1 to 5, INT-1 to 4, MAL-1 to 2, MRG-1 to 2'};
    f_writevariable(outfile,varname,value,dim,att,ov);
end

% var_est1_met
varname=[varvv,'_est1_met'];
if ~ismember(varname,varold) || Overwrite==1
    if ~ismember(varname,varold); ov=1; else; ov=0; end
    value=est.metfill;
    dim=cat(2,dim_est,dim_met1);
    att={'description','accuracy metrics of _est1';...
        'strategy','QMN-1 to 4,QMR-1 to 5, INT-1 to 4, MAL-1 to 2, MRG-1 to 2';...
        'metric','KGE,KGE-r,KGE-gamma,KGE-beta'};
    f_writevariable(outfile,varname,value,dim,att,ov);
end

% var_est2_met
varname=[varvv,'_est2_met'];
if ~ismember(varname,varold) || Overwrite==1
    if ~ismember(varname,varold); ov=1; else; ov=0; end
    value=est.metreco;
    dim=cat(2,dim_est,dim_met1);
    att={'description','accuracy metrics of _est2';...
         'strategy','QMN-1 to 4,QMR-1 to 5, INT-1 to 4, MAL-1 to 2, MRG-1 to 2';...
         'metric','KGE,KGE-r,KGE-gamma,KGE-beta'};
    f_writevariable(outfile,varname,value,dim,att,ov);
end

% var_scd
varname=[varvv,'_scd'];
if ~ismember(varname,varold) || Overwrite==1
    if ~ismember(varname,varold); ov=1; else; ov=0; end
    value=est.scd;
    dim=dim_day;
    att={'description','merged serially complete dataset (scd)'};
    f_writevariable(outfile,varname,value,dim,att,ov);
end

% var_source
varname=[varvv,'_source'];
if ~ismember(varname,varold) || Overwrite==1
    if ~ismember(varname,varold); ov=1; else; ov=0; end
    value=est.source;
    dim=dim_day;
    att={'description','serially complete dataset (scd) sources corresponding to different strategies'};
    f_writevariable(outfile,varname,value,dim,att,ov);
end

% var_metric
varname=[varvv,'_metric'];
if ~ismember(varname,varold) || Overwrite==1
    if ~ismember(varname,varold); ov=1; else; ov=0; end
    value=est.metric;
    dim=cat(2,dim_met2,dim_met1);
    att={'description','metrics of filled (1st row) and reconstructed (2nd row) scd estimates';...
        'metric','KGE,KGE-r,KGE-gamma,KGE-beta'};
    f_writevariable(outfile,varname,value,dim,att,ov);
end


% var_scd_corr
varname=[varvv,'_scd_corr'];
if ~ismember(varname,varold) || Overwrite==1
    if ~ismember(varname,varold); ov=1; else; ov=0; end
    value=est.scd_corr;
    dim=dim_day;
    att={'description','corrected merged serially complete dataset (scd)'};
    f_writevariable(outfile,varname,value,dim,att,ov);
end

% var_metric_corr
varname=[varvv,'_metric_corr'];
if ~ismember(varname,varold) || Overwrite==1
    if ~ismember(varname,varold); ov=1; else; ov=0; end
    value=est.metric_corr;
    dim=cat(2,dim_met3,dim_met1);
    att={'description','metrics of corrected SCD for year (1st row) and DOY1-366 (2nd-367 row)';...
        'metric','KGE,KGE-r,KGE-gamma,KGE-beta'};
    f_writevariable(outfile,varname,value,dim,att,ov);
end

% var_corrflag
varname=[varvv,'_corrflag'];
if ~ismember(varname,varold) || Overwrite==1
    if ~ismember(varname,varold); ov=1; else; ov=0; end
    value=est.flag_corr;
    dim=dim_cont;
    att={'description','1: CDF correction; 0: No CDF correction'};
    f_writevariable(outfile,varname,value,dim,att,ov);
end
end

function f_writevariable(outfile,varname,value,dim,att,ov)
value=single(value);
if ov==1 % need to create the variable
    nccreate(outfile,varname,'Datatype','single','Dimensions',dim,'Format','netcdf4','DeflateLevel',9);
%     dimstr='{';
%     for i=1:size(dim,1)
%         dimi=['''',dim{i,1},''',',num2str(dim{i,2})];
%         dimstr=[dimstr,dimi];
%         if i<size(dim,1)
%             dimstr=[dimstr,','];
%         else
%             dimstr=[dimstr,'}'];
%         end
%     end
%     command=['nccreate(outfile,''',varname,''',''Datatype'',''single'',''Dimensions'',',...
%         dimstr,',''Format'',''netcdf4'',''DeflateLevel'',9,''FillValue'',-999);'];
%     eval(command);
end

% write value
ncwrite(outfile,varname,value);

%write attributes
for i=1:size(att,1)
    ncwriteatt(outfile,varname,att{i,1},att{i,2});
end
end
