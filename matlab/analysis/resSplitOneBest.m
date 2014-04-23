clc;
clear;
close all;

reload = false;
suffix = '2014-04-09';
resFile = sprintf('experiments/results_%s.mat', suffix);

if ~reload && exist(resFile, 'file')
  load(resFile, 'results');
else
  tic;
  results = readExperimentResults();
  toc;
  save(resFile, 'results');
end

defineIndexes;

C1s = 10.^(-4:4);
C2s = 0;
fprintf('%s', 'STL-SDCA-Stacked, Sqr & SIFT ');
ix = iS01 & iMtlS & iSIFT & iKhel;
selectModelSplitOne(r,ix,iN05,iN10,iN20,iN50,C1s,C2s);

fprintf('%s', 'STL-SDCA-Stacked, Sqr & SIFT+LCS+PN ');
ix = iS01 & iMtlS & iLCSPN & iKhel;
selectModelSplitOne(r,ix,iN05,iN10,iN20,iN50,C1s,C2s);

fprintf('%s', 'STL-SDCA-Stacked, Sqr & SIFT+LCS+PN+L2 ');
ix = iS01 & iMtlS & iLCSPNL2 & iKhel;
selectModelSplitOne(r,ix,iN05,iN10,iN20,iN50,C1s,C2s);

fprintf('STL-SDCA-Stacked: Selected C1 = 1\n\n');

C1s = 10.^(-5:-1);
C2s = 10.^(0:5);
fprintf('MTL-SDCA, Sqr | SIFT \n');
ix = iS01 & iMtlM & iSIFT & iKhel;
selectModelSplitOne(r,ix,iN05,iN10,iN20,iN50,C1s,C2s);

fprintf('MTL-SDCA, Sqr | SIFT+LCS+PN \n');
ix = iS01 & iMtlM & iLCSPN & iKhel;
selectModelSplitOne(r,ix,iN05,iN10,iN20,iN50,C1s,C2s);

fprintf('MTL-SDCA, Sqr | SIFT+LCS+PN+L2 \n');
ix = iS01 & iMtlM & iLCSPNL2 & iKhel;
selectModelSplitOne(r,ix,iN05,iN10,iN20,iN50,C1s,C2s);

fprintf('MTL-SDCA: Selected C1 / C2\n');
fprintf('   5: 1e-2 / 1e+3\n');
fprintf('  10: 1e-2 / 1e+3\n');
fprintf('  20: 1e-3 / 1e+3\n');
fprintf('  50: 1e-3 / 1e+5\n');
