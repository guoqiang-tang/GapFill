function VarFill_INTdd=ff_INTfill_DOY(data_stn_nedd,CCstn_ne,DISTstn_ne,xdata,ydata,flag)
ndaydd=size(data_stn_nedd,1);
VarFill_INTdd=nan*zeros(ndaydd,4);
%1. Multiple regression using the least absolute deviation criterion (MLAD)
% exclude days that ydata does not have valid data
xdataMLAD=xdata; ydataMLAD=ydata;

indin=~isnan(ydataMLAD);
ydataMLAD=ydataMLAD(indin);
xdataMLAD=xdataMLAD(indin,:);
if isempty(xdataMLAD)
   return; 
end

% for the doy, exclude neighboring stations that CC is low
indno=CCstn_ne<0.35;
xdataMLAD(:,indno)=[];
data_stn_nedd(:,indno)=[];
CCstn_ne(indno)=[];
DISTstn_ne(indno)=[];

FillInt1=nan*zeros(ndaydd,1);
if ~isempty(xdataMLAD)
    % fod each day, find the non NaN index of data_stn_nedd
    NEindex=zeros(ndaydd,4); % maximum is 4 station
    for i=1:ndaydd
       indi=find(~isnan(data_stn_nedd(i,:)));
       leni=min([4,length(indi)]);
       NEindex(i,1:leni)=indi(1:leni);
    end
    NEindexu=unique(NEindex,'rows');
    
    for i=1:size(NEindexu,1)
        % start MADL, many combinations of input neighboring stations according to
        % the availability of data for each day
        NEindexui=NEindexu(i,:);
        induse=NEindexui>0;
        if sum(induse)==0; continue; end
        indexdd=ismember(NEindex,NEindexui,'rows');
        NEindexui=NEindexui(induse);
        FillInt1i=zeros(sum(indexdd),1);
        
        % training stations for day corresponding to indexdd
        
        xdataMLADi=xdataMLAD(:,NEindexui);
        ydataMLADi=ydataMLAD;
        
        % exclude days that some neighboring stations in xdata have NaN
        [tempind,~]=find(isnan(xdataMLADi));
        xdataMLADi(tempind,:)=[];ydataMLADi(tempind)=[];
        if isempty(xdataMLADi); continue; end
        
        try
            pi=f_MADL(xdataMLADi,ydataMLADi);
            % p=regress(ydata,[ones(size(xdata,1),1),xdata]);
        catch
           continue; 
        end

        FillInt1i=FillInt1i+pi(1);
        xdataInput=data_stn_nedd(indexdd,NEindexui);
        for j=1:size(xdataInput,2)
            FillInt1i=FillInt1i+xdataInput(:,j)*pi(j+1);
        end
        
        FillInt1(indexdd)=FillInt1i;
    end
end
VarFill_INTdd(:,1)=FillInt1;

if flag==0
    return; % don't do normal ration and IDW filling
end
%2. Normal ratio method
%3. IDW
% calculate weight of NR
numsam=zeros(length(CCstn_ne),1);
for i=1:length(CCstn_ne)
    numsam(i)=sum(~isnan(xdata(:,i))&~isnan(ydata));
end
weightNR=CCstn_ne.^2 .* (numsam-2) ./ (1 - CCstn_ne.^2); % CCstn_ne has been sorted from high to low

% calculate weight of IDW
DISTstn_ne(DISTstn_ne==0)=0.01;
weightIDW=DISTstn_ne.^-2;

FillInt2=nan*zeros(ndaydd,1);
FillInt3=nan*zeros(ndaydd,1);
for i=1:ndaydd
    valuei=data_stn_nedd(i,:)';
    indexi=find(~isnan(valuei));
    if ~isempty(indexi)
        % NR interpolation
        indexi2=indexi;
        if length(indexi2)>4
            indexi2(5:end)=[];
        end
        FillInt2(i)=sum(valuei(indexi2) .* weightNR(indexi2)) / sum(weightNR(indexi2));
        
        % IDW interpolation
        weightIDWi=weightIDW(indexi);
        valuei=valuei(indexi);
        if length(indexi)>4
            [weightIDWi,indsort]=sort(weightIDWi,'descend');
            weightIDWi(5:end)=[];
            indsort(5:end)=[];
            valuei=valuei(indsort);
        end
        FillInt3(i)=sum(valuei .* weightIDWi) / sum(weightIDWi);
    end
    
end
VarFill_INTdd(:,2)=FillInt2;
VarFill_INTdd(:,3)=FillInt3;

%4. The median of the three
VarFill_INTdd(:,4)=nanmedian(VarFill_INTdd(:,1:3),2);
end