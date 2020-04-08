function GF=f_BasicControl(Inpath,ID,LLE,BC)
GF=ones(length(ID),1);
% (1) check lat lon
GF(isnan(LLE(:,1))|isnan(LLE(:,2))|isnan(LLE(:,3)),:)=0;
% (2) data length and valid number ratio chech
ylen=BC.ylen;
yrange=BC.yrange;
validratio=BC.validratio;
for i=1:length(GF)
    if GF(i)==1
        GF(i)=0; % initialize
        Infile=[Inpath,'/',ID{i},'.mat'];
        if ~exist(Infile,'file')
           continue; 
        end
        
        load(Infile,'data');
        date=data(:,1);
        data(date<yrange(1)*10000|date>(yrange(2)+1)*10000,:)=[];
        date=data(:,1);
        
        if length(date)>ylen*365 % we don't know whether the year is complete, so we use days to determine
            flagvv=0;
            for vv=1:size(data,2)-1
                vvd=data(:,vv+1);
                if ~isnan(validratio(vv))
                    vratioi=sum(~isnan(vvd))/length(vvd);
                    if vratioi>=validratio(vv)
                        flagvv=1;
                        break;
                    end
                end
            end
            
            if flagvv==1
                GF(i)=1;
            end
        end
    end
end

if mod(i,100)==0
    fprintf('Basic control %d--%d\n',i,length(GF));
end
end