function [D] = distl1(X,Y)
%DISTL1 Pairwise L1 distance.
% [D]=DISTL1(X,Y) Computes L1 distance 
% between all pairs of p-dimensional points in X and Y.
%
% Inputs:
%   X   - a p-by-m matrix of m p-dimensional points;
%   Y   - a p-by-n matrix of n p-dimensional points.
%
% Outputs:
%   D   - a m-by-n matrix of pairwise distances.

D = zeros(size(X,2), size(Y,2));
for i = 1:size(X,2)
    D(i,:) = sum(abs(bsxfun(@minus, Y, X(:,i))));
end
