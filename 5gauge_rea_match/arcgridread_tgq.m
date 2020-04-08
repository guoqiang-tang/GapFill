function MM=arcgridread_tgq(file)
% read header
fid=fopen(file,'r');
for i=1:6
    li=fgetl(fid);
    li2=regexp(li,' ','split');
    vi=str2double(li2{end});
    switch li2{1}
        case 'nrows'
            nrows=vi;
        case 'ncols'
            ncols=vi;
        case 'xllcorner'
            xllcorner=vi;
        case 'yllcorner'
            yllcorner=vi;
        case 'cellsize'
            cellsize=vi;
        case 'NODATA_value'
            NODATA_value=vi;
    end
end
fclose(fid);

% read matrix
% mask=readmatrix(file,'Range',7); % read matrix cannot be used in lower
% version
% mask(:,end)=[]; % /n
% if size(mask,1)~=nrows||size(mask,2)~=ncols
%    error('wrong matrix size') 
% end

fid=fopen(file,'r');
for i=1:6
    fgetl(fid);
end
mask=nan*zeros(nrows,ncols);
flag=1;
while ~feof(fid)
    li=fgetl(fid);
    li2=regexp(li,' ','split');
    if isempty(li2{end})
    li2(end)=[];
    end
    mask(flag,:)=str2double(li2);
    flag=flag+1;
end
fclose(fid);

mask(mask==NODATA_value)=nan;

MM.mask=mask;
MM.nrows=nrows;
MM.ncols=ncols;
MM.cellsize=cellsize;
MM.xll=xllcorner;
MM.yll=yllcorner;
MM.xll2=xllcorner+ncols*cellsize;
MM.yll2=yllcorner+nrows*cellsize;

end