%
% Show profiling results
% (reported in the supplementary material)
%

clc;
clear;
close all;
myinit;

% Load profiling results
cachedResultsFile = 'experiments/profiling.mat';
try
  load(cachedResultsFile);
catch
  folder = 'experiments/ex-SUN397-R100K-S01-T50/5e523890b042286b77cbf3bf251e69db11523431';
  encoderFile = 'encoder.mat';
  kernelFile = 'result-Khell-trn-nobias.mat';
  stlFile = 'result-Khell-C1.000000e+01.mat';
  mtlSFile = 'result-Khell-C1.000000e+01-S-C1.000000e+00-C0.000000e+00.mat';
  mtlMFile = 'result-Khell-C1.000000e+01-M-C1.000000e-03-C1.000000e+05.mat';

  encoder = load(fullfile(folder, encoderFile));
  load(fullfile(folder, kernelFile), 'descrsTime');
  stl = load(fullfile(folder, stlFile), 'timing'); stl = stl.timing;      % STL
  mtlS = load(fullfile(folder, mtlSFile), 'timing'); mtlS = mtlS.timing;  % STL-Stacked
  mtlM = load(fullfile(folder, mtlMFile), 'timing'); mtlM = mtlM.timing;  % MTL
  
  save(cachedResultsFile, 'stl', 'mtlS', 'mtlM', 'descrsTime', 'encoder');
end

% Compute timings

wallKernelTotal = descrsTime.wallTimeKerMap + descrsTime.wallTimeTrnTrn + descrsTime.wallTimeTrnTst;
cpuKernelTotal = descrsTime.cpuTimeKerMap + descrsTime.cpuTimeTrnTrn + descrsTime.cpuTimeTrnTst;

wallStlTrainTest = stl.wallTimeTrn + stl.wallTimeTst;
cpuStlTrainTest = stl.cpuTimeTrn + stl.cpuTimeTst;

wallStlStackTrainTest = mtlS.wallTimeTrn + mtlS.wallTimeTst + mtlS.wallTimeZ + mtlS.wallTimeZTrnTrn + mtlS.wallTimeZTrnTst;
cpuStlStackTrainTest = mtlS.cpuTimeTrn + mtlS.cpuTimeTst + mtlS.cpuTimeZ + mtlS.cpuTimeZTrnTrn + mtlS.cpuTimeZTrnTst;

wallMtlTrainTest = mtlM.wallTimeTrn + mtlM.wallTimeTst + mtlM.wallTimeZ + mtlM.wallTimeZTrnTrn + mtlM.wallTimeZTrnTst;
cpuMtlTrainTest = mtlM.cpuTimeTrn + mtlM.cpuTimeTst + mtlM.cpuTimeZ + mtlM.cpuTimeZTrnTrn + mtlM.cpuTimeZTrnTst;

wallKernelCommon = descrsTime.wallTimeKerMap + descrsTime.wallTimeTrnTrn;
wallDescrsKernelCommon = wallKernelCommon + descrsTime.wallTime/2; % + training set descriptors
wallTotalCommon = wallDescrsKernelCommon + encoder.wallTime; % + training encoder (GMM for the FV)
wallKernelMtlOnly = mtlM.wallTimeZ + mtlM.wallTimeZTrnTrn + stl.wallTimeTrn; % initial point for MTL

wallStlKernelTrain = wallKernelCommon + stl.wallTimeTrn;
wallMtlKernelTrain = wallKernelCommon + + wallKernelMtlOnly + mtlM.wallTimeTrn;
wallStlDescrsKernelTrain = wallDescrsKernelCommon + stl.wallTimeTrn;
wallMtlDescrsKernelTrain = wallDescrsKernelCommon + + wallKernelMtlOnly + mtlM.wallTimeTrn;
wallStlTotalTrain = wallTotalCommon + stl.wallTimeTrn;
wallMtlTotalTrain = wallTotalCommon + + wallKernelMtlOnly + mtlM.wallTimeTrn;

cpuKernelCommon = descrsTime.cpuTimeKerMap + descrsTime.cpuTimeTrnTrn;
cpuDescrsKernelCommon = cpuKernelCommon + descrsTime.cpuTime/2; % + training set descriptors
cpuTotalCommon = cpuDescrsKernelCommon + encoder.cpuTime; % + training encoder (GMM for the FV)
cpuKernelMtlOnly = mtlM.cpuTimeZ + mtlM.cpuTimeZTrnTrn + stl.cpuTimeTrn; % initial point for MTL

cpuStlKernelTrain = cpuKernelCommon + stl.cpuTimeTrn;
cpuMtlKernelTrain = cpuKernelCommon + + cpuKernelMtlOnly + mtlM.cpuTimeTrn;
cpuStlDescrsKernelTrain = cpuDescrsKernelCommon + stl.cpuTimeTrn;
cpuMtlDescrsKernelTrain = cpuDescrsKernelCommon + + cpuKernelMtlOnly + mtlM.cpuTimeTrn;
cpuStlTotalTrain = cpuTotalCommon + stl.cpuTimeTrn;
cpuMtlTotalTrain = cpuTotalCommon + + cpuKernelMtlOnly + mtlM.cpuTimeTrn;

% Print details

fprintf('\n');
fprintf('Further details:\n');
fprintf('\n');
if exist('folder', 'var')
  type(fullfile(folder, '.description'));
end

fprintf('\n');
fprintf('Timespan format: dd.HH:MM:SS.FFF\n');
fprintf('\n');

fprintf('Training Encoder (%d images, %d words):\n', encoder.numImages, encoder.numWords);

fprintf('Total Wall Time: %s (%10.3f seconds)\n', sec2str(encoder.wallTime), encoder.wallTime);
fprintf('             IO: %s (%10.3f seconds)\n', sec2str(encoder.wallTimeIO), encoder.wallTimeIO);
fprintf('         D-SIFT: %s (%10.3f seconds)\n', sec2str(encoder.wallTimeExtract), encoder.wallTimeExtract);
fprintf('            PCA: %s (%10.3f seconds)\n', sec2str(encoder.wallTimePca), encoder.wallTimePca);
fprintf('     Vocabulary: %s (%10.3f seconds)\n', sec2str(encoder.wallTimeVocab), encoder.wallTimeVocab);

fprintf(' Total CPU Time: %s (%10.3f seconds)\n', sec2str(encoder.cpuTime), encoder.cpuTime);
fprintf('             IO: %s (%10.3f seconds)\n', sec2str(encoder.cpuTimeIO), encoder.cpuTimeIO);
fprintf('         D-SIFT: %s (%10.3f seconds)\n', sec2str(encoder.cpuTimeExtract), encoder.cpuTimeExtract);
fprintf('            PCA: %s (%10.3f seconds)\n', sec2str(encoder.cpuTimePca), encoder.cpuTimePca);
fprintf('     Vocabulary: %s (%10.3f seconds)\n', sec2str(encoder.cpuTimeVocab), encoder.cpuTimeVocab);

fprintf('\n');

fprintf('Computing descriptors (%d images):\n', descrsTime.numImages);

fprintf('Total Wall Time: %s (%10.3f seconds)\n', sec2str(descrsTime.wallTime), descrsTime.wallTime);
fprintf('             IO: %s (%10.3f seconds)\n', sec2str(descrsTime.wallTimeIO), descrsTime.wallTimeIO);
fprintf('         D-SIFT: %s (%10.3f seconds)\n', sec2str(descrsTime.wallTimeExtract), descrsTime.wallTimeExtract);
fprintf('         Encode: %s (%10.3f seconds)\n', sec2str(descrsTime.wallTimeEncode), descrsTime.wallTimeEncode);

fprintf(' Total CPU Time: %s (%10.3f seconds)\n', sec2str(descrsTime.cpuTime), descrsTime.cpuTime);
fprintf('             IO: %s (%10.3f seconds)\n', sec2str(descrsTime.cpuTimeIO), descrsTime.cpuTimeIO);
fprintf('         D-SIFT: %s (%10.3f seconds)\n', sec2str(descrsTime.cpuTimeExtract), descrsTime.cpuTimeExtract);
fprintf('         Encode: %s (%10.3f seconds)\n', sec2str(descrsTime.cpuTimeEncode), descrsTime.cpuTimeEncode);

fprintf('\n');

fprintf('Computing kernels:\n');

fprintf('Total Wall Time: %s (%10.3f seconds)\n', sec2str(wallKernelTotal), wallKernelTotal);
fprintf('     Kernel Map: %s (%10.3f seconds)\n', sec2str(descrsTime.wallTimeKerMap), descrsTime.wallTimeKerMap);
fprintf('    Xtrn * Xtrn: %s (%10.3f seconds)\n', sec2str(descrsTime.wallTimeTrnTrn), descrsTime.wallTimeTrnTrn);
fprintf('    Xtrn * Xtst: %s (%10.3f seconds)\n', sec2str(descrsTime.wallTimeTrnTst), descrsTime.wallTimeTrnTst);

fprintf(' Total CPU Time: %s (%10.3f seconds)\n', sec2str(cpuKernelTotal), cpuKernelTotal);
fprintf('     Kernel Map: %s (%10.3f seconds)\n', sec2str(descrsTime.cpuTimeKerMap), descrsTime.cpuTimeKerMap);
fprintf('    Xtrn * Xtrn: %s (%10.3f seconds)\n', sec2str(descrsTime.cpuTimeTrnTrn), descrsTime.cpuTimeTrnTrn);
fprintf('    Xtrn * Xtst: %s (%10.3f seconds)\n', sec2str(descrsTime.cpuTimeTrnTst), descrsTime.cpuTimeTrnTst);

fprintf('\n');

fprintf('STL time:\n');

fprintf('Total Wall Time: %s (%10.3f seconds)\n', sec2str(wallStlTrainTest), wallStlTrainTest);
fprintf('          Train: %s (%10.3f seconds)\n', sec2str(stl.wallTimeTrn), stl.wallTimeTrn);
fprintf('           Test: %s (%10.3f seconds)\n', sec2str(stl.wallTimeTst), stl.wallTimeTst);

fprintf(' Total CPU Time: %s (%10.3f seconds)\n', sec2str(cpuStlTrainTest), cpuStlTrainTest);
fprintf('          Train: %s (%10.3f seconds)\n', sec2str(stl.cpuTimeTrn), stl.cpuTimeTrn);
fprintf('           Test: %s (%10.3f seconds)\n', sec2str(stl.cpuTimeTst), stl.cpuTimeTst);

fprintf('\n');

fprintf('STL-Stacked time:\n');

fprintf('Total Wall Time: %s (%10.3f seconds)\n', sec2str(wallStlStackTrainTest), wallStlStackTrainTest);
fprintf('          Train: %s (%10.3f seconds)\n', sec2str(mtlS.wallTimeTrn), mtlS.wallTimeTrn);
fprintf('           Test: %s (%10.3f seconds)\n', sec2str(mtlS.wallTimeTst), mtlS.wallTimeTst);
fprintf('           Ztrn: %s (%10.3f seconds)\n', sec2str(mtlS.wallTimeZ), mtlS.wallTimeZ);
fprintf('    Ztrn * Ztrn: %s (%10.3f seconds)\n', sec2str(mtlS.wallTimeZTrnTrn), mtlS.wallTimeZTrnTrn);
fprintf('    Ztrn * Ztst: %s (%10.3f seconds)\n', sec2str(mtlS.wallTimeZTrnTst), mtlS.wallTimeZTrnTst);

fprintf(' Total CPU Time: %s (%10.3f seconds)\n', sec2str(cpuStlStackTrainTest), cpuStlStackTrainTest);
fprintf('          Train: %s (%10.3f seconds)\n', sec2str(mtlS.cpuTimeTrn), mtlS.cpuTimeTrn);
fprintf('           Test: %s (%10.3f seconds)\n', sec2str(mtlS.cpuTimeTst), mtlS.cpuTimeTst);
fprintf('           Ztrn: %s (%10.3f seconds)\n', sec2str(mtlS.cpuTimeZ), mtlS.cpuTimeZ);
fprintf('    Ztrn * Ztrn: %s (%10.3f seconds)\n', sec2str(mtlS.cpuTimeZTrnTrn), mtlS.cpuTimeZTrnTrn);
fprintf('    Ztrn * Ztst: %s (%10.3f seconds)\n', sec2str(mtlS.cpuTimeZTrnTst), mtlS.cpuTimeZTrnTst);

fprintf('\n');

fprintf('MTL time:\n');

fprintf('Total Wall Time: %s (%10.3f seconds)\n', sec2str(wallMtlTrainTest), wallMtlTrainTest);
fprintf('          Train: %s (%10.3f seconds)\n', sec2str(mtlM.wallTimeTrn), mtlM.wallTimeTrn);
fprintf('           Test: %s (%10.3f seconds)\n', sec2str(mtlM.wallTimeTst), mtlM.wallTimeTst);
fprintf('           Ztrn: %s (%10.3f seconds)\n', sec2str(mtlM.wallTimeZ), mtlM.wallTimeZ);
fprintf('    Ztrn * Ztrn: %s (%10.3f seconds)\n', sec2str(mtlM.wallTimeZTrnTrn), mtlM.wallTimeZTrnTrn);
fprintf('    Ztrn * Ztst: %s (%10.3f seconds)\n', sec2str(mtlM.wallTimeZTrnTst), mtlM.wallTimeZTrnTst);

fprintf(' Total CPU Time: %s (%10.3f seconds)\n', sec2str(cpuMtlTrainTest), cpuMtlTrainTest);
fprintf('          Train: %s (%10.3f seconds)\n', sec2str(mtlM.cpuTimeTrn), mtlM.cpuTimeTrn);
fprintf('           Test: %s (%10.3f seconds)\n', sec2str(mtlM.cpuTimeTst), mtlM.cpuTimeTst);
fprintf('           Ztrn: %s (%10.3f seconds)\n', sec2str(mtlM.cpuTimeZ), mtlM.cpuTimeZ);
fprintf('    Ztrn * Ztrn: %s (%10.3f seconds)\n', sec2str(mtlM.cpuTimeZTrnTrn), mtlM.cpuTimeZTrnTrn);
fprintf('    Ztrn * Ztst: %s (%10.3f seconds)\n', sec2str(mtlM.cpuTimeZTrnTst), mtlM.cpuTimeZTrnTst);

fprintf('\n');

fprintf('MTL/STL ratio (i.e. MTL overhead factor):\n');
fprintf('                              Wall Time:\n');
fprintf('                                  Train: %g\n', mtlM.wallTimeTrn / stl.wallTimeTrn);
fprintf('                        Kernels + Train: %g\n', wallMtlKernelTrain / wallStlKernelTrain);
fprintf('          Descriptors + Kernels + Train: %g\n', wallMtlDescrsKernelTrain / wallStlDescrsKernelTrain);
fprintf('Encoder + Descriptors + Kernels + Train: %g\n', wallMtlTotalTrain / wallStlTotalTrain);

fprintf('                               CPU Time:\n');
fprintf('                                  Train: %g\n', mtlM.cpuTimeTrn / stl.cpuTimeTrn);
fprintf('                        Kernels + Train: %g\n', cpuMtlKernelTrain / cpuStlKernelTrain);
fprintf('          Descriptors + Kernels + Train: %g\n', cpuMtlDescrsKernelTrain / cpuStlDescrsKernelTrain);
fprintf('Encoder + Descriptors + Kernels + Train: %g\n', cpuMtlTotalTrain / cpuStlTotalTrain);

fprintf('\nLegend:\n');
fprintf('  Train: runtime of the SDCA algorithm given precomputed data\n');
fprintf('  Kernels(no STL): kernel maps + Xtrn * Xtrn; for MTL, additionally Ztrn = stlA * Ktrn and Ztrn * Ztrn\n');
fprintf('  Kernels: same as above, but MTL time also includes the STL training time (initial point!)\n');
fprintf('  Descriptors: computation of Xtrn (1/2 of descriptors total time)\n');
fprintf('  Encoder: training the encoder\n');

fprintf('\n');

fprintf('Machine details (lscpu):\n');
try %#ok<TRYNC>
  fprintf('%s', system('ssh -x d2blade29 lscpu'));
end
% Output:
% Architecture:          x86_64
% CPU op-mode(s):        32-bit, 64-bit
% Byte Order:            Little Endian
% CPU(s):                32
% On-line CPU(s) list:   0-31
% Thread(s) per core:    2
% Core(s) per socket:    8
% Socket(s):             2
% NUMA node(s):          2
% Vendor ID:             GenuineIntel
% CPU family:            6
% Model:                 45
% Stepping:              7
% CPU MHz:               2699.917
% BogoMIPS:              5402.06
% Virtualization:        VT-x
% L1d cache:             32K
% L1i cache:             32K
% L2 cache:              256K
% L3 cache:              20480K
% NUMA node0 CPU(s):     0,2,4,6,8,10,12,14,16,18,20,22,24,26,28,30
% NUMA node1 CPU(s):     1,3,5,7,9,11,13,15,17,19,21,23,25,27,29,31

fprintf('\n');
fprintf('Runtime performance results of a single run on SUN397:\n');

fprintf('\n');
fprintf('%%Wall time:\n');
fprintf('%s\n', '\begin{tabular}{lccc}\toprule');
fprintf('Routine & STL & MTL & MTL/STL \\\\ \n');
fprintf('%s\n', '\midrule\midrule');
fprintf('Prepare image encoder (fit a GMM for the Fisher Vector) & \\multicolumn{2}{c}{%s} & -- \\\\\n', ...
  sec2hstr(encoder.wallTime));
fprintf('Compute Fisher Vector image descriptors (train and test subsets) & \\multicolumn{2}{c}{%s} & -- \\\\\n', ...
  sec2hstr(descrsTime.wallTime));
fprintf('Compute train and test kernels & \\multicolumn{2}{c}{%s} & -- \\\\\n', ...
  sec2hstr(wallKernelTotal));
fprintf('%s\n', '\midrule');
fprintf('Solve SDCA optimization problem (pure training time) & %s & %s & %.2f \\\\\n', ...
  sec2hstr(stl.wallTimeTrn), sec2hstr(mtlM.wallTimeTrn), mtlM.wallTimeTrn/stl.wallTimeTrn);
fprintf('+ compute training kernels + compute MTL initial point & %s & %s & %.2f \\\\\n', ...
  sec2hstr(wallStlKernelTrain), sec2hstr(wallMtlKernelTrain), wallMtlKernelTrain/wallStlKernelTrain);
fprintf('+ compute descriptors for training images & %s & %s & %.2f \\\\\n', ...
  sec2hstr(wallStlTotalTrain), sec2hstr(wallMtlTotalTrain), wallMtlTotalTrain/wallStlTotalTrain);
fprintf('%s\n', '\bottomrule');
fprintf('%s\n', '\end{tabular}');

fprintf('\n');
fprintf('%%CPU time:\n');
fprintf('%s\n', '\begin{tabular}{lccc}\toprule');
fprintf('Routine & STL & MTL & MTL/STL \\\\ \n');
fprintf('%s\n', '\midrule\midrule');
fprintf('Prepare image encoder (fit a GMM for the Fisher Vector) & \\multicolumn{2}{c}{%s} & -- \\\\\n', ...
  sec2hstr(encoder.cpuTime));
fprintf('Compute Fisher Vector image descriptors (train and test subsets) & \\multicolumn{2}{c}{%s} & -- \\\\\n', ...
  sec2hstr(descrsTime.cpuTime));
fprintf('Compute train and test kernels & \\multicolumn{2}{c}{%s} & -- \\\\\n', ...
  sec2hstr(cpuKernelTotal));
fprintf('%s\n', '\midrule');
fprintf('Solve SDCA optimization problem (pure training time) & %s & %s & %.2f \\\\\n', ...
  sec2hstr(stl.cpuTimeTrn), sec2hstr(mtlM.cpuTimeTrn), mtlM.cpuTimeTrn/stl.cpuTimeTrn);
fprintf('+ compute training kernels + compute MTL initial point & %s & %s & %.2f \\\\\n', ...
  sec2hstr(cpuStlKernelTrain), sec2hstr(cpuMtlKernelTrain), cpuMtlKernelTrain/cpuStlKernelTrain);
fprintf('+ compute descriptors for training images & %s & %s & %.2f \\\\\n', ...
  sec2hstr(cpuStlTotalTrain), sec2hstr(cpuMtlTotalTrain), cpuMtlTotalTrain/cpuStlTotalTrain);
fprintf('%s\n', '\bottomrule');
fprintf('%s\n', '\end{tabular}');

