function [IDne_num,IDne_dist]=f_FindNearGauge(lat,lon,radius)
% up to ten neighboring stations within 400 km.
gnum=length(lat);
IDne_num=nan*zeros(gnum,10); % 10 is the most
IDne_dist=nan*zeros(gnum,10); % 10 is the most

lat2=lat;
lon2=lon;
IDnum=(1:gnum)';
for i=1:gnum
    lat1i=repmat(lat(i),gnum,1);
    lon1i=repmat(lon(i),gnum,1);
    
    disi=zeros(gnum,2);
    disi(:,1)=IDnum;
    disi(:,2)=lldistkm(lat1i,lon1i,lat2,lon2);
    disi(i,:)=1000;
    disi(disi(:,2)>radius,:)=[];
    if ~isempty(disi)
        disi2=sortrows(disi,2);
        gn=size(disi2,1);
        if gn>=10         
            IDne_num(i,1:10)=disi2(1:10,1);
            IDne_dist(i,1:10)=disi2(1:10,2);
        else
            IDne_num(i,1:gn)=disi2(1:gn,1);
            IDne_dist(i,1:gn)=disi2(1:gn,2);
        end
    end
    if mod(i,100)==0
       fprintf('Find Near Gauge %d--%d\n',i,gnum); 
    end
end

end


