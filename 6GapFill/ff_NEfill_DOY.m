function VarFill_NE=ff_NEfill_DOY(data_stn_nedd,CDFstnggd,CDFvstnggd,CDFstn_ne,CDFvstn_ne,CCstn_ne,DISTstn_ne)
%1 Fill the gap using the NE station with highest Spearman CC for each doy
%2 Fill the gap using weighted mean according to Spearman CC
%3 Fill the gap using weighted mean according to distance
%4 median of the above three
CCstn_ne(CCstn_ne<0|isnan(CCstn_ne))=0; % for weight calculation
if sum(CCstn_ne~=0)==0
    CCstn_ne(:)=1;
end

DISTstn_ne(DISTstn_ne==0)=0.001;

weico1=2; % weight for mean
weico2=-2;

nday=size(data_stn_nedd,1);
VarFill_NE=nan*zeros(nday,4);
if isempty(data_stn_nedd)
    return;
end

for dd=1:nday
    ValueNe=data_stn_nedd(dd,:);
    % for each NAN value in IDtar, if there is no data from nearest gauges,
    % it is abandoned
    Neind=find(~isnan(ValueNe));
    if isempty(Neind); continue; end
    
    CDFstn_ned=CDFstn_ne(Neind);
    CDFvstn_ned=CDFvstn_ne(Neind);
    valuene=ValueNe(Neind);
    
    % Fill NE1: using the one with highest CC
    fillne1=ff_cdfMatch(CDFstnggd,CDFvstnggd,CDFstn_ned{1},CDFvstn_ned{1},valuene(1));
    VarFill_NE(dd,1)=fillne1;
    
    % Fill NE2: using weighted mean of all neighboring stations based (at
    % most 4 stations)
    % on CC
    Neindlen=length(Neind);
%     maxnum=10;
    if Neindlen>1
%         if Neindlen>maxnum
%            Neind(maxnum+1:end)=[];  Neindlen=maxnum;
%         end
        fillallne=nan*zeros(Neindlen,1);
        fillallne(1)=fillne1;
        for i=2:Neindlen
            fillallne(i)=ff_cdfMatch(CDFstnggd,CDFvstnggd,CDFstn_ned{i},CDFvstn_ned{i},valuene(i));
        end
        CCstn_ned=CCstn_ne(Neind);
        weight=CCstn_ned.^weico1;
        weight=weight/sum(weight);
        fillne2=sum(fillallne(:).*weight(:));
        VarFill_NE(dd,2)=fillne2;
    else
        VarFill_NE(dd,2)=fillne1;
    end
    
    % Fill NE3: using weighted mean of all neighboring stations based
    % on distance
    if Neindlen>1
        DISTstn_ned=DISTstn_ne(Neind);
        weight=DISTstn_ned.^weico2;
        weight=weight/sum(weight);
        fillne3=sum(fillallne(:).*weight(:));
        VarFill_NE(dd,3)=fillne3;
    else
        VarFill_NE(dd,3)=fillne1;
    end
    
    % Fill NE4: the median of all neighboring stations
    if Neindlen>1
        VarFill_NE(dd,4)=nanmedian(fillallne);
    else
        VarFill_NE(dd,4)=fillne1;
    end
    
end
end
