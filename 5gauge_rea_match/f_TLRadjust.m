function T=f_TLRadjust(T,DEM_rea,LLE,TLR_rea)
DEMdiff=(DEM_rea-LLE(:,3))/1000;
DEMdiff=DEMdiff';
DEMdiff=repmat(DEMdiff,size(T,1),1);
T=T+DEMdiff.*TLR_rea;
end