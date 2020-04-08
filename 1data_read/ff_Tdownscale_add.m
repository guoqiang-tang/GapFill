function dout=ff_Tdownscale_add(din,Tadd)
dout=nan*ones(size(din));
for i=1:size(din,3)
    temp=din(:,:,i);
    dout(:,:,i)=temp+Tadd;
end
end