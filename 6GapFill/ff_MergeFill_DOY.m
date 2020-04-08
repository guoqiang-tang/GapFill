function VarFill_merge=ff_MergeFill_DOY(OriWeight,datain)
indno=isnan(OriWeight);
OriWeight(indno)=[];
datain(:,indno)=[];
VarFill_merge=nan*zeros(size(datain,1),2);

if isempty(OriWeight)
    return;
end

maxnum=3;
if length(OriWeight)>maxnum
    [OriWeight,indsort]=sort(OriWeight,'descend');
    OriWeight(maxnum+1:end)=[];
    datain=datain(:,indsort(1:maxnum));
end

% merging according to Oriweight
OriWeight(OriWeight<0)=0;
if sum(OriWeight~=0)==0
    Weiall=ones(length(OriWeight),1)/length(OriWeight);
else
    Weiall=OriWeight.^2;
    Weiall=Weiall/sum(Weiall);
end

VarFill_mergeAll=nan*zeros(size(datain,1),size(datain,2));
for i=1:size(datain,2)
    VarFill_mergeAll(:,i)=datain(:,i)*Weiall(i);
end
VarFill_merge(:,1)=sum(VarFill_mergeAll,2);

VarFill_merge(:,2)=nanmedian(datain,2);
end