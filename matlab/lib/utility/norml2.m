function [A]=norml2(A)
%NORML2 L2-Normalize a matrix (columnwise).

assert(isfloat(A), 'Input matrix A must be either single or double.');

d = sqrt(sum(A.^2, 1));
d(d==0) = 1;
A = bsxfun(@rdivide, A, d);

% Alternative (only double):
% A = A * spdiags(spfun(@(x) 1./x, d'), 0, size(A,2), size(A,2));
