function [Msim,KGEtrain,KGEreco]=ff_ANN(Xtrain,Ytrain,Xcomplete,varvv)
% Xtrain: row: variables; col:samples
% Ytrain: [1,samples]
% Xreco: data for reconstruction period

%1. neural network training
rng(1,'twister');
normalize=false;
% network setting
NNset.hiddenlayer=[20,20]; NNset.learn='trainrp'; NNset.transfer='tansig';
NNset.goal=0.001; % default

ANN=fitnet(NNset.hiddenlayer,NNset.learn);
% ANN=newff(Xtrain,Ytrain,NNset.hiddenlayer,NNset.transfer,NNset.learn);
% view(net);
% parameter definition
ANN.trainParam.show=200;
ANN.trainParam.lr=0.05; 
ANN.trainParam.epochs=1000;
ANN.trainParam.goal=NNset.goal;
ANN.trainParam.mu=1e-3;
ANN.trainParam.mu_dec=0.1;
ANN.trainParam.mu_inc=10;
% ANN.trainParam.mu_max=1e10;
ANN.trainParam.showWindow = false; 
% net.trainParam.max_fail=20;

ANN.divideFcn='divideblock';
ANN.divideParam.trainRatio=0.5;
ANN.divideParam.valRatio=0.2;
ANN.divideParam.testRatio=0.3;

ANN.layers{1}.transferFcn=NNset.transfer;
ANN.layers{2}.transferFcn=NNset.transfer;
ANN.layers{3}.transferFcn='purelin';

if normalize
    % normalize data
    [Ytm,Yts,Ytrain]=ff_normalize(Ytrain);
    Xtm=zeros(size(Xtrain,1),1);
    Xts=zeros(size(Xtrain,1),1);
    for i=1:size(Xtrain,1)
        [Xtm(i),Xts(i),temp]=ff_normalize(Xtrain(i,:));
        Xtrain(i,:)=temp;
    end
end

[ANN,tr]=train(ANN,Xtrain,Ytrain);

% simulation
Mtrain=ANN(Xtrain);
if normalize
    Mtrain=ff_normalize_reverse(Mtrain,Ytm,Yts);
    Ytrain=ff_normalize_reverse(Ytrain,Ytm,Yts);
end
if strcmp(varvv,'prcp')
    Mtrain(Mtrain<0)=0;
end

%2. evaluate the performance of ANN in training period and testing period
KGEtrain=ff_KGE(Ytrain(tr.trainInd),Mtrain(tr.trainInd)); KGEtrain=KGEtrain(1);
% KGEvalid=ff_KGE(Ytrain(tr.valInd),Mtrain(tr.valInd)); KGEvalid=KGEvalid(1);
KGEreco=ff_KGE(Ytrain(tr.testInd),Mtrain(tr.testInd)); KGEreco=KGEreco(1);  % this is only test KGE. refer to as KGEreco to be consistent with outputs

%3. simulate the result in reconstruction period
Msim=ANN(Xcomplete);
if normalize
    Msim=ff_normalize_reverse(Msim,Ytm,Yts);
end
if strcmp(varvv,'prcp')
    Msim(Msim<0)=0;
end
end

