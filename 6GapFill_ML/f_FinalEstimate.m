function ANNscd=f_FinalEstimate(edata,ekge)
nday=size(edata,1);
ANNscd=nan*zeros(nday,2); % col: observation period and reconstruction period
for i=1:2 % two period loop
    ekgei=ekge(:,i);
    [~,indexi]=sort(ekgei,'descend');
    for j=1:size(edata,2)
        indj=~isnan(edata(:,indexi(j))) & isnan(ANNscd(:,i));
        ANNscd(indj,i)=edata(indj,indexi(j));
        if sum(isnan(ANNscd(:,i)))==0; break; end
    end
end
end