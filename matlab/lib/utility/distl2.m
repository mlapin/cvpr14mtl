function [D] = distl2(X,Y)
%DISTL2 Pairwise squared L2 (Euclidean) distance.
% [D]=DISTL2(X,Y) Computes squared L2 (Euclidean) distance 
% between all pairs of d-dimensional points in X and Y.
%
% Inputs:
%   X   - a d-by-m matrix of m d-dimensional points;
%   Y   - a d-by-n matrix of n d-dimensional points.
%
% Outputs:
%   D   - a m-by-n matrix of pairwise distances.

if nargin < 2
    D = full(X'*X);
    d = diag(D);
    D = bsxfun(@minus, d, 2*D);
    D = bsxfun(@plus, d', D);
    D = max(D, 0);
else
    D = full(X'*Y);
    D = bsxfun(@minus, sum(Y.^2,1), 2*D);
    D = bsxfun(@plus, sum(X.^2,1)', D);
    D = max(D, 0);
end
