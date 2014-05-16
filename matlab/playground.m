%
% Playground: train and test with precomputed kernels
%
% Notes:
% 1) Please ensure that you have downloaded the precomputed kernels.
%    To download, run in shell: make playkernels
%
% 2) Sometimes a solver would exit with the status 'NumericalProblems'.
%    This happens when the problem has poor condition number.
%    To exit when something is starting to go wrong is the best
%    the current implementation can do given a limited floating-point
%    machine precision. In any case, check the reported
%    absolute_gap and relative_gap.
%
% 3) loadKernelsXiao10 will print two messages about bad values in kernels.
%    This is a known problem, see analysis/loadKernelsXiao10.m for details.
%
% 4) The accuracy numbers computed by this script will be different
%    from the ones reported in the paper since this is one split only.
%

myinit;
ccc;

% Uncomment to save all output to a log file
% diary(sprintf('diary_%s.txt', datestr(now, 'yyyy-mm-dd_HH-MM-SS_FFF')));
% diary on;

% C range for STL-SDCA (SVM) model selection via 2-fold cross-validation
% (MTL was tuned on the first split - see analysis/resSplitOneBest.m)
svmCs = 10.^(-3:3);

% Default setting - if changed, other kernels need to be downloaded.
% To download all kernels computed for this paper (not the Xiao ones),
% run in shell: make allkernels
split = 1;
ntrain = 5;
lcs = true;

% MTL-SDCA: Selected C1 / C2
%    5: 1e-2 / 1e+3
%   10: 1e-2 / 1e+3
%   20: 1e-3 / 1e+3
%   50: 1e-3 / 1e+5
mtlC1 = 1e-2;
mtlC2 = 1e+3;

t = tic;
[Ytrn,Ktrn,Ytst,Ktst] = loadKernels(split,ntrain,lcs);
[cvC,cvAcc,A,info,scores,acc,timing] = playSvmModelSelectionTrainTest(Ytrn,Ktrn,Ytst,Ktst,svmCs);
[mtlA,mtlKw,mtlinfo,mtlscores,mtlacc,mtltiming]=playMtlTrainTest(Ytrn,Ktrn,Ytst,Ktst,mtlC1,mtlC2,A);

% Better performing values for the Xiao kernels
% (no proper model selection, sorry)
mtlC1 = 1e-1;
mtlC2 = 1e-1;

[Ytrn,Ktrn,Ytst,Ktst] = loadKernelsXiao10(split,ntrain);
[cvC1,cvAcc1,A1,info1,scores1,acc1,timing1] = playSvmModelSelectionTrainTest(Ytrn,Ktrn,Ytst,Ktst,svmCs);
[mtlA1,mtlKw1,mtlinfo1,mtlscores1,mtlacc1,mtltiming1]=playMtlTrainTest(Ytrn,Ktrn,Ytst,Ktst,mtlC1,mtlC2,A1);
t = toc(t);

fprintf('\n');
fprintf('Selected models (STL-SDCA):\n');
fprintf('          our kernels: C = %g (CV accuracy: %5.2f%%)\n', cvC, 100*cvAcc);
fprintf('  Xiao et al. kernels: C = %g (CV accuracy: %5.2f%%)\n', cvC1, 100*cvAcc1);
fprintf('Test accuracies (split=%d, Ntrain=%d): STL / MTL:\n', split, ntrain);
fprintf('          our kernels: %5.2f%% / %5.2f%%\n', 100*acc, 100*mtlacc);
fprintf('  Xiao et al. kernels: %5.2f%% / %5.2f%%\n', 100*acc1, 100*mtlacc1);
fprintf('Elapsed time: %s\n', sec2hstr(t));

% Observed output:
% (MTL does not seem to improve over STL with the kernels from Xiao et al.)
%
% Selected models (STL-SDCA):
%           our kernels: C = 10 (CV accuracy: 13.90%)
%   Xiao et al. kernels: C = 0.01 (CV accuracy:  9.61%)
% Test accuracies (split=1, Ntrain=5): STL / MTL:
%           our kernels: 22.29% / 22.58%
%   Xiao et al. kernels: 15.60% / 14.74%
% Elapsed time: 3.5 mins

% diary off;
