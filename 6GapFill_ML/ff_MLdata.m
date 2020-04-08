function [xdata,ydata,xcomb]=ff_MLdata(data_reagg,data_stn_negg,data_stngg)
% defaul setting
leastnum=8*365; % least overlapped samples with ydata: Actually, this is performed in f_findnear. But to keep the independence of this code, we calculate it again
mostnode=5; % largest number of ANN input nodes

%0. xdata: [14610, N]: N is three reanalysis+several nearby stations
% ydata: [14610, 1]: has some/many NaN values
if ~isempty(data_stn_negg)
    xdata=[data_reagg,data_stn_negg];
else
    xdata=data_reagg;
end
ydata=data_stngg;
nday=length(data_stngg);

%1. exclude some nearby stations that CC is lower than reanalysis
% or overlapped samples with ydata are too few
% or has no observations when ydata also has no observations
num=size(xdata,2);
CC=nan*zeros(num,1);
indnan=isnan(ydata);
for i=1:num
    if sum(~isnan(xdata(indnan,i)))==0; continue; end
    di=[xdata(:,i), ydata];
    di(isnan(di(:,1))|isnan(di(:,2)),:)=[];
    numi=size(di,1);
    if numi>=leastnum
        CC(i)=corr(di(:,1),di(:,2),'Type','Pearson');
    end
end
indout=isnan(CC)|CC<min(CC(1:3)); % 1:3 is ERA5, JRA55, MERRA2
xdata(:,indout)=[]; CC(indout)=[];
if isempty(xdata)
   xdata=[];ydata=[]; xcomb=[];
   return;
end

if size(xdata,2)<=3  % only reanalysis data
    % estimate of different combinations
    xcomb=nan*zeros(2,mostnode);
    xcomb(1,1:2)=[1,2]; % ERA5, JRA55
    xcomb(2,1:3)=[1,2,3]; % ERA5, JRA55, MERRA2
    if size(xdata,2)==2
        xcomb(2,:)=[];
    end
    
else % reanalysis and neighboring stations
    [~,indrank]=sort(CC,'descend');
    xdata=xdata(:,indrank);
    ydatatemp=ydata;
    xcomb=zeros(nday,mostnode);
    for i=1:nday
       if ~isnan(ydatatemp(i)); continue; end
       xdatai=xdata(i,:);
       indi=find(~isnan(xdatai));
       leni=min(length(indi),mostnode);
       indi=indi(1:leni);       
       xcomb(i,1:leni)=indi;
    end
    % add the combination of ERA5, JRA55 // ERA5, JRA55, MERRA2 
    add1=[find(indrank==1),find(indrank==2),0,0,0];
    add2=[add1(1:2),find(indrank==3),0,0];
    xcomb=cat(1,xcomb,add1);
    xcomb=cat(1,xcomb,add2);
    xcomb=unique(xcomb,'rows');
    xcomb(xcomb(:,1)==0,:)=[];
    xcomb(xcomb==0)=nan;
end

end