function traintest(varargin)

profilingRun = false ;
doNotCacheDescriptors = true ;
recomputeCVOlder = datenum(2014,4,9) ;
recomputeResultsOlder = datenum(2014,4,9) ;

errorIfNoKernel = false ;
kernelOnly = false ;

addBias = false ;

if profilingRun
%   recomputeCVOlder = datenum(2020,1,1) ;
  recomputeResultsOlder = datenum(2020,1,1) ;
  errorIfNoKernel = false ;
  kernelOnly = false ;
end

if ~exist('vl_version', 'file')
  run(fullfile(fileparts(which(mfilename)), '..', '..', 'toolbox', 'vl_setup.m')) ;
end

opts.dataset = 'SUN397-R100K' ;
opts.prefix = 'bovw' ;
opts.encoderParams = {'type', 'bovw'} ;
opts.numTrain = 50;
opts.seed = 1 ;
opts.lite = true ;
opts.C = 1 ;
opts.kernel = 'linear' ;
opts.perfMeasure = 'mACC' ;
opts.dataDir = 'data' ;
opts.experimentsDir = 'experiments' ;
for pass = 1:2
  opts.datasetDir = fullfile(opts.dataDir, opts.dataset) ;
  opts.resultDir = fullfile(opts.experimentsDir, opts.prefix, ...
    arg2sha1(optsForSha1(opts))) ;
  opts.imdbPath = fullfile(opts.resultDir, 'imdb.mat') ;
  opts.encoderPath = fullfile(opts.resultDir, 'encoder.mat') ;
  opts.diaryPath = fullfile(opts.resultDir, ...
    sprintf('diary_%s.txt', datestr(now, 'yyyy-mm-dd_HH-MM-SS_FFF'))) ;
  opts.cacheDir = fullfile(opts.resultDir, 'cache') ;
  opts.trnKernelPath = @(kernel) fullfile(opts.resultDir, ...
    sprintf('result-K%s-trn-nobias.mat', kernel)) ;
  opts.tstKernelPath = @(kernel) fullfile(opts.resultDir, ...
    sprintf('result-K%s-tst-nobias.mat', kernel)) ;
  opts.resultPath = @(kernel, C) fullfile(opts.resultDir, ...
    sprintf('result-K%s-C%e.mat', kernel, C)) ;
  opts.modelPath = @(kernel, C) fullfile(opts.resultDir, ...
    sprintf('model-K%s-C%e.mat', kernel, C)) ;
  opts.modelSelectionPath = @(kernel) fullfile(opts.resultDir, ...
    sprintf('model-selection-%s-K%s.mat', opts.perfMeasure, kernel)) ;
  opts = vl_argparse(opts,varargin) ;
end

fprintf('resultDir:\n%s\n', opts.resultDir) ;

% do not do anything if the result data already exist
if numel(opts.C) > 1 && exist(opts.modelSelectionPath(opts.kernel), 'file')
  fstat = dir(opts.modelSelectionPath(opts.kernel)) ;
  assert(numel(fstat) == 1) ;
  fprintf('Found model selection results:\n  name: %s\n  date: %s\n', fstat.name, datestr(fstat.datenum)) ;
  if fstat.datenum >= recomputeCVOlder
    selectedModel = load(opts.modelSelectionPath(opts.kernel), 'C', 'mACC', 'Kfolds') ;
    fprintf('Model selected via %d-fold CV: C = %g (mACC = %.2f)\n', ...
      selectedModel.Kfolds, selectedModel.C, 100*selectedModel.mACC) ;
    opts.C = selectedModel.C ;
  else
    fprintf('..older than %s; ignore.\n', datestr(recomputeCVOlder)) ;
  end
end
if numel(opts.C) == 1 && exist(opts.resultPath(opts.kernel, opts.C), 'file')
  fstat = dir(opts.resultPath(opts.kernel, opts.C)) ;
  assert(numel(fstat) == 1) ;
  fprintf('Found experiment results:\n  name: %s\n  date: %s\n', fstat.name, datestr(fstat.datenum)) ;
  if fstat.datenum >= recomputeResultsOlder
    load(opts.resultPath(opts.kernel, opts.C), 'confusion') ;
    displayResults(confusion) ; %#ok<NODEF>
    diary off ;
    return ;
  else
    fprintf('..older than %s; ignore.', datestr(recomputeResultsOlder)) ;
  end
end

% make sure all the necessary folders exist
vl_xmkdir(opts.resultDir) ;
%vl_xmkdir(opts.cacheDir) ;
% create a symlink to a scratch dir
if ~exist(opts.cacheDir, 'file')
  cacheDirScratch = fullfile('/scratch/BS/pool0/mlapin/experiments', ...
    opts.prefix, arg2sha1(optsForSha1(opts)), 'cache') ;
  fprintf('Creating cache dir:\n%s\n', cacheDirScratch) ;
  vl_xmkdir(cacheDirScratch) ;
  [status, cmdout] = system(sprintf('cd "%s" && rm -rf cache && ln -s "%s"', opts.resultDir, cacheDirScratch)) ;
  if status ~= 0
    fprintf('%s\n', cmdout) ;
    error('TRAINTEST:CACHELINK', 'Failed to create a symlink to %s', cacheDirScratch) ;
  end
end


% store the options description in a human readable format
% (the SHA1 is based on that description)
descriptionFile = fullfile(opts.resultDir, '.description') ;
if ~exist(descriptionFile, 'file')
  dlmwrite(descriptionFile, prettyprint(optsForSha1(opts)), '') ;
end

exStartTime = tic ;
diary(opts.diaryPath) ; diary on ;
fprintf('\nStarted experiment:\n') ;
disp('options:' ); disp(opts) ;
diary off ;
diary on ;

% --------------------------------------------------------------------
%                                                   Get image database
% --------------------------------------------------------------------

if exist(opts.imdbPath, 'file')
  imdb = load(opts.imdbPath);
else
  switch opts.dataset
    case 'scene67', imdb = setupScene67(opts.datasetDir, ...
      'lite', opts.lite) ;
    case 'caltech101', imdb = setupCaltech256(opts.datasetDir, ...
      'lite', opts.lite, 'variant', 'caltech101', 'seed', opts.seed) ;
    case 'caltech256', imdb = setupCaltech256(opts.datasetDir, ...
      'lite', opts.lite) ;
    case 'voc07', imdb = setupVoc(opts.datasetDir, ...
      'lite', opts.lite, 'edition', '2007') ;
    case 'fmd', imdb = setupFMD(opts.datasetDir, ...
      'lite', opts.lite) ;
    case 'SUN397-R100K', imdb = setupSUN397(opts.datasetDir, ...
      'lite', opts.lite, 'numTrain', opts.numTrain, 'seed', opts.seed) ;
    otherwise, error('Unknown dataset type.') ;
  end
  save(opts.imdbPath, '-struct', 'imdb', '-v7') ;
end
diary off ;
diary on ;

% --------------------------------------------------------------------
%                                      Train encoder and encode images
% --------------------------------------------------------------------

if ~profilingRun && exist(opts.encoderPath, 'file')
  encoder = load(opts.encoderPath) ;
else
  encoderOpts.numTrain = 5000 ;
  [encoderOpts, ~] = vl_argparse(encoderOpts, opts.encoderParams{:}) ;
  if opts.lite, encoderOpts.numTrain = 10 ; end
  train = vl_colsubset(find(imdb.images.set <= 2), encoderOpts.numTrain, 'uniform') ;
  encoder = trainEncoder(fullfile(imdb.imageDir,imdb.images.name(train)), ...
                         opts.encoderParams{:}, ...
                         'lite', opts.lite) ;
  save(opts.encoderPath, '-struct', 'encoder', '-v7') ;
  diary off ;
  diary on ;
end


% --------------------------------------------------------------------
%                                       Compute train and test kernels
% --------------------------------------------------------------------

kernelsLoaded = false ;
if ~profilingRun && exist(opts.trnKernelPath(opts.kernel), 'file') && exist(opts.tstKernelPath(opts.kernel), 'file')
  load(opts.trnKernelPath(opts.kernel), 'train', 'Ktrn', 'descrsTime') ;
  load(opts.tstKernelPath(opts.kernel), 'test', 'Ktst', 'descrsTime') ;
  if all(isfinite(Ktrn(:))) && all(isfinite(Ktst(:)))
    kernelsLoaded = true ;
  end
end

if kernelsLoaded
  fprintf('Loaded precomputed kernels from\n  %s\n  %s\n', ...
    opts.trnKernelPath(opts.kernel), opts.tstKernelPath(opts.kernel)) ;
elseif errorIfNoKernel
  error('TRAINTEST:NOKERNEL', 'No precomputed kernels at\n  %s\n  %s\n', ...
    opts.trnKernelPath(opts.kernel), opts.tstKernelPath(opts.kernel)) ;
else
  [descrs,descrsTime] = encodeImage(encoder, fullfile(imdb.imageDir, imdb.images.name), ...
    'cacheDir', opts.cacheDir, 'readOnly', doNotCacheDescriptors, 'profiling', profilingRun) ;
  
  % apply kernel maps
  tWall = tic; tCpu = cputime;
  switch opts.kernel
    case 'linear'
    case 'hell'
      descrs = sign(descrs) .* sqrt(abs(descrs)) ;
    case 'chi2'
      descrs = vl_homkermap(descrs,1,'kchi2') ;
    otherwise
      assert(false) ;
  end
  norm2(descrs);
  descrsTime.wallTimeKerMap = toc(tWall) ;
  descrsTime.cpuTimeKerMap = cputime - tCpu ;

  train = imdb.images.set <= 2 ;
  test = imdb.images.set == 3 ;

  tWall = tic; tCpu = cputime;
  Ktrn = descrs(:,train)' * descrs(:,train);
  descrsTime.wallTimeTrnTrn = toc(tWall) ;
  descrsTime.cpuTimeTrnTrn = cputime - tCpu ;
  Ttrn = descrsTime.cpuTimeTrnTrn ;

  tWall = tic; tCpu = cputime;
  Ktst = descrs(:,train)' * descrs(:,test);
  descrsTime.wallTimeTrnTst = toc(tWall) ;
  descrsTime.cpuTimeTrnTst = cputime - tCpu ;
  Ttst = descrsTime.cpuTimeTrnTst ;

  if all(isfinite(Ktrn(:))) && all(isfinite(Ktst(:)))
    save(opts.trnKernelPath(opts.kernel), 'train', 'Ktrn', 'Ttrn', 'descrsTime') ;
    save(opts.tstKernelPath(opts.kernel), 'test', 'Ktst', 'Ttst', 'descrsTime') ;
  else
    error('TRAINTEST:KERNELINF', 'Some values are Inf or NaN.') ;
  end

  clear descrs Ttrn Ttst;
end

assert( all(isfinite(Ktrn(:))) && all(isfinite(Ktst(:))) ) ;
assert(Ktrn(1) < 2) ; % No bias by default

if kernelOnly
  fprintf('Kernels have been computed.\n') ;
  diary off ;
  return ;
end

if addBias
  Ktrn = Ktrn + 1 ;
  Ktst = Ktst + 1 ;
end

Ytrn = imdb.images.class(train) ;
Ytst = imdb.images.class(test) ;

diary off ;
diary on ;

% --------------------------------------------------------------------
%                                             STL SVM Cross-Validation
% --------------------------------------------------------------------

if isfield(imdb.images, 'class')
  classRange = unique(imdb.images.class) ;
else
  classRange = 1:numel(imdb.classes.imageIds) ;
end
numClasses = numel(classRange) ;

% Select the best C via cross-validation
mACC = NaN ;
if numel(opts.C) > 1
  Kfolds = 2 ;
  fprintf('Model selection...\n') ;
  fprintf('C = %s\n', mat2str(opts.C)) ;
  [Cs, mACCs] = svmtraintest_modelselection(classRange, Ytrn, Ktrn, opts.C, Kfolds) ;
  
  [mACC, ind] = max(mACCs) ;
  C = Cs(ind) ;

  save(opts.modelSelectionPath(opts.kernel), 'C', 'mACC', 'Cs', 'mACCs', 'Kfolds', '-v7') ;
  opts.C = C ;
end

diary off ;
diary on ;


% --------------------------------------------------------------------
%                                               Train and test STL SVM
% --------------------------------------------------------------------

assert(numel(opts.C) == 1) ;

lambda = 1 / (opts.C * size(Ktrn,1)) ;

% train the final model
[A,info,scores,acc,timing] = svmtraintest_onevsall(Ytrn, Ktrn, Ytst, Ktst, lambda) ;

fprintf('\nSTL Model selection (best): accuracy = %g, C = %g (lambda = %g)\n', mACC*100, opts.C, lambda) ;
fprintf('STL Test: accuracy = %g\n', acc*100) ;

% confusion matrix (can be computed only if each image has only one label)
if isfield(imdb.images, 'class')
  [~,preds] = max(scores, [], 1) ;
  confusion = zeros(numClasses) ;
  for c = 1:numClasses
    sel = imdb.images.class(test) == classRange(c) ;
    tmp = accumarray(preds(sel)', 1, [numClasses 1]) ;
    tmp = tmp / max(sum(tmp),1e-10) ;
    confusion(c,:) = tmp(:)' ;
  end
else
  confusion = NaN ;
end

diary off ;
diary on ;

% save results
save(opts.modelPath(opts.kernel, opts.C), 'A', 'info', 'timing', '-v7') ;
save(opts.resultPath(opts.kernel, opts.C), 'info', 'scores', 'acc', 'timing', 'confusion', 'classRange', '-v7') ;

displayResults(confusion) ;

fprintf('\nCompleted experiment: %s\n', sec2str(toc(exStartTime))) ; 
diary off ;
