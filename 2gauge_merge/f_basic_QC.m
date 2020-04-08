function [ID_ghcn,ID_gsod,ID_mexico,ID_eccc,flag_ghcn,flag_gsod,flag_eccc,flag_mexico]=f_basic_QC(Inpath,outfile1,outfile2,BQC)
if exist(outfile2,'file')
   load(outfile2,'ID_ghcn','ID_gsod','ID_mexico','ID_eccc',...
       'flag_ghcn','flag_gsod','flag_eccc','flag_mexico',...
       'lle_ghcn','lle_gsod','lle_eccc','lle_mexico',...
       'flagvalue');
   return;
end

% gauge IDs and their flags
load(outfile1,'ID_ghcn','ID_mexico','ID_eccc','flag_ghcn','flag_eccc','flag_mexico');

dirg=dir(fullfile(Inpath{2},'*.mat')); %gsod
ID_gsod=cell(length(dirg),1);
fi=1;
for i=1:length(dirg)
    temp=dirg(i).name(1:end-4);
    if length(temp)==11
        ID_gsod{fi}=temp;
        fi=fi+1;
    end
end
ID_gsod(fi:end)=[];

flag_gsod=ones(length(ID_gsod),1);


% QC
[flag_ghcn,lle_ghcn]=f_BQC(Inpath{1},BQC,ID_ghcn,flag_ghcn);
[flag_gsod,lle_gsod]=f_BQC(Inpath{2},BQC,ID_gsod,flag_gsod);
[flag_eccc,lle_eccc]=f_BQC(Inpath{3},BQC,ID_eccc,flag_eccc);
[flag_mexico,lle_mexico]=f_BQC(Inpath{4},BQC,ID_mexico,flag_mexico);
flagvalue={'1-valid','0-fail ID check','-1: fail basic QC'};
save(outfile2,'ID_ghcn','ID_gsod','ID_mexico','ID_eccc',...
    'flag_ghcn','flag_gsod','flag_eccc','flag_mexico',...
    'lle_ghcn','lle_gsod','lle_eccc','lle_mexico',...
    'flagvalue');
end


function [flag,lleall]=f_BQC(Inpath,BQC,ID,flag)
lleall=nan*zeros(length(flag),3);
for i=1:length(ID)
    file=[Inpath,'/',ID{i},'.mat'];
    load(file,'lle');
    lleall(i,:)=lle;
    if flag(i)==1
        load(file,'data');
        if ~exist('data','var')
            flag(i)=-1;
            continue;
        end
        
        % valid ratio
        vnum=sum(~isnan(data(:,2:4)));
        if all(vnum<BQC.validsample)
            flag(i)=-1;
            clear data 
            continue;
        end
        % year lengths
        date=data(:,1);
        year=unique(floor(date/10000));
        yearlen=sum(ismember(year,BQC.yrange));
        if yearlen<BQC.ylen(1)||yearlen>BQC.ylen(2)
            flag(i)=-1;
            clear data 
            continue;
        end
    end
end
end