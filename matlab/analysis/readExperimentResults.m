function results = readExperimentResults(directory)

if nargin < 1
  directory = 'experiments';
end

results = [];
results = readDirectory(directory, results);


function results = readDirectory(directory, results)

if ~exist(directory, 'dir') || ~isempty(strfind(directory, 'lite'))
  return
end

ignoreOlder = datenum(2014,4,9);

disp(directory);
descFile = fullfile(directory, '.description');
if exist(descFile, 'file')
  desc = seval(descFile);
  if desc.lite
    return
  end

  desc.opts = parseEncoderOptions(desc.encoderParams{:});
  modsel = readModelSelection(directory, 'accuracy');
  kertime = readKernelTimings(directory);
  f = dir(fullfile(directory, 'result-K*-C*.mat'));
  for i = 1:numel(f)
    if f(i).datenum > ignoreOlder
      results = readFile(...
        fullfile(directory, f(i).name), desc, modsel, kertime, results);
    end
  end
else
  d = dir(directory);
  dirs = {d([d(:).isdir]).name};
  for i = 1:numel(dirs)
    if ~ismember(dirs{i}, {'.', '..'})
      results = readDirectory(fullfile(directory, dirs{i}), results);
    end
  end
end

function results = readFile(fname, desc, modsel, kertime, results)

% Sorting fun with Matlab:
%   cannot use empty: []
%   cannot use empty string: '' (somehow it gets converted to [] during sorting)
%   cannot use logical: it is not numeric, hence, is expected to be a string
%     (sortrows works on either numeric or char)

result.fname = fname;
result.seed = desc.seed;
result.numTrain = desc.numTrain;

% Feature options
result.encoder = desc.opts.type;
result.pcaDim = desc.opts.numPcaDimensions;
result.pcaBlockwise = 0;
result.pcaBlocks = [];
if isfield(desc.opts, 'pcaBlockDimensions') && ~isempty(desc.opts.pcaBlockDimensions)
  result.pcaBlockwise = 1;
  result.pcaBlocks = desc.opts.pcaBlockDimensions;
end

extractorFn = func2str(desc.opts.extractorFn);

result.dsift = 0;
result.dsiftRoot = 0;
if ~isempty(strfind(extractorFn, 'getDenseSIFT'))
  result.dsift = 1;
  if ~isempty(strfind(extractorFn, '''rootSift'',true'))
    result.dsiftRoot = 1;
  end
end

result.lcs = 0;
result.lcsRoot = 0;
result.lcsNormComp = 0;
result.lcsNormAll = 0;
if ~isempty(strfind(extractorFn, '''addLcs'',true'))
  result.lcs = 1;
  if ~isempty(strfind(extractorFn, '''lcsSquareRoot'',true'))
    result.lcsRoot = 1;
  end
  if ~isempty(strfind(extractorFn, '''lcsNormalizeComponents'',true'))
    result.lcsNormComp = 1;
  end
  if ~isempty(strfind(extractorFn, '''lcsNormalizeAll'',true'))
    result.lcsNormAll = 1;
  end
end

% Model options
kernelC = strsplit(regexprep(fname, ...
  '^.*result-K([a-zA-Z0-9]+)-C([0-9\.]+e[\+\-][0-9]+)-?(.*)\.mat$', '$1 $2 $3'));
result.kernel = kernelC{1};
result.C = todouble(kernelC{2});
result.mtl = double(~isempty(kernelC{3}));

result.mAcc_C = -1;
if isfield(modsel, result.kernel)
  result.mAcc_C = modsel.(result.kernel).C;
end

% Kernel timings
result.KTtrn = NaN;
result.KTtst = NaN;
if isfield(kertime, result.kernel)
  if isfield(kertime.(result.kernel), 'Ttrn')
    result.KTtrn = kertime.(result.kernel).Ttrn;
  end
  if isfield(kertime.(result.kernel), 'Ttst')
    result.KTtst = kertime.(result.kernel).Ttst;
  end
end

  
% Evaluation results
data = load(fname, 'info', 'confusion');
result.info = data.info;
result.mAcc = mean(diag(data.confusion)) * 100;
clear data;

% MTL options
result.mtl_ex = '_none';
result.mtl_C1 = -1;
result.mtl_C2 = -1;
if result.mtl
  mtlparams = strsplit(regexprep(kernelC{3}, ...
    '^([a-zA-Z0-9]+)-C([0-9\.]+e[\+\-][0-9]+)-C([0-9\.]+e[\+\-][0-9]+)$', '$1 $2 $3'));
  result.mtl_ex = mtlparams{1};
  result.mtl_C1 = todouble(mtlparams{2});
  result.mtl_C2 = todouble(mtlparams{3});
end

if isempty(results)
  results = result;
else
  results(end+1) = result;
end


function [modsel] = readModelSelection(directory, perfMeasure)
modsel = struct();
f = dir(fullfile(directory, sprintf('model-selection-%s-K*.mat', perfMeasure)));
for i = 1:numel(f)
  kernel = regexprep(f(i).name, ...
    sprintf('^.*model-selection-%s-K([a-zA-Z0-9]+)\\.mat$', perfMeasure), '$1');
  if ~isempty(kernel)
    try
      data = load(fullfile(directory, f(i).name), 'C');
    catch
      fprintf('Failed to load: %s\n', fullfile(directory, f(i).name));
    end
    modsel.(kernel).C = data.C;
    clear data;
  end
end

function [kertime] = readKernelTimings(directory)
kertime = struct();
f = dir(fullfile(directory, 'result-K*-nobias.mat'));
for i = 1:numel(f)
  kernel = regexprep(f(i).name, '^.*result-K([a-zA-Z0-9]+)-t[rnst]*-nobias\.mat$', '$1');
  if ~isempty(kernel)
    if strfind(f(i).name, '-trn-')
      data = load(fullfile(directory, f(i).name), 'Ttrn');
      kertime.(kernel).Ttrn = data.Ttrn;
      clear data;
    elseif strfind(f(i).name, '-tst-')
      data = load(fullfile(directory, f(i).name), 'Ttst');
      kertime.(kernel).Ttst = data.Ttst;
      clear data;
    else
      fprintf('Unexpected kernel file name: %s\n', fullfile(directory, f(i).name));
    end
  end
end

function [opts] = parseEncoderOptions(varargin)
opts.type = 'bovw' ;
opts.numWords = [] ;
opts.numTrain = [] ;
opts.seed = 1 ;
opts.numPcaDimensions = +inf ;
opts.pcaBlockDimensions = [] ;
opts.whitening = false ;
opts.whiteningRegul = 0 ;
opts.numSamplesPerWord = [] ;
opts.renormalize = false ;
opts.fvSquareRoot = false ;
opts.fvNormalized = false ;
opts.fvImproved = true ;
opts.vladUnnormalized = false ;
opts.vladNormalizeComponents = true ;
opts.vladNormalizeMass = false ;
opts.vladSquareRoot = true ;
opts.layouts = {'1x1'} ;
opts.geometricExtension = 'none' ;
opts.subdivisions = zeros(4,0) ;
opts.readImageFn = @readImage ;
opts.extractorFn = @getDenseSIFT ;
opts.lite = false ;
opts = vl_argparse(opts, varargin) ;
