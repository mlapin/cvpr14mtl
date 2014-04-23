function [A]=norml1(A)
%NORML1 L1-Normalize a matrix (columnwise).

assert(isfloat(A), 'Input matrix must be either single or double.');

d = sum(abs(A), 1);
d(d==0) = 1;
A = bsxfun(@rdivide, A, d);

% Alternative (only double):
% A = A * spdiags(spfun(@(x) 1./x, d'), 0, size(A,2), size(A,2));
