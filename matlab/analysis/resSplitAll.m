% clc;
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


fprintf('%s\n', '\midrule');
fprintf('%s\n', 'S{\''a}nchez \etal \cite{sanchez2013image} & SIFT & 19.2 (0.4) & 26.6 (0.4) & 34.2 (0.3) & 43.3 (0.2)\\');
fprintf('%s', 'STL-SDCA, Lin & SIFT ');
ix = iStl & iSIFT & iKlin;
rowSplitAll(r,ix,iN05,iN10,iN20,iN50)

fprintf('%s', 'STL-SDCA, Sqr & SIFT ');
ix = iStl & iSIFT & iKhel;
rowSplitAll(r,ix,iN05,iN10,iN20,iN50)

fprintf('%s', 'STL-SDCA-Stacked, Sqr & SIFT ');
ix = iMtlS & iSIFT & iKhel & iMtlSModel;
rowSplitAll(r,ix,iN05,iN10,iN20,iN50)

fprintf('%s', 'MTL-SDCA, Sqr & SIFT ');
ix = iMtlM & iSIFT & iKhel & iMtlMModel;
rowSplitAll(r,ix,iN05,iN10,iN20,iN50)


fprintf('%s\n', '\midrule');
fprintf('%s\n', 'S{\''a}nchez \etal \cite{sanchez2013image} & SIFT+LCS & 21.1 (0.3) & 29.1 (0.3) & 37.4 (0.3) & 47.2 (0.2)\\');
fprintf('%s', 'STL-SDCA, Sqr & SIFT+LCS ');
ix = iStl & iLCS & iKhel;
rowSplitAll(r,ix,iN05,iN10,iN20,iN50)

fprintf('%s', 'STL-SDCA-Stacked, Sqr & SIFT+LCS ');
ix = iMtlS & iLCS & iKhel & iMtlSModel;
rowSplitAll(r,ix,iN05,iN10,iN20,iN50)

fprintf('%s', 'MTL-SDCA, Sqr & SIFT+LCS ');
ix = iMtlM & iLCS & iKhel & iMtlMModel;
rowSplitAll(r,ix,iN05,iN10,iN20,iN50)


fprintf('%s\n', '\midrule');
fprintf('%s', 'STL-SDCA, Sqr & SIFT+LCS+PN ');
ix = iStl & iLCSPN & iKhel;
rowSplitAll(r,ix,iN05,iN10,iN20,iN50)

fprintf('%s', 'STL-SDCA-Stacked, Sqr & SIFT+LCS+PN ');
ix = iMtlS & iLCSPN & iKhel & iMtlSModel;
rowSplitAll(r,ix,iN05,iN10,iN20,iN50)

fprintf('%s', 'MTL-SDCA, Sqr & SIFT+LCS+PN ');
ix = iMtlM & iLCSPN & iKhel & iMtlMModel;
rowSplitAll(r,ix,iN05,iN10,iN20,iN50)


fprintf('%s\n', '\midrule');
fprintf('%s', 'STL-SDCA, Sqr & SIFT+LCS+L2 ');
ix = iStl & iLCSL2 & iKhel;
rowSplitAll(r,ix,iN05,iN10,iN20,iN50)

fprintf('%s', 'STL-SDCA-Stacked, Sqr & SIFT+LCS+L2 ');
ix = iMtlS & iLCSL2 & iKhel & iMtlSModel;
rowSplitAll(r,ix,iN05,iN10,iN20,iN50)

fprintf('%s', 'MTL-SDCA, Sqr & SIFT+LCS+L2 ');
ix = iMtlM & iLCSL2 & iKhel & iMtlMModel;
rowSplitAll(r,ix,iN05,iN10,iN20,iN50)


fprintf('%s\n', '\midrule');
fprintf('%s', 'STL-SDCA, Sqr & SIFT+LCS+PN+L2 ');
ix = iStl & iLCSPNL2 & iKhel;
rowSplitAll(r,ix,iN05,iN10,iN20,iN50)

fprintf('%s', 'STL-SDCA-Stacked, Sqr & SIFT+LCS+PN+L2 ');
ix = iMtlS & iLCSPNL2 & iKhel & iMtlSModel;
rowSplitAll(r,ix,iN05,iN10,iN20,iN50)

fprintf('%s', 'MTL-SDCA, Sqr & SIFT+LCS+PN+L2 ');
ix = iMtlM & iLCSPNL2 & iKhel & iMtlMModel;
rowSplitAll(r,ix,iN05,iN10,iN20,iN50)
