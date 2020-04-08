function dint=ff_interpolate(var,XX0,YY0,XX1,YY1,imethod)
day=size(var,3);
dint=nan*zeros(size(XX1,1),size(XX1,2),day);
for dd=1:day
    temp=interp2(XX0,YY0,var(:,:,dd),XX1,YY1,imethod); % from orignal resolution to original resolution
    dint(:,:,dd)=temp;
end

end
