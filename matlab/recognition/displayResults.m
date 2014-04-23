function [meanAccuracy] = displayResults(confusion)

meanAccuracy = sprintf('mean accuracy: %f', 100 * mean(diag(confusion))) ;
disp(meanAccuracy) ;
