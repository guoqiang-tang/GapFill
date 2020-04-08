function f_save_stn(Outfile,ID,LLE,date,prcp,tmin,tmax,...
    prcp_qfraw,tmin_qfraw,tmax_qfraw,...
    prcp_qf,tmin_qf,tmax_qf,mflag,overwrite)
if exist(Outfile,'file')&&overwrite==1
   delete(Outfile); 
end
% ID from cell to char
IDstr=cell2mat(ID);

% dimensions
nday=length(date);
nstn=size(IDstr,1);
nchar=size(IDstr,2);

% write basic infomation
nccreate(Outfile,'ID','Datatype','char','Dimensions',{'nstn',nstn,'nchar',nchar},'Format','netcdf4','DeflateLevel',9);
ncwrite(Outfile,'ID',IDstr);
ncwriteatt(Outfile,'ID','description','station IDs');
ncwriteatt(Outfile,'ID','Char1-2','station source. GH: ghcn-d, GS: gsod, EC: eccc, ME: mexico, MR: merge');
ncwriteatt(Outfile,'ID','Char3-end','ID from original sources. For ME, it is Char6-end.');
ncwriteatt(Outfile,'ID','MergeInfo','MR merges stations with same lat/lon and Char3-end of MR is from the source in order of GH GS EC ME');
clear ID


nccreate(Outfile,'LLE','Datatype','single',...
'Dimensions',{'nstn',nstn,'dimLLE',size(LLE,2)},...
'Format','netcdf4','DeflateLevel',9,'FillValue',-999);
ncwrite(Outfile,'LLE',LLE);
ncwriteatt(Outfile,'LLE','description','latitude, longitude, and elevation');
clear LLE

nccreate(Outfile,'date','Datatype','double','Dimensions',{'nday',nday},'Format','netcdf4','DeflateLevel',9);
ncwrite(Outfile,'date',date);
ncwriteatt(Outfile,'date','description','yyyymmdd');
clear date

% write variables
prcp(isnan(prcp))=-999;
nccreate(Outfile,'prcp','Datatype','single','Dimensions',{'nday',nday,'nstn',nstn},'Format','netcdf4','DeflateLevel',9,'FillValue',-999);
ncwrite(Outfile,'prcp',prcp);
ncwriteatt(Outfile,'prcp','description','precipitation (mm/d)');
clear prcp

tmin(isnan(tmin))=-999;
nccreate(Outfile,'tmin','Datatype','single','Dimensions',{'nday',nday,'nstn',nstn},'Format','netcdf4','DeflateLevel',9,'FillValue',-999);
ncwrite(Outfile,'tmin',tmin);
ncwriteatt(Outfile,'tmin','description','minimum temperature (C)');
clear tmin

tmax(isnan(tmax))=-999;
nccreate(Outfile,'tmax','Datatype','single','Dimensions',{'nday',nday,'nstn',nstn},'Format','netcdf4','DeflateLevel',9,'FillValue',-999);
ncwrite(Outfile,'tmax',tmax);
ncwriteatt(Outfile,'tmax','description','maximum temperature (C)');
clear tmax

% write flags
prcp_qfraw(isnan(prcp_qfraw))=-999;
nccreate(Outfile,'prcp_qfraw','Datatype','int16','Dimensions',{'nday',nday,'nstn',nstn},'Format','netcdf4','DeflateLevel',9,'FillValue',-999);
ncwrite(Outfile,'prcp_qfraw',prcp_qfraw);
ncwriteatt(Outfile,'prcp_qfraw','description','prcp quality flag (ascii values) from original data sets ');
ncwriteatt(Outfile,'prcp_qfraw','fillvalue','no flags are available');
ncwriteatt(Outfile,'prcp_qfraw','Value-0','pass all quality control assurance check');
ncwriteatt(Outfile,'prcp_qfraw','Value-68','D in GHCND. failed duplicate check');
ncwriteatt(Outfile,'prcp_qfraw','Value-71','G in GHCND. failed gap check');
ncwriteatt(Outfile,'prcp_qfraw','Value-73','I in GHCND. failed internal consistency check');
ncwriteatt(Outfile,'prcp_qfraw','Value-75','K in GHCND. failed streak/frequent-value check');
ncwriteatt(Outfile,'prcp_qfraw','Value-76','L in GHCND. failed check on length of multiday period');
ncwriteatt(Outfile,'prcp_qfraw','Value-77','M in GHCND. failed megaconsistency check');
ncwriteatt(Outfile,'prcp_qfraw','Value-78','N in GHCND. failed naught check');
ncwriteatt(Outfile,'prcp_qfraw','Value-79','O in GHCND. failed climatological outlier check');
ncwriteatt(Outfile,'prcp_qfraw','Value-82','R in GHCND. failed lagged range check');
ncwriteatt(Outfile,'prcp_qfraw','Value-83','S in GHCND. failed spatial consistency check');
ncwriteatt(Outfile,'prcp_qfraw','Value-84','T in GHCND. failed temporal consistency check');
ncwriteatt(Outfile,'prcp_qfraw','Value-87','W in GHCND. temperature too warm for snow');
ncwriteatt(Outfile,'prcp_qfraw','Value-88','X in GHCND. failed bounds check');
ncwriteatt(Outfile,'prcp_qfraw','Value-90','Z in GHCND. flagged as a result of an official Datzilla investigation');
clear prcp_qfraw

tmin_qfraw(isnan(tmin_qfraw))=-999;
nccreate(Outfile,'tmin_qfraw','Datatype','int16','Dimensions',{'nday',nday,'nstn',nstn},'Format','netcdf4','DeflateLevel',9,'FillValue',-999);
ncwrite(Outfile,'tmin_qfraw',tmin_qfraw);
ncwriteatt(Outfile,'tmin_qfraw','description','prcp quality flag (ascii values) from original data sets ');
ncwriteatt(Outfile,'tmin_qfraw','fillvalue','no flags are available');
ncwriteatt(Outfile,'tmin_qfraw','Value-0','pass all quality control assurance check');
ncwriteatt(Outfile,'tmin_qfraw','Value-68','D in GHCND. failed duplicate check');
ncwriteatt(Outfile,'tmin_qfraw','Value-71','G in GHCND. failed gap check');
ncwriteatt(Outfile,'tmin_qfraw','Value-73','I in GHCND. failed internal consistency check');
ncwriteatt(Outfile,'tmin_qfraw','Value-75','K in GHCND. failed streak/frequent-value check');
ncwriteatt(Outfile,'tmin_qfraw','Value-76','L in GHCND. failed check on length of multiday period');
ncwriteatt(Outfile,'tmin_qfraw','Value-77','M in GHCND. failed megaconsistency check');
ncwriteatt(Outfile,'tmin_qfraw','Value-78','N in GHCND. failed naught check');
ncwriteatt(Outfile,'tmin_qfraw','Value-79','O in GHCND. failed climatological outlier check');
ncwriteatt(Outfile,'tmin_qfraw','Value-82','R in GHCND. failed lagged range check');
ncwriteatt(Outfile,'tmin_qfraw','Value-83','S in GHCND. failed spatial consistency check');
ncwriteatt(Outfile,'tmin_qfraw','Value-84','T in GHCND. failed temporal consistency check');
ncwriteatt(Outfile,'tmin_qfraw','Value-87','W in GHCND. temperature too warm for snow');
ncwriteatt(Outfile,'tmin_qfraw','Value-88','X in GHCND. failed bounds check');
ncwriteatt(Outfile,'tmin_qfraw','Value-90','Z in GHCND. flagged as a result of an official Datzilla investigation');
clear tmin_qfraw

tmax_qfraw(isnan(tmax_qfraw))=-999;
nccreate(Outfile,'tmax_qfraw','Datatype','int16','Dimensions',{'nday',nday,'nstn',nstn},'Format','netcdf4','DeflateLevel',9,'FillValue',-999);
ncwrite(Outfile,'tmax_qfraw',tmax_qfraw);
ncwriteatt(Outfile,'tmax_qfraw','description','prcp quality flag (ascii values) from original data sets ');
ncwriteatt(Outfile,'tmax_qfraw','fillvalue','no flags are available');
ncwriteatt(Outfile,'tmax_qfraw','Value-0','pass all quality control assurance check');
ncwriteatt(Outfile,'tmax_qfraw','Value-68','D in GHCND. failed duplicate check');
ncwriteatt(Outfile,'tmax_qfraw','Value-71','G in GHCND. failed gap check');
ncwriteatt(Outfile,'tmax_qfraw','Value-73','I in GHCND. failed internal consistency check');
ncwriteatt(Outfile,'tmax_qfraw','Value-75','K in GHCND. failed streak/frequent-value check');
ncwriteatt(Outfile,'tmax_qfraw','Value-76','L in GHCND. failed check on length of multiday period');
ncwriteatt(Outfile,'tmax_qfraw','Value-77','M in GHCND. failed megaconsistency check');
ncwriteatt(Outfile,'tmax_qfraw','Value-78','N in GHCND. failed naught check');
ncwriteatt(Outfile,'tmax_qfraw','Value-79','O in GHCND. failed climatological outlier check');
ncwriteatt(Outfile,'tmax_qfraw','Value-82','R in GHCND. failed lagged range check');
ncwriteatt(Outfile,'tmax_qfraw','Value-83','S in GHCND. failed spatial consistency check');
ncwriteatt(Outfile,'tmax_qfraw','Value-84','T in GHCND. failed temporal consistency check');
ncwriteatt(Outfile,'tmax_qfraw','Value-87','W in GHCND. temperature too warm for snow');
ncwriteatt(Outfile,'tmax_qfraw','Value-88','X in GHCND. failed bounds check');
ncwriteatt(Outfile,'tmax_qfraw','Value-90','Z in GHCND. flagged as a result of an official Datzilla investigation');
clear tmax_qfraw

prcp_qf(isnan(prcp_qf))=-999;
nccreate(Outfile,'prcp_qf','Datatype','int16','Dimensions',{'nday',nday,'nstn',nstn},'Format','netcdf4','DeflateLevel',9,'FillValue',-999);
ncwrite(Outfile,'prcp_qf',prcp_qf);
ncwriteatt(Outfile,'prcp_qf','description','prcp quality flag (ascii values) from original data sets ');
ncwriteatt(Outfile,'prcp_qf','fillvalue','no flags are available');
ncwriteatt(Outfile,'prcp_qf','Value-0','pass all quality control assurance check');
ncwriteatt(Outfile,'prcp_qf','Value-33','used in APHRODITE. failed non-zero repetition check');
ncwriteatt(Outfile,'prcp_qf','Value-34','used in APHRODITE. failed zero repetition check');
ncwriteatt(Outfile,'prcp_qf','Value-35','used in APHRODITE. duplication of monthly or sub-monthly records');
ncwriteatt(Outfile,'prcp_qf','Value-36','used in APHRODITE. outliers');
ncwriteatt(Outfile,'prcp_qf','Value-37','used in APHRODITE. spatiotemporally isolated values');
ncwriteatt(Outfile,'prcp_qf','Value-38','used in APHRODITE. failed basic feature check');
ncwriteatt(Outfile,'prcp_qf','Value-68','D in GHCND. failed duplicate check');
ncwriteatt(Outfile,'prcp_qf','Value-69','E in GHCND. failed world record exceedance check');
ncwriteatt(Outfile,'prcp_qf','Value-71','G in GHCND. failed gap check');
ncwriteatt(Outfile,'prcp_qf','Value-75','K in GHCND. failed streak/frequent-value check');
ncwriteatt(Outfile,'prcp_qf','Value-79','O in GHCND. failed climatological outlier check');
ncwriteatt(Outfile,'prcp_qf','Value-83','S in GHCND. failed spatial consistency check');
clear prcp_qf

tmin_qf(isnan(tmin_qf))=-999;
nccreate(Outfile,'tmin_qf','Datatype','int16','Dimensions',{'nday',nday,'nstn',nstn},'Format','netcdf4','DeflateLevel',9,'FillValue',-999);
ncwrite(Outfile,'tmin_qf',tmin_qf);
ncwriteatt(Outfile,'tmin_qf','description','prcp quality flag (ascii values) from original data sets ');
ncwriteatt(Outfile,'tmin_qf','fillvalue','no flags are available');
ncwriteatt(Outfile,'tmin_qf','Value-0','pass all quality control assurance check');
ncwriteatt(Outfile,'tmin_qf','Value-68','D in GHCND. failed duplicate check');
ncwriteatt(Outfile,'tmin_qf','Value-69','E in GHCND. failed world record exceedance check');
ncwriteatt(Outfile,'tmin_qf','Value-71','G in GHCND. failed gap check');
ncwriteatt(Outfile,'tmin_qf','Value-73','I in GHCND. failed internal consistency check');
ncwriteatt(Outfile,'tmin_qf','Value-75','K in GHCND. failed streak/frequent-value check');
ncwriteatt(Outfile,'tmin_qf','Value-77','M in GHCND. failed megaconsistency check');
ncwriteatt(Outfile,'tmin_qf','Value-79','O in GHCND. failed climatological outlier check');
ncwriteatt(Outfile,'tmin_qf','Value-82','R in GHCND. failed lagged range check');
ncwriteatt(Outfile,'tmin_qf','Value-83','S in GHCND. failed spatial consistency check');
ncwriteatt(Outfile,'tmin_qf','Value-84','T in GHCND. failed temporal consistency check');
clear tmin_qf

tmax_qf(isnan(tmax_qf))=-999;
nccreate(Outfile,'tmax_qf','Datatype','int16','Dimensions',{'nday',nday,'nstn',nstn},'Format','netcdf4','DeflateLevel',9,'FillValue',-999);
ncwrite(Outfile,'tmax_qf',tmax_qf);
ncwriteatt(Outfile,'tmax_qf','description','prcp quality flag (ascii values) from original data sets ');
ncwriteatt(Outfile,'tmax_qf','fillvalue','no flags are available');
ncwriteatt(Outfile,'tmax_qf','Value-0','pass all quality control assurance check');
ncwriteatt(Outfile,'tmax_qf','Value-68','D in GHCND. failed duplicate check');
ncwriteatt(Outfile,'tmax_qf','Value-69','E in GHCND. failed world record exceedance check');
ncwriteatt(Outfile,'tmax_qf','Value-71','G in GHCND. failed gap check');
ncwriteatt(Outfile,'tmax_qf','Value-73','I in GHCND. failed internal consistency check');
ncwriteatt(Outfile,'tmax_qf','Value-75','K in GHCND. failed streak/frequent-value check');
ncwriteatt(Outfile,'tmax_qf','Value-77','M in GHCND. failed megaconsistency check');
ncwriteatt(Outfile,'tmax_qf','Value-79','O in GHCND. failed climatological outlier check');
ncwriteatt(Outfile,'tmax_qf','Value-82','R in GHCND. failed lagged range check');
ncwriteatt(Outfile,'tmax_qf','Value-83','S in GHCND. failed spatial consistency check');
ncwriteatt(Outfile,'tmax_qf','Value-84','T in GHCND. failed temporal consistency check');
clear tmax_qf

mflag(isnan(mflag))=-999;
nccreate(Outfile,'mflag','Datatype','int16','Dimensions',{'nday',nday,'nstn',nstn},'Format','netcdf4','DeflateLevel',9,'FillValue',-999);
ncwrite(Outfile,'mflag',mflag);
ncwriteatt(Outfile,'mflag','description','measurement flags');
ncwriteatt(Outfile,'mflag','Value-0','fill value (-999 or NaN) to fit date extent to enable unfied storage of all stations');
ncwriteatt(Outfile,'mflag','Value-1','station measurements');
clear mflag
end