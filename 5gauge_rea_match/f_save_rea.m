function f_save_rea(Outfile,prcp,tmin,tmax,tmean,ID,LLE,date,BasicInfo,DEM_rea,TLR_rea)
if exist(Outfile,'file')
    delete(Outfile);
end

days=length(date);
gnum=size(ID,1);

prcp(isnan(prcp))=-999;
nccreate(Outfile,'prcp','Datatype','single',...
    'Dimensions',{'days',days,'gnum',gnum},...
    'Format','netcdf4','DeflateLevel',9,'FillValue',-999);
ncwrite(Outfile,'prcp',prcp);
ncwriteatt(Outfile,'prcp','description','reanalysis data matched with gauges');
ncwriteatt(Outfile,'prcp','row','date');
ncwriteatt(Outfile,'prcp','col','corresponding to each gauge in ID');
ncwriteatt(Outfile,'prcp','unit','mm/d');

tmin(isnan(tmin))=-999;
nccreate(Outfile,'tmin','Datatype','single',...
    'Dimensions',{'days',days,'gnum',gnum},...
    'Format','netcdf4','DeflateLevel',9,'FillValue',-999);
ncwrite(Outfile,'tmin',tmin);
ncwriteatt(Outfile,'tmin','description','reanalysis data matched with gauges');
ncwriteatt(Outfile,'tmin','row','date');
ncwriteatt(Outfile,'tmin','col','corresponding to each gauge in ID');
ncwriteatt(Outfile,'tmin','unit','C');

tmax(isnan(tmax))=-999;
nccreate(Outfile,'tmax','Datatype','single',...
    'Dimensions',{'days',days,'gnum',gnum},...
    'Format','netcdf4','DeflateLevel',9,'FillValue',-999);
ncwrite(Outfile,'tmax',tmax);
ncwriteatt(Outfile,'tmax','description','reanalysis data matched with gauges');
ncwriteatt(Outfile,'tmax','row','date');
ncwriteatt(Outfile,'tmax','col','corresponding to each gauge in ID');
ncwriteatt(Outfile,'tmax','unit','C');

tmean(isnan(tmean))=-999;
nccreate(Outfile,'tmean','Datatype','single',...
    'Dimensions',{'days',days,'gnum',gnum},...
    'Format','netcdf4','DeflateLevel',9,'FillValue',-999);
ncwrite(Outfile,'tmean',tmean);
ncwriteatt(Outfile,'tmean','description','reanalysis data matched with gauges');
ncwriteatt(Outfile,'tmean','row','date');
ncwriteatt(Outfile,'tmean','col','corresponding to each gauge in ID');
ncwriteatt(Outfile,'tmean','unit','C');

nccreate(Outfile,'date','Datatype','double',...
    'Dimensions',{'days',days},...
    'Format','netcdf4','DeflateLevel',9,'FillValue',-999);
ncwrite(Outfile,'date',date);
ncwriteatt(Outfile,'date','description','yyyymmdd');

nccreate(Outfile,'ID','Datatype','char',...
    'Dimensions',{'gnum',gnum,'dimID',size(ID,2)},...
    'Format','netcdf4','DeflateLevel',9);
ncwrite(Outfile,'ID',ID);
ncwriteatt(Outfile,'ID','description','ID of stations');

nccreate(Outfile,'LLE','Datatype','double',...
    'Dimensions',{'gnum',gnum,'dimLLE',size(LLE,2)},...
    'Format','netcdf4','DeflateLevel',9,'FillValue',-999);
ncwrite(Outfile,'LLE',LLE);
ncwriteatt(Outfile,'LLE','description','lat lon elev of stations');

DEM_rea(isnan(DEM_rea))=-999;
nccreate(Outfile,'DEM_rea','Datatype','double',...
    'Dimensions',{'gnum',gnum},...
    'Format','netcdf4','DeflateLevel',9,'FillValue',-999);
ncwrite(Outfile,'DEM_rea',DEM_rea);
ncwriteatt(Outfile,'DEM_rea','description','elevation of reanalysis data at 0.1 degree resolution');

TLR_rea(isnan(TLR_rea))=-999;
nccreate(Outfile,'TLR_rea','Datatype','double',...
    'Dimensions',{'days',days,'gnum',gnum},...
    'Format','netcdf4','DeflateLevel',9,'FillValue',-999);
ncwrite(Outfile,'TLR_rea',TLR_rea);
ncwriteatt(Outfile,'TLR_rea','description','temperature lapse rate corresponding to stations that are used for tmin/tmax/tmean downscaling to point scale');

nccreate(Outfile,'BasicInfo','Datatype','double',...
    'Dimensions',{'dimBI',length(BasicInfo)},...
    'Format','netcdf4','DeflateLevel',9,'FillValue',-999);
ncwrite(Outfile,'BasicInfo',BasicInfo);
ncwriteatt(Outfile,'BasicInfo','description','Xll,Yll,tXll,tYll,cellsize');
end