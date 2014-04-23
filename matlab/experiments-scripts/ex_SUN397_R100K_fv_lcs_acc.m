%
% Experiment script
%   (based on the apps/recognition/experiments.m from the VLFeat 0.9.17)
%

% If true, only a small fraction of the dataset is used.
lite = false;

% Default parameters:
Splits = 1;               % training split
Kernel = 'linear';        % SVM kernel
Ntrn = [5 10 20 50] ;     % training sample size(s)
C = 10.^(-3:3);           % SVM C (if multiple values are given,
                          %        the best is chosen by cross-validation)
numWords = 256;           % vocabulary size


% Override the default parameters as needed:
if lite
  Ntrn = 5;
  tag = 'lite';
else
  tag = 'ex';
end
if length(varargin) >= 1
  Splits = todouble(varargin{1});
end
if length(varargin) >= 2
  Kernel = varargin{2};
end
if length(varargin) >= 3
  Ntrn = todouble(varargin{3});
end
if length(varargin) >= 4
  C = todouble(varargin{4});
end

% Experiment template:
ex(1).prefix = '';
ex(1).trainOpts = {};
ex(1).datasets = {'SUN397-R100K'};
ex(1).seed = 1;
ex(1).opts = {...
  'type', 'fv', ...
  'numWords', numWords, ...
  'numTrain', Inf, ...
  'numPcaDimensions', 128, ...
  'whitening', false, ...
  'whiteningRegul', 0, ...
  'numSamplesPerWord', ceil(1e6/numWords), ...
  'renormalize', false, ...
  'fvSquareRoot', false, ...
  'fvNormalized', false, ...
  'fvImproved', true, ...
  'vladUnnormalized', false, ...
  'vladNormalizeComponents', true, ...
  'vladNormalizeMass', false, ...
  'vladSquareRoot', true, ...
  'layouts', {'1x1', '3x1'}, ...
  'geometricExtension', 'none', ...
  'lite', lite, ...
  'extractorFn', @(x) getDenseSIFT(x, ...
                                   'step', 4, ...
                                   'rootSift', true, ...
                                   'addLcs', true, ...
                                   'lcsNormalizeComponents', true, ...
                                   'lcsNormalizeAll', true, ...
                                   'scales', 2.^(0:-.5:-2), ...
                                   'binSize', 6)};

% Create copies for each split and sample size
for i = 1:numel(Splits)
  for j = 1:numel(Ntrn)
    ind = numel(Ntrn)*(i-1) + j;
    ex(ind) = ex(1);
    ex(ind).prefix = sprintf('S%02d-T%02d', Splits(i), Ntrn(j));
    ex(ind).trainOpts = {'C', C, 'numTrain', Ntrn(j), 'kernel', Kernel, 'perfMeasure', 'accuracy'};
    ex(ind).seed = Splits(i);
  end
end
clear ind;

% Run the experiments
for i=1:numel(ex)
  for j=1:numel(ex(i).datasets)
    dataset = ex(i).datasets{j};
    if ~isfield(ex(i), 'trainOpts') || ~iscell(ex(i).trainOpts)
      ex(i).trainOpts = {};
    end
    traintest(...
      'prefix', [tag '-' dataset '-' ex(i).prefix], ...
      'seed', ex(i).seed, ...
      'dataset', char(dataset), ...
      'datasetDir', fullfile('data', dataset), ...
      'lite', lite, ...
      ex(i).trainOpts{:}, ...
      'encoderParams', ex(i).opts);
  end
end
