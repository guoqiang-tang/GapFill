function dataall=f_reanalysis_extract(Inpath,prefix,rowg,colg,years,yeare)
dataall=[];

for yy=years:yeare
	fprintf('%s-%d--%d\n',prefix,yy,yeare);
    daysyy=datenum(yy,12,31)-datenum(yy,1,1)+1;
    file=[Inpath,'/',prefix,num2str(yy),'.nc4'];
    if ~exist(file,'file')
        ddyy=nan*zeros(daysyy,length(rowg));
    else
        data=ncread(file,'data');
        if size(data,3)~=daysyy
            error('Reanalysis data have different dates with the defined date');
        end
        ddyy=[];
        for gg=1:length(rowg)
            datagg=squeeze(data(rowg(gg),colg(gg),:));
            datagg=datagg(:);
            ddyy=cat(2,ddyy,datagg);
        end
    end
    dataall=cat(1,dataall,ddyy);
end

end