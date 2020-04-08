function f_unify_save(Outpathunify,FileAllgauge,Inpath2,outfile3,Year)
% load ID information
load(outfile3,'ID_ghcn','ID_gsod','ID_mexico','ID_eccc','ID_merge',...
    'flag_ghcn','flag_gsod','flag_eccc','flag_mexico',...
    'lle_ghcn','lle_gsod','lle_eccc','lle_mexico','lle_merge',...
    'flagvalue');
prod={'ghcn','gsod','eccc','mexico'};
for i=1:length(prod)
   command=['ID_',prod{i},'(flag_',prod{i},'~=1)=[];']; eval(command);
   command=['lle_',prod{i},'(flag_',prod{i},'~=1,:)=[];']; eval(command);
end

date=datenum(Year(1),1,1):datenum(Year(2),12,31);
nday=length(date);
date=datestr(date,'yyyymmdd');
date=mat2cell(date,ones(nday,1),8);
date=str2double(date);
% (1) Unify ID and LLE
% ID_ghcn: 11 char      ID_eccc: 11 char
% ID_mexico: 8 char     ID_gsod: 11 char   ID_merge: 11 char
% final ID: 13 char. The first two chars are source indicators (ghcn--GH,
% gsod--GS, eccc--EC, mexico--ME (ME999 to increase 8 to 13), merge--MR
ID_merge(:,2)=[];

ID_ghcn=strcat('GH',ID_ghcn);
ID_gsod=strcat('GS',ID_gsod);
ID_eccc=strcat('EC',ID_eccc);
ID_mexico=strcat('ME999',ID_mexico);
ID_merge=strcat('MR',ID_merge);
ID=[ID_ghcn;ID_gsod;ID_eccc;ID_mexico;ID_merge];
LLE=[lle_ghcn;lle_gsod;lle_eccc;lle_mexico;lle_merge];
source=[ones(length(ID_ghcn),1);...
    ones(length(ID_gsod),1)*2;...
    ones(length(ID_eccc),1)*3;...
    ones(length(ID_mexico),1)*4;...
    ones(length(ID_merge),1)*5];
gstn=length(ID);
% (2) read data from all sources

for g=1:gstn
    fprintf('%d--%d\n',g,gstn);
    sourceg=source(g);
    IDg=ID{g};
    Inpathg=Inpath2{sourceg};
    if sourceg==4 % mexico
        file0=[Inpathg,'/',IDg(6:end),'.mat'];
    else
        file0=[Inpathg,'/',IDg(3:end),'.mat'];
    end
    file1=[Outpathunify,'/',IDg,'.mat'];
    if ~exist(file1,'file')
        copyfile(file0,file1);
    end
end

save(FileAllgauge,'ID','LLE');
end

function [prcpg,tming,tmaxg,qfprcpg,qftming,qftmaxg]=f_readstn(Inpathg,IDg,sourceg,date)
if sourceg==4 % mexico
    file=[Inpathg,'/',IDg(6:end),'.mat'];
else
    file=[Inpathg,'/',IDg(3:end),'.mat'];
end

switch sourceg
    case 1
        [prcpg,tming,tmaxg,qfprcpg,qftming,qftmaxg]=f_ghcn_read(file,date);
    case 2
        
    case 3
        
    case 4
        
    case 5
        
end


end

function [dataout,flagout]=f_ghcn_read(file,date)
% data
dataout=nan*zeros(length(date),4);
dataout(:,1)=date;
load(file,'data','mqsflag');
[ind1,ind2]=ismember(data(:,1),date);
ind2(ind2==0)=[];
dataout(ind2,2:4)=data(ind1,2:4);

% flag
flagout=nan*zeros(length(date),3);
for v=1:3
    
end
end