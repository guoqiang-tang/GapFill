function Tadd=ff_Tdownscale_lp(XX1,YY1,REAinfo,DEMHigh,DEMLow,lprate)
% there are three kinds of temperature lapse rate
% 1. fixed value, e.g., -6.5
% 2. 2-D values, e.g., [nrows, ncols] same with din, but do not change with time
% 3. 3-D values, e.g., [nrows, ncols, ntimes] same with din
lpdim=length(size(lprate));
if lpdim==3
    error('3-D codes have not been written');
end

% find the closest grid in DEM1 corresponding to each DEM2 pixel
% center match
size0=size(XX1);
XX1=XX1(:);
YY1=YY1(:);
row=floor((REAinfo.yll+REAinfo.Ysize*REAinfo.nrows-YY1)/REAinfo.Ysize)+1;
col=floor((XX1-REAinfo.xll)/REAinfo.Xsize)+1;
Tindex=sub2ind(size(DEMLow),row,col);

DEMdiff=DEMHigh(:)-DEMLow(Tindex);
DEMdiff=reshape(DEMdiff,size0(1),size0(2));
Tadd=DEMdiff.*lprate/1000;
end