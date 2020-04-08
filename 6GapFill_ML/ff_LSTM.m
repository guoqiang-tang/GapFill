function [Msim,KGEtrain,KGEreco]=ff_LSTM(xdatai,ydata,varvv)
nstep=6; % number of days that are used for lstm model
[xin,yin,xall,flagall]=ff_LSTMdata(xdatai,ydata,nstep);
rng(1,'twister');

% only use 70% for training and 30% for testing
tnum=floor(length(yin)*0.7);
Xtrain=xin(1:tnum);
Ytrain=yin(1:tnum);
Xtest=xin(tnum+1:end);
Ytest=yin(tnum+1:end);

% lstm model
inputSize = size(xdatai,2);
numResponses = 1;
numHiddenUnits = 80;
layers = [ ...
    sequenceInputLayer(inputSize)
    lstmLayer(numHiddenUnits,'OutputMode','last')
    fullyConnectedLayer(numResponses)
    regressionLayer];

maxEpochs = 50;
miniBatchSize = 1000;
% opts = trainingOptions('rmsprop', ...  
%     'ExecutionEnvironment','cpu',...
%     'MaxEpochs',maxEpochs, ...
%     'MiniBatchSize',miniBatchSize, ...
%     'InitialLearnRate',0.05, ...
%     'LearnRateSchedule','piecewise', ...
%     'LearnRateDropPeriod',50, ...
%     'LearnRateDropFactor',0.2, ...
%     'Verbose',0);
opts = trainingOptions('adam', ...  
    'ExecutionEnvironment','cpu',...
    'MaxEpochs',maxEpochs, ...
    'MiniBatchSize',miniBatchSize, ...
    'GradientThreshold',1, ...
    'InitialLearnRate',0.05, ...
    'LearnRateSchedule','piecewise', ...
    'LearnRateDropPeriod',50, ...
    'LearnRateDropFactor',0.2, ...
    'Verbose',0);

net = trainNetwork(Xtrain,Ytrain,layers,opts);

net = resetState(net);
[net, Mtrain] = predictAndUpdateState(net,Xtrain);
net = resetState(net);
[net, Mtest] = predictAndUpdateState(net,Xtest);
net = resetState(net);
[net, Msim0] = predictAndUpdateState(net,xall);

if strcmp(varvv,'prcp')
    Mtrain(Mtrain<0)=0;
    Mtest(Mtest<0)=0;
    Msim0(Msim0<0)=0;
end
Msim=nan*zeros(size(ydata));
Msim(flagall==1)=Msim0;

KGEtrain=ff_KGE(Ytrain,Mtrain); KGEtrain=KGEtrain(1);
KGEreco=ff_KGE(Ytest,Mtest); KGEreco=KGEreco(1);  % this is only test KGE. refer to as KGEreco to be consistent with outputs
end

function [xin,yin,xall,flagall]=ff_LSTMdata(xdatai,ydata,nstep)
xall=cell(length(ydata),1);
flagall=zeros(length(ydata),1);
for i=nstep:length(ydata)
    xi=xdatai(i-nstep+1:i,:);
    if sum(isnan(xi(:)))>0; continue; end
    xall{i}=xi';
    flagall(i)=1;
end

flagy=~isnan(ydata);
indexin=flagy==1&flagall==1;
xin=xall(indexin);
yin=ydata(indexin);
xall=xall(flagall==1);
end