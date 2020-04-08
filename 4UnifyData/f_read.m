function [datai,qfrawi,qfi,mfi]=f_read(filei,sourcei,date)
datai=nan*zeros(length(date),3);
qfrawi=nan*zeros(length(date),3);
qfi=nan*zeros(length(date),3);
mfi=zeros(length(date),1); % measurement flag

% data
load(filei,'data');
date0=data(:,1);
[ind1,ind2]=ismember(date0,date);
ind2(ind2==0)=[];
datai(ind2,1:3)=data(ind1,2:4);

mfi(ind1)=1; % this is from measurement
% quality flags in our framework
load(filei,'Qflag_prcp1','Qflag_prcp2','Qflag_tmax','Qflag_tmin');

% if ~strcmp(sourcei,'GS')
%     Qflag_prcp2(Qflag_prcp2==34)=0;
% end

tempind=Qflag_prcp1>0;
Qflag_prcp1(~tempind)=Qflag_prcp2(~tempind); 
qfi(ind2,1)=Qflag_prcp1(ind1);
qfi(ind2,2)=Qflag_tmin(ind1);
qfi(ind2,3)=Qflag_tmax(ind1);

% quality flags from raw data
switch sourcei
    case 'GH'  % GHCN-D
        qfraw=f_read_ghcn(filei);
%     case 'GS'  % GSOD
%         qfraw=f_read_gsod(filei);
%     case 'EC' % ECCC
%         qfraw=f_read_eccc(filei);
%     case 'ME' % Mexico
%         qfraw=nan*zeros(length(date0),3);
    case {'GS','EC','ME','MR'} % Merge from various sources
        qfraw=nan*zeros(length(date0),3);
end
qfrawi(ind2,1:3)=qfraw(ind1,1:3);
end


function qfrawi=f_read_ghcn(filei)
load(filei,'mqsflag');
qfrawi=nan*zeros(size(mqsflag{1})); 
for i=1:3
    qfrawi(:,i)=int16(mqsflag{i}(:,2));
end
qfrawi(qfrawi==32)=0; % space is used in ghcd-d for good stations. here we use 0.
end
