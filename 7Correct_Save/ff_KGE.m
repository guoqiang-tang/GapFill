function KGEgroup=ff_KGE(Obs,Pre)
% reference: Runoff conditions in the upper Danube basin under an ensemble of climate change scenarios
% https://www-sciencedirect-com.cyber.usask.ca/science/article/pii/S0022169412000431
ind=isnan(Obs)|isnan(Pre);
Pre(ind)=[]; Obs(ind)=[];


pre_mean = nanmean(Pre);
obs_mean = nanmean(Obs);
r = nansum((Pre - pre_mean) .* (Obs - obs_mean)) / sqrt(nansum((Pre - pre_mean).^2).*nansum((Obs - obs_mean).^2));
gamma = (std(Pre)/pre_mean) / (std(Obs) / obs_mean);
beta = nanmean(Pre)/nanmean(Obs);
KGE = 1 - sqrt((r - 1)^2 + (gamma - 1)^2 + (beta - 1)^2);
KGEgroup = [KGE,r,gamma,beta];
end