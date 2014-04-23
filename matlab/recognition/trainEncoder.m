function encoder = trainEncoder(images, varargin)
% TRAINENCODER   Train image encoder: BoVW, VLAD, FV
%   ENCODER = TRAINENCOER(IMAGES) trains a BoVW encoder from the
%   specified list of images IMAGES.
%
%   TRAINENCODER(..., 'OPT', VAL, ...) accepts the following options:
%
%   Type:: 'bovw'
%     Bag of visual words ('bovw'), VLAD ('vlad') or Fisher Vector
%     ('fv').
%
%   numPcaDimension:: +inf
%     Use PCA to reduce the descriptor dimensionality to this
%     dimension. Use +inf to deactivate PCA.
%
%   Whitening:: false
%     Set to true to divide the principal components by the
%     corresponding standard deviation s_i.
%
%   WhiteningRegul:: 0
%     When using whitening, divide by s_max * WhiteningRegul + s_i
%     instead of s_i alone.
%
%   Renormalize:: false
%     If true, descriptors are L2 normalized after PCA or
%     whitening.
%
%
%   Subdivisions:: []
%     A list of spatial subdivisions. Each column is a rectangle
%     [XMIN YMIN XMAX YMAX]. The spatial subdivisions are
%
%   Layouts:: {'1x1'}
%     A list of strings representing regular spatial subdivisions
%     in the format MxN, where M is the number of vertical
%     subdivisions and N the number of horizontal ones. For
%     example {'1x1', 2x2'} uses 5 partitions: the whole image and
%     four quadrants. The subdivisions are appended to the ones
%     specified by the SUBDIVISIONS option.
%
%   ReadImageFn:: @readImage
%     The function used to load an image.
%
%   ExtractorFn:: @getDenseSIFT
%     The function used to extract the feature frames and
%     descriptors from an image.

% Author: Andrea Vedaldi

% Copyright (C) 2013 Andrea Vedaldi
% All rights reserved.
%
% This file is part of the VLFeat library and is made available under
% the terms of the BSD license (see the COPYING file).

wallTimeStart = tic ;
cpuTimeStart = cputime ;
wallTimeIO = 0 ;
cpuTimeIO = 0 ;
wallTimePca = 0 ;
cpuTimePca = 0 ;
wallTimeExtract = 0 ;
cpuTimeExtract = 0 ;
wallTimeVocab = 0 ;
cpuTimeVocab = 0 ;

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

for i = 1:numel(opts.layouts)
  t = sscanf(opts.layouts{i},'%dx%d') ;
  m = t(1) ;
  n = t(2) ;
  [x,y] = meshgrid(...
    linspace(0,1,n+1), ...
    linspace(0,1,m+1)) ;
  x1 = x(1:end-1,1:end-1) ;
  y1 = y(1:end-1,1:end-1) ;
  x2 = x(2:end,2:end) ;
  y2 = y(2:end,2:end) ;
  opts.subdivisions = cat(2, opts.subdivisions, ...
    [x1(:)' ;
     y1(:)' ;
     x2(:)' ;
     y2(:)'] ) ;
  clear x y x1 y1 x2 y2 t m n;
end

if isempty(opts.numWords)
    switch opts.type
      case {'bovw'}
        opts.numWords = 1024 ;
      case {'fv'}
        opts.numWords = 64 ;
        opts.numPcaDimensions = 80 ;
      case {'vlad'}
        opts.numWords = 64 ;
        opts.numPcaDimensions = 100 ;
        opts.whitening = true ;
        opts.whiteninRegul = 0.01 ;
      otherwise
        assert(false) ;
    end
end

if isempty(opts.numSamplesPerWord)
    switch opts.type
      case {'bovw'}
        opts.numSamplesPerWord = 200 ;
      case {'vlad','fv'}
        opts.numSamplesPerWord = 1000 ;
      otherwise
        assert(false) ;
    end
    if opts.lite
      opts.numSamplesPerWord = 10 ;
    end
end

disp(opts) ;

encoder.opts = opts ;
encoder.type = opts.type ;
encoder.subdivisions = opts.subdivisions ;
encoder.readImageFn = opts.readImageFn ;
encoder.extractorFn = opts.extractorFn ;
encoder.numWords = opts.numWords ;
encoder.renormalize = opts.renormalize ;
encoder.geometricExtension = opts.geometricExtension ;

%% Step 0: obtain sample image descriptors
numImages = numel(images) ;
numDescrsPerImage = ceil(opts.numWords * opts.numSamplesPerWord / numImages) ;
for i = 1:numImages
  fprintf('%s: reading: %s\n', mfilename, images{i}) ;
  tWall = tic; tCpu = cputime;
  im = encoder.readImageFn(images{i}) ;
  wallTimeIO = wallTimeIO + toc(tWall); cpuTimeIO = cpuTimeIO + cputime - tCpu;
  w = size(im,2) ;
  h = size(im,1) ;
  tWall = tic; tCpu = cputime;
  features = encoder.extractorFn(im) ;
  wallTimeExtract = wallTimeExtract + toc(tWall); cpuTimeExtract = cpuTimeExtract + cputime - tCpu;
  randn('state',0) ;
  rand('state',0) ;
  sel = vl_colsubset(1:size(features.descr,2), single(numDescrsPerImage)) ;
  descrs{i} = features.descr(:,sel) ;
  frames{i} = features.frame(:,sel) ;
  frames{i} = bsxfun(@times, bsxfun(@minus, frames{i}(1:2,:), [w;h]/2), 1./[w;h]) ;
end
clear im w h features sel ;
descrs = cat(2, descrs{:}) ;
frames = cat(2, frames{:}) ;

fprintf('%s: sampled %d image descriptors\n', mfilename, size(descrs, 2)) ;

%% Step 1 (optional): learn PCA projection
tWall = tic; tCpu = cputime;
if opts.numPcaDimensions < inf || opts.whitening
  fprintf('%s: learning PCA rotation/projection\n', mfilename) ;
  encoder.projectionCenter = mean(descrs,2) ;
  % PCA per block
  blockDimensions = opts.pcaBlockDimensions ;
  if isempty(blockDimensions)
    blockDimensions = size(descrs,1) ;
  end
  if blockDimensions(end) < size(descrs,1)
    blockDimensions(end+1) = size(descrs,1) ;
  end
  ix = 0 ;
  for bi = 1:numel(blockDimensions)
    ix = ix(end)+1:blockDimensions(bi) ;
    x = bsxfun(@minus, descrs(ix,:), encoder.projectionCenter(ix)) ;
    X = x*x' / size(x,2) ;
    clear x ;
    [V,D] = eig(X) ;
    d = diag(D) ;
    [d,perm] = sort(d,'descend') ;
    d = d + opts.whiteningRegul * max(d) ;
    m = min(opts.numPcaDimensions, numel(ix)) ;
    V = V(:,perm) ;
    if opts.whitening
      encoder.projection{bi} = diag(1./sqrt(d(1:m))) * V(:,1:m)' ;
    else
      encoder.projection{bi} = V(:,1:m)' ;
    end
    clear V D d ;
  end
  clear ix x X V D d perm bi ;
  encoder.projection = blkdiag(encoder.projection{:}) ;
else
  encoder.projection = 1 ;
  encoder.projectionCenter = 0 ;
end
descrs = encoder.projection * bsxfun(@minus, descrs, encoder.projectionCenter) ;
if encoder.renormalize
  descrs = bsxfun(@times, descrs, 1./max(1e-12, sqrt(sum(descrs.^2)))) ;
end
wallTimePca = wallTimePca + toc(tWall); cpuTimePca = cpuTimePca + cputime - tCpu;

%% Step 2 (optional): geometrically augment the features

descrs = extendDescriptorsWithGeometry(opts.geometricExtension, frames, descrs) ;

%% Step 3: learn a VQ or GMM vocabulary
tWall = tic; tCpu = cputime;
%dimension = size(descrs,1) ;
%numDescriptors = size(descrs,2) ;

switch encoder.type
  case {'bovw', 'vlad'}
    fprintf('%s: learning a VQ vocabulary\n', mfilename) ;
    vl_twister('state', opts.seed) ;
    if exist('yael_kmeans', 'file')
      encoder.words = yael_kmeans(...
        descrs, opts.numWords, 'seed', opts.seed, 'niter', 50) ;
    else
      encoder.words = vl_kmeans(...
        descrs, opts.numWords, 'verbose', 'algorithm', 'elkan') ;
    end
    encoder.kdtree = vl_kdtreebuild(encoder.words, 'numTrees', 2) ;

  case {'fv'} ;
    fprintf('%s: learning a GMM vocabulary\n', mfilename) ;
    vl_twister('state', opts.seed) ;
    if 1
      v = var(descrs')' ;
      [encoder.means, encoder.covariances, encoder.priors] = ...
          vl_gmm(descrs, opts.numWords, 'verbose', ...
                 'Initialization', 'kmeans', ...
                 'CovarianceBound', double(max(v)*0.0001), ...
                 'NumRepetitions', 1) ;
    else
      %addpath lib/yael/matlab
      [a,b,c] = ...
          yael_gmm(descrs, opts.numWords, 'verbose', 2) ;
      encoder.priors = single(a) ;
      encoder.means = single(b) ;
      encoder.covariances = single(c) ;
    end
end
wallTimeVocab = wallTimeVocab + toc(tWall); cpuTimeVocab = cpuTimeVocab + cputime - tCpu;

encoder.wallTime = toc(wallTimeStart) ;
encoder.cpuTime = cputime - cpuTimeStart ;
encoder.wallTimeIO = wallTimeIO ;
encoder.cpuTimeIO = cpuTimeIO ;
encoder.wallTimePca = wallTimePca ;
encoder.cpuTimePca = cpuTimePca ;
encoder.wallTimeExtract = wallTimeExtract ;
encoder.cpuTimeExtract = cpuTimeExtract ;
encoder.wallTimeVocab = wallTimeVocab ;
encoder.cpuTimeVocab = cpuTimeVocab ;
encoder.numImages = numImages ;

