function mtltraintest(mtlopts, varargin)

profilingRun = false ;

recomputeSTLCVOlder = datenum(2014,4,9) ;
recomputeSTLModelOlder = datenum(2014,4,9) ;
recomputeMTLResultsOlder = datenum(2014,4,9) ;
addBias = false ;

if profilingRun
%   recomputeSTLCVOlder = datenum(2014,4,9) ;
%   recomputeSTLModelOlder = datenum(2014,4,9) ;
  recomputeMTLResultsOlder = datenum(2020,1,1) ;
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
  opts.mtlResultPath = @(kernel,C,ex,C1,C2) fullfile(opts.resultDir, ...
    sprintf('result-K%s-C%e-%s-C%e-C%e.mat', kernel,C,ex,C1,C2));
  opts.mtlModelPath = @(kernel,C,ex,C1,C2) fullfile(opts.resultDir, ...
    sprintf('model-K%s-C%e-%s-C%e-C%e.mat', kernel,C,ex,C1,C2));
  opts = vl_argparse(opts,varargin) ;
end

fprintf('resultDir:\n%s\n', opts.resultDir) ;

% load cross-validated C
opts.C = [] ;
if exist(opts.modelSelectionPath(opts.kernel), 'file')
  fstat = dir(opts.modelSelectionPath(opts.kernel)) ;
  assert(numel(fstat) == 1) ;
  fprintf('Found STL model selection results:\n  name: %s\n  date: %s\n', fstat.name, datestr(fstat.datenum)) ;
  if fstat.datenum >= recomputeSTLCVOlder
    selectedModel = load(opts.modelSelectionPath(opts.kernel), 'C', 'mACC', 'Kfolds') ;
    fprintf('STL SVM Model selected via %d-fold CV: C = %g (mACC = %.2f)\n', ...
      selectedModel.Kfolds, selectedModel.C, 100*selectedModel.mACC) ;
    opts.C = selectedModel.C ;
    mtlopts.C = selectedModel.C ;
  else
    fprintf('..older than %s; ignore.\n', datestr(recomputeSTLCVOlder)) ;
  end
end
if isempty(opts.C)
  error('MTLTRAINTEST:ModelSelection', 'No model selection results.');
end

assert(numel(mtlopts.C) == 1 && numel(mtlopts.C1) == 1 && numel(mtlopts.C2) == 1) ;
assert(opts.C == mtlopts.C && mtlopts.C > 0 && mtlopts.C1 > 0 && mtlopts.C2 >= 0) ;

% do not do anything if the result data already exist
mtlResultPath = opts.mtlResultPath(mtlopts.kernel, mtlopts.C, mtlopts.ex, mtlopts.C1, mtlopts.C2) ;
if exist(mtlResultPath, 'file')
  fstat = dir(mtlResultPath) ;
  assert(numel(fstat) == 1) ;
  fprintf('Found MTL experiment results:\n  name: %s\n  date: %s\n', fstat.name, datestr(fstat.datenum)) ;
  if fstat.datenum >= recomputeMTLResultsOlder
    load(mtlResultPath, 'confusion') ;
    displayResults(confusion) ; %#ok<NODEF>
    diary off ;
    return ;
  else
    fprintf('..older than %s; ignore.', datestr(recomputeMTLResultsOlder)) ;
  end
end

stlA = [] ;
stlModelPath = opts.modelPath(mtlopts.kernel, mtlopts.C) ;
if exist(stlModelPath, 'file')
  fstat = dir(stlModelPath) ;
  assert(numel(fstat) == 1) ;
  fprintf('Found STL model:\n  name: %s\n  date: %s\n', fstat.name, datestr(fstat.datenum)) ;
  if fstat.datenum >= recomputeSTLModelOlder
    stlA = load(stlModelPath, 'A') ;
    stlA = stlA.A ;
  else
    fprintf('..older than %s; ignore.', datestr(recomputeMTLResultsOlder)) ;
  end
end
if isempty(stlA)
  error('MTLTRAINTEST:StlModel', 'No STL model.');
end

exStartTime = tic ;
diary(opts.diaryPath) ; diary on ;
fprintf('\nStarted experiment:\n') ;
disp('options:' ); disp(opts) ;
disp('mtl options:' ); disp(mtlopts) ;
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

if exist(opts.encoderPath, 'file')
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
if exist(opts.trnKernelPath(opts.kernel), 'file') && exist(opts.tstKernelPath(opts.kernel), 'file')
  load(opts.trnKernelPath(opts.kernel), 'train', 'Ktrn') ;
  load(opts.tstKernelPath(opts.kernel), 'test', 'Ktst') ;
  if all(isfinite(Ktrn(:))) && all(isfinite(Ktst(:)))
    kernelsLoaded = true ;
  end
end

if kernelsLoaded
  fprintf('Loaded precomputed kernels from\n  %s\n  %s\n', ...
    opts.trnKernelPath(opts.kernel), opts.tstKernelPath(opts.kernel)) ;
else
  error('MTLTRAINTEST:NOKERNEL', 'No precomputed kernels at\n  %s\n  %s\n', ...
    opts.trnKernelPath(opts.kernel), opts.tstKernelPath(opts.kernel)) ;
end

assert( all(isfinite(Ktrn(:))) && all(isfinite(Ktst(:))) ) ;
assert(Ktrn(1) < 2) ; % No bias by default

if addBias
  Ktrn = Ktrn + 1 ;
  Ktst = Ktst + 1 ;
end

Ytrn = imdb.images.class(train) ;
Ytst = imdb.images.class(test) ;

% Z = U0' * X, U0 = W_stl = X * A_stl, KZ = Z' * Z
tWall = tic; tCpu = cputime;
Ztrn = stlA' * Ktrn ;
wallTimeZ = toc(tWall); cpuTimeZ = cputime - tCpu;

tWall = tic; tCpu = cputime;
KZtrn = Ztrn' * Ztrn ;
wallTimeZTrnTrn = toc(tWall); cpuTimeZTrnTrn = cputime - tCpu;

tWall = tic; tCpu = cputime;
KZtst = Ztrn' * (stlA' * Ktst) ;
wallTimeZTrnTst = toc(tWall); cpuTimeZTrnTst = cputime - tCpu;

clear Ztrn ;

diary off ;
diary on ;

if isfield(imdb.images, 'class')
  classRange = unique(imdb.images.class) ;
else
  classRange = 1:numel(imdb.classes.imageIds) ;
end
numClasses = numel(classRange) ;

% --------------------------------------------------------------------
%                                                   Train and test MTL
% --------------------------------------------------------------------

lambda = 1 / (mtlopts.C1 * size(Ktrn,1)) ;
mu = 1 / (mtlopts.C2 * size(Ktrn,1) * numClasses) ;

Kw = [] ;
if strfind(mtlopts.ex, 'S')
  % Stacked SVMs - train second layer SVM on top of the first layer scores = Z
  [A,info,scores,acc,timing] = svmtraintest_onevsall(Ytrn, KZtrn, Ytst, KZtst, lambda) ;
elseif strfind(mtlopts.ex, 'M')
  % Stacked SVMs - train second layer SVM on top of the first layer scores = Z
  [A,Kw,info,scores,acc,timing] = mtltraintest_onevsall(Ytrn, Ktrn, KZtrn, Ytst, Ktst, lambda, mu) ;
else
  assert(false) ;
end

fprintf('\nSTL parameters: C = %g (lambda = %g)\n', mtlopts.C, 1/(mtlopts.C*size(Ktrn,1))) ;
fprintf('\nMTL parameters: C1 = %g (lambda = %g), C2 = %g (mu = %g) \n', mtlopts.C1, lambda, mtlopts.C2,  mu) ;
fprintf('MTL Test: accuracy = %g\n', acc*100) ;

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

timing.wallTimeZ = wallTimeZ ;
timing.cpuTimeZ = cpuTimeZ ;
timing.wallTimeZTrnTrn = wallTimeZTrnTrn ;
timing.cpuTimeZTrnTrn = cpuTimeZTrnTrn ;
timing.wallTimeZTrnTst = wallTimeZTrnTst ;
timing.cpuTimeZTrnTst = cpuTimeZTrnTst ;

% save results
save(opts.mtlModelPath(mtlopts.kernel, mtlopts.C, mtlopts.ex, mtlopts.C1, mtlopts.C2), ...
  'A', 'Kw', 'info', 'timing', '-v7') ;
save(opts.mtlResultPath(mtlopts.kernel, mtlopts.C, mtlopts.ex, mtlopts.C1, mtlopts.C2), ...
  'info', 'scores', 'acc', 'timing', 'confusion', 'classRange', '-v7') ;

displayResults(confusion) ;

fprintf('\nCompleted experiment: %s\n', sec2str(toc(exStartTime))) ; 
diary off ;
