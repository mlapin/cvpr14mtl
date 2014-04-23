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

fprintf('%s', '& & & 64 ');
ix = iS01 & iStl & ~iLcs & ~iPN & ~iL2 & iPca64;
rowSplitOne(r,ix,iN05,iN10,iN20,iN50,iKlin,iKhel,iKchi);

fprintf('%s', '$\centerdot$ & & & 64 ');
ix = iS01 & iStl &  iLcs & ~iPN & ~iL2 & iPca64;
rowSplitOne(r,ix,iN05,iN10,iN20,iN50,iKlin,iKhel,iKchi);

fprintf('%s', '$\centerdot$ & $\centerdot$ & & 64 ');
ix = iS01 & iStl &  iLcs &  iPN & ~iL2 & iPca64;
rowSplitOne(r,ix,iN05,iN10,iN20,iN50,iKlin,iKhel,iKchi);

fprintf('%s', '$\centerdot$ & & $\centerdot$ & 64 ');
ix = iS01 & iStl &  iLcs & ~iPN &  iL2 & iPca64;
rowSplitOne(r,ix,iN05,iN10,iN20,iN50,iKlin,iKhel,iKchi);

fprintf('%s', '$\centerdot$ & $\centerdot$ & $\centerdot$ & 64 ');
ix = iS01 & iStl &  iLcs &  iPN &  iL2 & iPca64;
rowSplitOne(r,ix,iN05,iN10,iN20,iN50,iKlin,iKhel,iKchi);

fprintf('%s', '$\centerdot$ & & & 128 ');
ix = iS01 & iStl &  iLcs & ~iPN & ~iL2 & iPca128;
rowSplitOne(r,ix,iN05,iN10,iN20,iN50,iKlin,iKhel,iKchi);

fprintf('%s', '$\centerdot$ & $\centerdot$ & & 128 ');
ix = iS01 & iStl &  iLcs &  iPN & ~iL2 & iPca128;
rowSplitOne(r,ix,iN05,iN10,iN20,iN50,iKlin,iKhel,iKchi);

fprintf('%s', '$\centerdot$ & & $\centerdot$ & 128 ');
ix = iS01 & iStl &  iLcs & ~iPN &  iL2 & iPca128;
rowSplitOne(r,ix,iN05,iN10,iN20,iN50,iKlin,iKhel,iKchi);

fprintf('%s', '$\centerdot$ & $\centerdot$ & $\centerdot$ & 128 ');
ix = iS01 & iStl &  iLcs &  iPN &  iL2 & iPca128;
rowSplitOne(r,ix,iN05,iN10,iN20,iN50,iKlin,iKhel,iKchi);
