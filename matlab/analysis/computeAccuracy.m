function [accuracy] = computeAccuracy(scores, labels, topK)
%COMPUTEACCURACY Compute top-1, top-2, ..., top-K accuracies
%
% Inputs:
%   scores    - C-by-N matrix of classifier scores,
%               where C is the number of classes and N is the sample size
%   labels    - 1-by-N vector of ground truth labels,
%               where each label is in 1:C
%   topK      - 1-by-M vector of the required K's in the top-K measure
%               (topK = 1:C by default)
%
% Outputs:
%   accuracy  - 1-by-M vector of top-K accuracies
%

narginchk(2, 3);
if nargin < 3
  topK = 1:size(scores, 1);
end

[~, IX] = sort(scores, 1, 'descend');

accuracy = nan(size(topK));
for K = topK
  correct = sign(sum(bsxfun(@eq, IX(1:K, :), labels), 1));
  accuracy(K) = sum(correct) / size(scores, 2);
end
