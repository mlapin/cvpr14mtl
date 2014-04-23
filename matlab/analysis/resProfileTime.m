
ccc;
myinit;

folder = 'experiments/ex-SUN397-R100K-S01-T50/5e523890b042286b77cbf3bf251e69db11523431';
encoderFile = 'encoder.mat';
kernelFile = 'result-Khell-trn-nobias.mat';
stlFile = 'result-Khell-C1.000000e+01.mat';
mtlSFile = 'result-Khell-C1.000000e+01-S-C1.000000e+00-C0.000000e+00.mat';
mtlMFile = 'result-Khell-C1.000000e+01-M-C1.000000e-03-C1.000000e+05.mat';

encoder = load(fullfile(folder, encoderFile));
load(fullfile(folder, kernelFile), 'descrsTime');
stl = load(fullfile(folder, stlFile), 'timing'); stl = stl.timing;
mtlS = load(fullfile(folder, mtlSFile), 'timing'); mtlS = mtlS.timing;
mtlM = load(fullfile(folder, mtlMFile), 'timing'); mtlM = mtlM.timing;

fprintf('Runtime performance results of a single run on SUN397.\n');
type(fullfile(folder, '.description'));

fprintf('Format: dd.HH:MM:SS.FFF\n');
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

total = descrsTime.wallTimeKerMap + descrsTime.wallTimeTrnTrn + descrsTime.wallTimeTrnTst;
fprintf('Total Wall Time: %s (%10.3f seconds)\n', sec2str(total), total);
fprintf('     Kernel Map: %s (%10.3f seconds)\n', sec2str(descrsTime.wallTimeKerMap), descrsTime.wallTimeKerMap);
fprintf('    Xtrn * Xtrn: %s (%10.3f seconds)\n', sec2str(descrsTime.wallTimeTrnTrn), descrsTime.wallTimeTrnTrn);
fprintf('    Xtrn * Xtst: %s (%10.3f seconds)\n', sec2str(descrsTime.wallTimeTrnTst), descrsTime.wallTimeTrnTst);

total = descrsTime.cpuTimeKerMap + descrsTime.cpuTimeTrnTrn + descrsTime.cpuTimeTrnTst;
fprintf(' Total CPU Time: %s (%10.3f seconds)\n', sec2str(total), total);
fprintf('     Kernel Map: %s (%10.3f seconds)\n', sec2str(descrsTime.cpuTimeKerMap), descrsTime.cpuTimeKerMap);
fprintf('    Xtrn * Xtrn: %s (%10.3f seconds)\n', sec2str(descrsTime.cpuTimeTrnTrn), descrsTime.cpuTimeTrnTrn);
fprintf('    Xtrn * Xtst: %s (%10.3f seconds)\n', sec2str(descrsTime.cpuTimeTrnTst), descrsTime.cpuTimeTrnTst);

fprintf('\n');

fprintf('STL time:\n');

total = stl.wallTimeTrn + stl.wallTimeTst;
fprintf('Total Wall Time: %s (%10.3f seconds)\n', sec2str(total), total);
fprintf('          Train: %s (%10.3f seconds)\n', sec2str(stl.wallTimeTrn), stl.wallTimeTrn);
fprintf('           Test: %s (%10.3f seconds)\n', sec2str(stl.wallTimeTst), stl.wallTimeTst);

total = stl.cpuTimeTrn + stl.cpuTimeTst;
fprintf(' Total CPU Time: %s (%10.3f seconds)\n', sec2str(total), total);
fprintf('          Train: %s (%10.3f seconds)\n', sec2str(stl.cpuTimeTrn), stl.cpuTimeTrn);
fprintf('           Test: %s (%10.3f seconds)\n', sec2str(stl.cpuTimeTst), stl.cpuTimeTst);

fprintf('\n');

fprintf('STL-Stacked time:\n');

total = mtlS.wallTimeTrn + mtlS.wallTimeTst + mtlS.wallTimeZ + mtlS.wallTimeZTrnTrn + mtlS.wallTimeZTrnTst;
fprintf('Total Wall Time: %s (%10.3f seconds)\n', sec2str(total), total);
fprintf('          Train: %s (%10.3f seconds)\n', sec2str(mtlS.wallTimeTrn), mtlS.wallTimeTrn);
fprintf('           Test: %s (%10.3f seconds)\n', sec2str(mtlS.wallTimeTst), mtlS.wallTimeTst);
fprintf('           Ztrn: %s (%10.3f seconds)\n', sec2str(mtlS.wallTimeZ), mtlS.wallTimeZ);
fprintf('    Ztrn * Ztrn: %s (%10.3f seconds)\n', sec2str(mtlS.wallTimeZTrnTrn), mtlS.wallTimeZTrnTrn);
fprintf('    Ztrn * Ztst: %s (%10.3f seconds)\n', sec2str(mtlS.wallTimeZTrnTst), mtlS.wallTimeZTrnTst);

total = mtlS.cpuTimeTrn + mtlS.cpuTimeTst + mtlS.cpuTimeZ + mtlS.cpuTimeZTrnTrn + mtlS.cpuTimeZTrnTst;
fprintf(' Total CPU Time: %s (%10.3f seconds)\n', sec2str(total), total);
fprintf('          Train: %s (%10.3f seconds)\n', sec2str(mtlS.cpuTimeTrn), mtlS.cpuTimeTrn);
fprintf('           Test: %s (%10.3f seconds)\n', sec2str(mtlS.cpuTimeTst), mtlS.cpuTimeTst);
fprintf('           Ztrn: %s (%10.3f seconds)\n', sec2str(mtlS.cpuTimeZ), mtlS.cpuTimeZ);
fprintf('    Ztrn * Ztrn: %s (%10.3f seconds)\n', sec2str(mtlS.cpuTimeZTrnTrn), mtlS.cpuTimeZTrnTrn);
fprintf('    Ztrn * Ztst: %s (%10.3f seconds)\n', sec2str(mtlS.cpuTimeZTrnTst), mtlS.cpuTimeZTrnTst);

fprintf('\n');

fprintf('MTL time:\n');

total = mtlM.wallTimeTrn + mtlM.wallTimeTst + mtlM.wallTimeZ + mtlM.wallTimeZTrnTrn + mtlM.wallTimeZTrnTst;
fprintf('Total Wall Time: %s (%10.3f seconds)\n', sec2str(total), total);
fprintf('          Train: %s (%10.3f seconds)\n', sec2str(mtlM.wallTimeTrn), mtlM.wallTimeTrn);
fprintf('           Test: %s (%10.3f seconds)\n', sec2str(mtlM.wallTimeTst), mtlM.wallTimeTst);
fprintf('           Ztrn: %s (%10.3f seconds)\n', sec2str(mtlM.wallTimeZ), mtlM.wallTimeZ);
fprintf('    Ztrn * Ztrn: %s (%10.3f seconds)\n', sec2str(mtlM.wallTimeZTrnTrn), mtlM.wallTimeZTrnTrn);
fprintf('    Ztrn * Ztst: %s (%10.3f seconds)\n', sec2str(mtlM.wallTimeZTrnTst), mtlM.wallTimeZTrnTst);

total = mtlM.cpuTimeTrn + mtlM.cpuTimeTst + mtlM.cpuTimeZ + mtlM.cpuTimeZTrnTrn + mtlM.cpuTimeZTrnTst;
fprintf(' Total CPU Time: %s (%10.3f seconds)\n', sec2str(total), total);
fprintf('          Train: %s (%10.3f seconds)\n', sec2str(mtlM.cpuTimeTrn), mtlM.cpuTimeTrn);
fprintf('           Test: %s (%10.3f seconds)\n', sec2str(mtlM.cpuTimeTst), mtlM.cpuTimeTst);
fprintf('           Ztrn: %s (%10.3f seconds)\n', sec2str(mtlM.cpuTimeZ), mtlM.cpuTimeZ);
fprintf('    Ztrn * Ztrn: %s (%10.3f seconds)\n', sec2str(mtlM.cpuTimeZTrnTrn), mtlM.cpuTimeZTrnTrn);
fprintf('    Ztrn * Ztst: %s (%10.3f seconds)\n', sec2str(mtlM.cpuTimeZTrnTst), mtlM.cpuTimeZTrnTst);

fprintf('\n');

fprintf('MTL/STL ratio (i.e. MTL overhead factor):\n');
fprintf('                              Wall Time:\n');
fprintf('                                  Train: %g\n', mtlM.wallTimeTrn / stl.wallTimeTrn);
common = descrsTime.wallTimeKerMap + descrsTime.wallTimeTrnTrn;
mtlOnly = mtlM.wallTimeZ + mtlM.wallTimeZTrnTrn;
fprintf('                Kernels(no STL) + Train: %g\n', (mtlM.wallTimeTrn + common + mtlOnly) / (stl.wallTimeTrn + common));
mtlOnly = mtlM.wallTimeZ + mtlM.wallTimeZTrnTrn + stl.wallTimeTrn;
fprintf('                        Kernels + Train: %g\n', (mtlM.wallTimeTrn + common + mtlOnly) / (stl.wallTimeTrn + common));
common = descrsTime.wallTimeKerMap + descrsTime.wallTimeTrnTrn + descrsTime.wallTime/2;
fprintf('          Descriptors + Kernels + Train: %g\n', (mtlM.wallTimeTrn + common + mtlOnly) / (stl.wallTimeTrn + common));
common = descrsTime.wallTimeKerMap + descrsTime.wallTimeTrnTrn + descrsTime.wallTime/2 + encoder.wallTime;
fprintf('Encoder + Descriptors + Kernels + Train: %g\n', (mtlM.wallTimeTrn + common + mtlOnly) / (stl.wallTimeTrn + common));

fprintf('                               CPU Time:\n');
fprintf('                                  Train: %g\n', mtlM.cpuTimeTrn / stl.cpuTimeTrn);
common = descrsTime.cpuTimeKerMap + descrsTime.cpuTimeTrnTrn;
mtlOnly = mtlM.cpuTimeZ + mtlM.cpuTimeZTrnTrn;
fprintf('                Kernels(no STL) + Train: %g\n', (mtlM.cpuTimeTrn + common + mtlOnly) / (stl.cpuTimeTrn + common));
mtlOnly = mtlM.cpuTimeZ + mtlM.cpuTimeZTrnTrn + stl.cpuTimeTrn;
fprintf('                        Kernels + Train: %g\n', (mtlM.cpuTimeTrn + common + mtlOnly) / (stl.cpuTimeTrn + common));
common = descrsTime.cpuTimeKerMap + descrsTime.cpuTimeTrnTrn + descrsTime.cpuTime/2;
fprintf('          Descriptors + Kernels + Train: %g\n', (mtlM.cpuTimeTrn + common + mtlOnly) / (stl.cpuTimeTrn + common));
common = descrsTime.cpuTimeKerMap + descrsTime.cpuTimeTrnTrn + descrsTime.cpuTime/2 + encoder.cpuTime;
fprintf('Encoder + Descriptors + Kernels + Train: %g\n', (mtlM.cpuTimeTrn + common + mtlOnly) / (stl.cpuTimeTrn + common));

fprintf('\nLegend:\n');
fprintf('  Train: runtime of the SDCA algorithm given precomputed data\n');
fprintf('  Kernels(no STL): kernel maps + Xtrn * Xtrn; for MTL, additionally Ztrn = stlA * Ktrn and Ztrn * Ztrn\n');
fprintf('  Kernels: same as above, but MTL time also includes the STL training time (initial point!)\n');
fprintf('  Descriptors: computation of Xtrn (1/2 of descriptors total time)\n');
fprintf('  Encoder: training the encoder\n');

fprintf('\n');

fprintf('Machine details (lscpu):\n');
fprintf('%s', system('ssh -x d2blade29 lscpu'));
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
