function [ID_ghcn,ID_eccc,ID_mexico,flag_ghcn,flag_eccc,flag_mexico]=f_IDmerge(Inpath_GHCN,Inpath_ECCC,Inpath_Mexico,outfile1)
% just keep the one with longer periods
% flag==1 means using this station. flag==0 means dropping it
if exist(outfile1,'file')
    load(outfile1,'ID_ghcn','ID_mexico','ID_eccc','flag_ghcn','flag_eccc','flag_mexico')
    return;
end

%% 1. merge ghcn and eccc. they have same ID styles
dirg=dir(fullfile(Inpath_GHCN,'*.mat'));
dire=dir(fullfile(Inpath_ECCC,'*.mat'));
ID_ghcn=cell(length(dirg),1);
fi=1;
for i=1:length(dirg)
    temp=dirg(i).name(1:end-4);
    if length(temp)==11
        ID_ghcn{fi}=temp;
        fi=fi+1;
    end
end
ID_ghcn(fi:end)=[];

ID_eccc=cell(length(dire),1);
fi=1;
for i=1:length(dire)
    temp=dire(i).name(1:end-4);
    if length(temp)==11
        ID_eccc{fi}=temp;
        fi=fi+1;
    end
end
ID_eccc(fi:end)=[];

% separate IDe into two parts: in or not in IDg
[indin,indg]=ismember(ID_eccc,ID_ghcn);
flag_ghcn=ones(length(ID_ghcn),1);
flag_eccc=zeros(length(ID_eccc),1);
samplediff=nan*zeros(length(ID_eccc),1);
for i=1:length(ID_eccc)
    if indin(i)
       fileg=[Inpath_GHCN,'/',ID_eccc{i},'.mat']; dg=load(fileg,'data');
       filee=[Inpath_ECCC,'/',ID_eccc{i},'.mat']; de=load(filee,'data');
       numg=sum(~isnan(dg.data(:,2))); % for prcp
       nume=sum(~isnan(de.data(:,2))); % for prcp
       samplediff(i)=nume-numg;
       if numg<nume
           flag_ghcn(indg(i))=0;
           flag_eccc(i)=1;
       end
    else
        flag_eccc(i)=1;
    end
end

%%  2. merge ghcn and mexico. they have different ID styles
dirm=dir(fullfile(Inpath_Mexico,'*.mat'));
ID_mexico=cell(length(dirm),1);
for i=1:length(dirm)
    ID_mexico{i}=dirm(i).name(1:end-4);
end

IDg2=cell(length(ID_ghcn),1);
for i=1:length(ID_ghcn)
    if strcmp(ID_ghcn{i}(1:2),'MX')
        IDg2{i}=['9',ID_ghcn{i}(5:end)];
    else
        IDg2{i}='xxx';
    end
end

% separate IDm into two parts: in or not in IDg
[indin2,indg2]=ismember(ID_mexico,IDg2);
flag_mexico=zeros(length(ID_mexico),1);
for i=1:length(ID_mexico)
    if indin2(i)
       fileg=[Inpath_GHCN,'/',ID_ghcn{indg2(i)},'.mat']; dg=load(fileg,'data');
       filem=[Inpath_Mexico,'/',ID_mexico{i},'.mat']; dm=load(filem,'data');
       numg=sum(~isnan(dg.data(:,2))); % for prcp
       numm=sum(~isnan(dm.data(:,2))); % for prcp
       if numg<numm
           flag_ghcn(indg2(i))=0;
           flag_mexico(i)=1;
       end
    else
        flag_mexico(i)=1;
    end
end

save(outfile1,'ID_ghcn','ID_mexico','ID_eccc','flag_ghcn','flag_eccc','flag_mexico')
end