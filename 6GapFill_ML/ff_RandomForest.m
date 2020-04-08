function [Msim,KGEtrain,KGEreco]=ff_RandomForest(Xtrain,Ytrain,Xcomplete,varvv)
% Xtrain: [samples,variables]
rng(1,'twister');
normalize=false;
treenum=50;

% only use 70% for training and 30% for testing
tnum=floor(length(Ytrain)*0.7);
Xtest=Xtrain(tnum+1:end,:);
Ytest=Ytrain(tnum+1:end);
Xtrain(tnum+1:end,:)=[];
Ytrain(tnum+1:end)=[];

if normalize
    % normalize data
    [Ytm,Yts,Ytrain]=ff_normalize(Ytrain);
    Xtm=zeros(size(Xtrain,2),1);
    Xts=zeros(size(Xtrain,2),1);
    for i=1:size(Xtrain,2)
        [Xtm(i),Xts(i),temp]=ff_normalize(Xtrain(:,i));
        Xtrain(:,i)=temp;
        Xtest(:,i)=(Xtest(:,i)-Xtm(i))/Xts(i);
        Xcomplete(:,i)=(Xcomplete(:,i)-Xtm(i))/Xts(i);
    end
end

RF= TreeBagger(treenum,Xtrain,Ytrain,'Method','regression','NumPredictorsToSample','all','MinLeafSize',5);

% simulation and reverse normalization
Mtrain=RF.predict(Xtrain);
Mtest=RF.predict(Xtest);
Msim=RF.predict(Xcomplete);
indnan=sum(isnan(Xcomplete),2)>0;
Msim(indnan)=nan;

if normalize
    Mtrain=ff_normalize_reverse(Mtrain,Ytm,Yts);
    Mtest=ff_normalize_reverse(Mtest,Ytm,Yts);
    Msim=ff_normalize_reverse(Msim,Ytm,Yts);
    Ytrain=ff_normalize_reverse(Ytrain,Ytm,Yts);
end

if strcmp(varvv,'prcp')
    Mtrain(Mtrain<0)=0;
    Mtest(Mtest<0)=0;
    Msim(Msim<0)=0;
end

KGEtrain=ff_KGE(Ytrain,Mtrain); KGEtrain=KGEtrain(1);
KGEreco=ff_KGE(Ytest,Mtest); KGEreco=KGEreco(1);  % this is only test KGE. refer to as KGEreco to be consistent with outputs
end

