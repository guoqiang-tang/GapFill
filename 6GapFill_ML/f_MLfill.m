function [ANNscd,RFscd,LSTMscd]=f_MLfill(xdata,ydata,xcomb,varvv,LSTMflag)
% scd estimate
numcomb=size(xcomb,1);
nday=length(ydata);
ANNdata=nan*zeros(nday,numcomb); % col: combinations
ANNkge=nan*zeros(numcomb,2); % train validation test kge
RFdata=nan*zeros(nday,numcomb); % col: combinations
RFkge=nan*zeros(numcomb,2); % train validation test kge
LSTMdata=nan*zeros(nday,numcomb); % col: combinations
LSTMkge=nan*zeros(numcomb,2); % train validation test kge

for i=1:numcomb % combination loop
    combi=xcomb(i,:); combi(isnan(combi))=[];
    if isempty(combi); continue; end
    xdatai=xdata(:,combi);
    inputi=[xdatai,ydata];
    [indin,~]=find(isnan(inputi));
    inputi(indin,:)=[];
    
% % %     % ANN estimate
% % %     try
% % %         [ANNdata(:,i),ANNkge(i,1),ANNkge(i,2)]=ff_ANN(inputi(:,1:end-1)',inputi(:,end)',xdatai',varvv);
% % %     catch
% % %     end
% % %     % Random Forest estimate
% % %     try
% % %         [RFdata(:,i),RFkge(i,1),RFkge(i,2)]=ff_RandomForest(inputi(:,1:end-1),inputi(:,end),xdatai,varvv);
% % %     catch
% % %     end
    
    % LSTM
    if LSTMflag==1
        try
            [LSTMdata(:,i),LSTMkge(i,1),LSTMkge(i,2)]=ff_LSTM(xdatai,ydata,varvv);
        catch
        end
    end
end

% generate final estimate
% % % ANNscd=f_FinalEstimate(ANNdata,ANNkge);
% % % RFscd=f_FinalEstimate(RFdata,RFkge);
ANNscd=[];
RFscd=[];
if LSTMflag==1
LSTMscd=f_FinalEstimate(LSTMdata,LSTMkge);
else
LSTMscd=nan*RFscd;
end
end
