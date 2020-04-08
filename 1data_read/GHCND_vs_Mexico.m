clc;clear;close all
path1='/home/gut428/GapFill/Data/mexico';
path2='/home/gut428/GapFill/Data/ghcn-d';
dir1=dir(fullfile(path1,'*.mat'));

% extract id of ghcn-d
filestation=[path2,'/GaugeValid.mat'];
load(filestation,'GaugeValid');
ID=GaugeValid.ID;
IDghcn=cell(6000,1);
flag=1;
for i=1:length(ID)
    if strcmp(ID{i}(1:2),'MX')
        IDghcn{flag}=ID{i};
        flag=flag+1;
    end
end
IDghcn(flag:end)=[];

% read ghcn and mexico data
CC=nan*zeros(length(IDghcn),2);
validnum=zeros(length(IDghcn),6);
for i=1:length(IDghcn)
    fprintf('%d--%d\n',i,length(IDghcn));
    file1=[path2,'/',IDghcn{i},'.mat'];
    load(file1,'data'); 
    dghcn=data; clear data
    
    file2=[path1,'/9',IDghcn{i}(5:end),'.mat'];
    if exist(file2,'file')
        load(file2,'data');
        dmexico=data;  clear data
        
        % valid number
        validnum(i,1:3)=sum(~isnan(dghcn(:,2:4)));
        validnum(i,4:6)=sum(~isnan(dmexico(:,2:4)));
        
        % correlation
        [ind1,ind2]=ismember(dmexico(:,1),dghcn(:,1));
        ind2(ind2==0)=[];
        dd=[dmexico(ind1,2),dghcn(ind2,2)];
        dd(isnan(dd(:,1))|isnan(dd(:,2)),:)=[];
        
        if length(dd)>3
            CC(i,1)=corr(dd(:,1),dd(:,2),'Type','Pearson');   
            CC(i,2)=nanmean(dd(:,1))-nanmean(dd(:,2));
        end
    end
end

save test validnum CC

% find stations in mexico but not in ghcn
IDghcn2=zeros(length(IDghcn),1);
for i=1:length(IDghcn)
    IDghcn2(i)=str2double(['9',IDghcn{i}(5:end)]);
end

IDmexico=zeros(length(dir1),1);
for i=1:length(dir1)
    IDmexico(i)=str2double(dir1(i).name(1:end-4));
end

[ind1,ind2]=ismember(IDmexico,IDghcn2);

[ind21,ind22]=ismember(IDghcn2,IDmexico);


