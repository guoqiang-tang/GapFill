function [p, fval,exitflag,output]=f_MADL(x,y)
% Multiple regression using the least absolute deviation criterion (MLAD)
% x: row-samples; col-number of stations
% y: row-samples

sigy = ones(size(y));

% seed the algorithm with the least-squares solution
xx=[ones(size(x,1),1),x];
p0 = regress(y,xx);

global X Y SIGY;
X = x;
Y = y;
SIGY = sigy;
s = sumdev(p0);
[p1,fval,exitflag,output] = fminsearch(@sumdev,p0);
p = p1;
end

function s = sumdev(p)
% calculate the absolute values of the residuals
global X Y SIGY;
n = size(X,1);
m = size(X,2);

fx = zeros(n,1);
fx=fx+p(1);
for j=1:m
    fx=fx+p(j+1)*X(:,j);
end
s=sum(abs(Y-fx));

% s = 0;
% for i = 1:n
%     fx = 0;
%     fx = fx + p(1);
%     for j = 1:m
%         fx = fx + p(j+1)*X(i,j);
%     end
%     s = s + abs(Y(i) - fx)/SIGY(i);
% end
end