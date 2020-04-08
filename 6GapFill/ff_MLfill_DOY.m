function VarFill_MLdd=ff_MLfill_DOY(xdataMLAD,ydataMLAD,xdataInput)
ndaydd=size(xdataInput,1);
VarFill_MLdd=nan*zeros(ndaydd,1);

NNset.hiddenlayer=[20,20];
NNset.learn='trainlm';
NNset.goal=0.01; % default
dataout=ff_ANN(xdataMLAD',ydataMLAD',xdataInput',NNset,'True');
VarFill_MLdd(:,1)=dataout;

end

function dataout=ff_ANN(xdata,ydata,datain,NNset,normalize)
% Xtrain: [samples,variables]
rng(1,'twister');
ANN=fitnet(NNset.hiddenlayer,NNset.learn); %设置网络,建立相应的BP网络,trainlm效果好，优于traingdx，traingd行不通，newff是旧用法
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
ANN.trainParam.mu_max=1e10;
% net.trainParam.max_fail=20;

ANN.divideFcn='divideint';
ANN.divideParam.trainRatio=0.6;
ANN.divideParam.valRatio=0.2;
ANN.divideParam.testRatio=0.2;

if normalize
    % normalize data
    [Ytm,Yts,ydata]=f_normalize(ydata);
    Xtm=zeros(size(xdata,1),1);
    for i=1:size(xdata,1)
        [Xtm(i),Xts(i),temp]=f_normalize(xdata(i,:));
        xdata(i,:)=temp;
    end
end

[ANN,tr]=train(ANN,xdata,ydata);

% simulation
dataout=ANN(datain);
if normalize
    dataout=f_normalize_reverse(dataout,Ytm,Yts);
end
dataout(dataout<0)=0;
end

function data2=f_normalize_reverse(data,m,s)
data2=data*s+m;
data2(data2<0)=0;
end

function [m,s,data2]=f_normalize(data)
m=mean(data);
s=std(data);
data2=(data-m)/s;
end