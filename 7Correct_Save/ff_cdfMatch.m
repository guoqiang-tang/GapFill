function value1=ff_cdfMatch(cdf1,cdfv1,cdf2,cdfv2,value2)
if isempty(cdf1)||isempty(cdf2)
   value1=nan; return; 
end

cdf1=cdf1(:);cdf2=cdf2(:);

if isnan(value2)
    value1=nan;
elseif value2<=cdfv2(1) % prcp: 0 mm, tmin/tmax: lowest temperature
    value1=cdfv1(1);
elseif value2>=cdfv2(end)
    value1=cdfv1(end);
else % interpolation is now reasonable
    cdfvalue=interp1(cdfv2,cdf2,value2,'linear');
    if cdfvalue<=cdf1(1)
        value1=cdfv1(1);
    elseif cdfvalue>=cdf1(end)
        value1=cdfv1(end);
    else
        value1=interp1(cdf1,cdfv1,cdfvalue,'linear');
    end
end

end