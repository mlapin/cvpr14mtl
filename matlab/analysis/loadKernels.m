function [Ytrn,Ktrn,Ytst,Ktst] = loadKernels(split,ntrain,lcs) %#ok<STOUT>
% Loads precomputed kernels

kernelsDir = 'data/kernels';

fprintf('Loading precomputed kernels...\n');

if lcs
  load(fullfile(kernelsDir, ...
    sprintf('Train-S%02d-N%02d-SIFT-LCS-PN-L2-Khell.mat', split, ntrain)));
  load(fullfile(kernelsDir, ...
    sprintf('Test-S%02d-N%02d-SIFT-LCS-PN-L2-Khell.mat', split, ntrain)));
else
  load(fullfile(kernelsDir, ...
    sprintf('Train-S%02d-N%02d-SIFT-Khell.mat', split, ntrain)));
  load(fullfile(kernelsDir, ...
    sprintf('Test-S%02d-N%02d-SIFT-Khell.mat', split, ntrain)));
end

fprintf('Done.\n');
