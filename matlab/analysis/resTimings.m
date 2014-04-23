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


t = zeros(1,4);
fprintf('%s', 'STL, Sqr & ');
ix = iStl & iSIFT & iKhel;
t = rowTimings(r,ix,iN05,iN10,iN20,iN50,t);

fprintf('%s', 'STL-Stkd, Sqr & ');
ix = iMtlS & iSIFT & iKhel & iMtlSModel;
rowTimings(r,ix,iN05,iN10,iN20,iN50,t);

fprintf('%s', 'MTL, Sqr & ');
ix = iMtlM & iSIFT & iKhel & iMtlMModel;
rowTimings(r,ix,iN05,iN10,iN20,iN50,t);


t = zeros(1,4);
fprintf('%s\n', '\midrule');
fprintf('%s', 'STL, Sqr & LCS ');
ix = iStl & iLCS & iKhel;
t = rowTimings(r,ix,iN05,iN10,iN20,iN50,t);

fprintf('%s', 'STL-Stkd, Sqr & LCS ');
ix = iMtlS & iLCS & iKhel & iMtlSModel;
rowTimings(r,ix,iN05,iN10,iN20,iN50,t);

fprintf('%s', 'MTL, Sqr & LCS ');
ix = iMtlM & iLCS & iKhel & iMtlMModel;
rowTimings(r,ix,iN05,iN10,iN20,iN50,t);


t = zeros(1,4);
fprintf('%s\n', '\midrule');
fprintf('%s', 'STL, Sqr & LCS+PN ');
ix = iStl & iLCSPN & iKhel;
t = rowTimings(r,ix,iN05,iN10,iN20,iN50,t);

fprintf('%s', 'STL-Stkd, Sqr & LCS+PN ');
ix = iMtlS & iLCSPN & iKhel & iMtlSModel;
rowTimings(r,ix,iN05,iN10,iN20,iN50,t);

fprintf('%s', 'MTL, Sqr & LCS+PN ');
ix = iMtlM & iLCSPN & iKhel & iMtlMModel;
rowTimings(r,ix,iN05,iN10,iN20,iN50,t);


t = zeros(1,4);
fprintf('%s\n', '\midrule');
fprintf('%s', 'STL, Sqr & LCS+L2 ');
ix = iStl & iLCSL2 & iKhel;
t = rowTimings(r,ix,iN05,iN10,iN20,iN50,t);

fprintf('%s', 'STL-Stkd, Sqr & LCS+L2 ');
ix = iMtlS & iLCSL2 & iKhel & iMtlSModel;
rowTimings(r,ix,iN05,iN10,iN20,iN50,t);

fprintf('%s', 'MTL, Sqr & LCS+L2 ');
ix = iMtlM & iLCSL2 & iKhel & iMtlMModel;
rowTimings(r,ix,iN05,iN10,iN20,iN50,t);


t = zeros(1,4);
fprintf('%s\n', '\midrule');
fprintf('%s', 'STL, Sqr & LCS+PN+L2 ');
ix = iStl & iLCSPNL2 & iKhel;
t = rowTimings(r,ix,iN05,iN10,iN20,iN50,t);

fprintf('%s', 'STL-Stkd, Sqr & LCS+PN+L2 ');
ix = iMtlS & iLCSPNL2 & iKhel & iMtlSModel;
rowTimings(r,ix,iN05,iN10,iN20,iN50,t);

fprintf('%s', 'MTL, Sqr & LCS+PN+L2 ');
ix = iMtlM & iLCSPNL2 & iKhel & iMtlMModel;
rowTimings(r,ix,iN05,iN10,iN20,iN50,t);
