function [Ytrn,Ktrn,Ytst,Ktst] = loadKernelsXiao10(split,ntrain)
% Loads precomputed kernels

fprintf('Loading precomputed kernels from Xiao et al.\n');
assert(split == 1, 'Xiao10 kernels are only available for split 1.');

kernelsDir = 'data/kernels';
kernelsXiaoDir = 'data/kernels_xiao10';
kernelsSuffix = '_all__split_01__combine__weighted_F__bow_F__normalize_F__';

% Xiao kernels are only available for Ntrain = 50 (full subset)
Ntmp = 50;
load(fullfile(kernelsDir, sprintf('meta-S%02d-N%02d-SIFT.mat', split, Ntmp)), 'imdb');
Ytrn = double(imdb.images.class(imdb.images.set ~= 3));
Ytst = double(imdb.images.class(imdb.images.set == 3));

Ktrn = load(fullfile(kernelsXiaoDir, sprintf('Train%s.mat', kernelsSuffix)));
Ktrn = Ktrn.K;
Ktrn = validateKernel(Ktrn, 'train');

Ktst = load(fullfile(kernelsXiaoDir, sprintf('Test%s.mat', kernelsSuffix)));
Ktst = Ktst.K_test;
Ktst = validateKernel(Ktst, 'test');

% Subsample the corresponding examples if a smaller subset is required
if ntrain ~= Ntmp
  imdbtmp = load(fullfile(kernelsDir, ...
    sprintf('meta-S%02d-N%02d-SIFT.mat', split, ntrain)), 'imdb');
  imdbtmp = imdbtmp.imdb;
  ix = imdb.images.set ~= 3;
  ix = ismember(imdb.images.name(ix), imdbtmp.images.name);
  Ytrn = Ytrn(ix);
  Ktrn = Ktrn(ix,ix);
  Ktst = Ktst(ix,:);
end

fprintf('Done.\n');

end

function [K] = validateKernel(K, kernelName)

% There are NaN's in the kernels provided by Xiao et al., see
%   http://vision.princeton.edu/projects/2010/SUN/source_code/SUN_source_code_v2.tar
%   SUN_source_code_v2/code/scene_sun/kernel.m
% They replaced the NaN's with 10^20 which, however, leads to
% poor condition number. Instead, we suggest to replace NaN's with 0.
replaceWith = 0;

ix = ~(isfinite(K) & isreal(K));
if any(ix(:))
  fprintf('Found %d bad values in the %s kernel; replaced with %g.\n', ...
    sum(ix(:)), kernelName, replaceWith);
  K(ix) = replaceWith;
end

end