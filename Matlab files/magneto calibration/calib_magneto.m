function [U,c] = calib_magneto(Mag)
% performs magnetometer calibration from a set of data
% using Merayo technique with a non iterative algoritm
% J.Merayo et al. "Scalar calibration of vector magnemoters"
% Meas. Sci. Technol. 11 (2000) 120-132.
%
%   X      : a Nx3 (or 3xN) data matrix
%              each row (columns) contains x, y, z measurements
%              N must be such that the data set describes
%              as completely as possible the 3D space
%              In any case N > 10
%
%    The calibration tries to find the best 3D ellipsoid that fits the data set
%    and returns the parameters of this ellipsoid
%
%    U     :  shape ellipsoid parameter, (3x3) upper triangular matrix
%    c      : ellipsoid center, (3x1) vector
%
%    Ellipsoid equation : (v-c)'*(U'*U)(v-c) = 1
%    with v a rough triaxes magnetometer  measurement
%
%    calibrated measurement w = U*(v-c)
%
%   author : Alain Barraud, Suzanne Lesecq 2008
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[N,n] = size(Mag);
% write  the ellipsoid equation as D*p=0
% the best parameter is the solution of min||D*p|| with ||p||=1;
% form D matrix from X measurements
x = Mag(:,1);
y = Mag(:,2);
z = Mag(:,3);

D = [x.^2, y.^2, z.^2, x.*y, x.*z, y.*z, x, y, z, ones(N,1)];
D=triu(qr(D));%avoids to compute the svd of a large matrix
[U,S,V] = svd(D,0);%because usually N may be very large
p = V(:,end);
if p(1)<0
    p =-p;
end

% the following matrix A(p) must be positive definite
% The optimization done by svd does not include such a constraint
% With "good" data the constraint is allways satisfied
% With too poor data A may fail to be positive definite
% In this case the calibration fails

U = [p(1) p(4)/2 p(5)/2;
    p(4)/2 p(2) p(6)/2;
    p(5)/2 p(6)/2 p(3)];

% performs Cholesky factoristation
U(1,1:n) = U(1,1:n)/sqrt(U(1,1));
U(2:n,1) = 0;
for j=2:n
    U(j,j:n) = U(j,j:n) - U(1:j-1,j)'*U(1:j-1,j:n);
    if U(j,j)<=0,break;end%A is not positive definite
    U(j,j:n) = U(j,j:n)/sqrt(U(j,j));
    U(j+1:n,j) = 0;
end
b = [p(7);p(8);p(9)]/2;

% solves U'*x=b
v=zeros(1,n);
v(1) = b(1)/U(1,1);
for k=2:n
    v(k) = (b(k)-v(1:k-1)*U(1:k-1,k))/U(k,k);
end

d = p(10);

% solves U*x=b
c(n) = v(n)/U(n,n);
for k=n-1:-1:1
    c(k) = (v(k)-U(k,k+1:n)*c(k+1:n)')/U(k,k);
end

U = U/sqrt(v*v'-d);%shape ellipsoid parameter


