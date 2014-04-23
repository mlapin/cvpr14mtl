function [descrs,descrsTime] = encodeImage(encoder, im, varargin)
% ENCODEIMAGE   Apply an encoder to an image
%   DESCRS = ENCODEIMAGE(ENCODER, IM) applies the ENCODER
%   to image IM, returning a corresponding code vector PSI.
%
%   IM can be an image, the path to an image, or a cell array of
%   the same, to operate on multiple images.
%
%   ENCODEIMAGE(ENCODER, IM, CACHE) utilizes the specified CACHE
%   directory to store encodings for the given images. The cache
%   is used only if the images are specified as file names.
%
%   See also: TRAINENCODER().

% Author: Andrea Vedaldi

% Copyright (C) 2013 Andrea Vedaldi
% All rights reserved.
%
% This file is part of the VLFeat library and is made available under
% the terms of the BSD license (see the COPYING file).

wallTimeStart = tic ;
cpuTimeStart = cputime ;
descrsTime.wallTimeIO = 0 ;
descrsTime.cpuTimeIO = 0 ;
descrsTime.wallTimeExtract = 0 ;
descrsTime.cpuTimeExtract = 0 ;
descrsTime.wallTimeEncode = 0 ;
descrsTime.cpuTimeEncode = 0 ;

opts.cacheDir = [] ;
opts.cacheChunkSize = 512 ;
opts.subset = [] ;
opts.biasMultiplier = [] ;
opts.readOnly = false ;
opts.profiling = false ;
opts = vl_argparse(opts,varargin) ;

if ~iscell(im), im = {im} ; end
if isempty(opts.subset)
  opts.subset = 1:numel(im) ;
elseif islogical(opts.subset)
  opts.subset = find(opts.subset) ;
end

% break the computation into cached chunks
startTime = tic ;
descrs = [];
numChunks = ceil(numel(im) / opts.cacheChunkSize) ;

for c = 1:numChunks
  sInd = (c-1) * opts.cacheChunkSize + 1 ;
  eInd = sInd + opts.cacheChunkSize - 1 ;
  chunkInd = intersect(sInd:eInd, opts.subset) ;
  if isempty(chunkInd), continue; end
  n  = min(opts.cacheChunkSize, numel(im) - (c-1)*opts.cacheChunkSize) ;
  chunkPath = fullfile(opts.cacheDir, sprintf('chunk-%03d.mat',c)) ;
  isLoaded = false ;
  if ~opts.profiling
    try
      clear data ;
      load(chunkPath, 'data') ;
      if all(isfinite(data(:)))
        isLoaded = true ;
        fprintf('%s: loaded descriptors from %s\n', mfilename, chunkPath) ;
      end
    catch
      if exist(chunkPath, 'file')
        fprintf('%s: failed to load: %s\n', mfilename, chunkPath) ;
        try
          delete(chunkPath) ;
        catch
          fprintf('%s: failed to delete corrupted chunk: %s\n', mfilename, chunkPath) ;
        end
      end
    end
  end
  if ~isLoaded || ~exist('data', 'var')
    range = (c-1)*opts.cacheChunkSize + (1:n) ;
    fprintf('%s: processing a chunk of %d images (%3d of %3d, %5.1fs to go)\n', ...
      mfilename, numel(range), ...
      c, numChunks, toc(startTime) / (c - 1) * (numChunks - c + 1)) ;
    [data,descrsTime] = processChunk(encoder, im(range), descrsTime) ;
    if ~isempty(opts.cacheDir) && ~opts.readOnly
      try
        save(chunkPath, 'data', '-v7') ;
      catch
        fprintf('%s: failed to save: %s\n', mfilename, chunkPath) ;
      end
    end
  end
  if isempty(descrs)
    if isempty(opts.biasMultiplier)
      descrs = nan(size(data,1), numel(opts.subset), class(data)) ;
    else
      descrs = nan(size(data,1) + 1, numel(opts.subset), class(data)) ;
      descrs(end,:) = opts.biasMultiplier ;
    end
    lastInd = 0 ;
  end
  eInd = sInd + size(data, 2) - 1 ; % possibly make it smaller (last chunk)
  chunkInd = intersect(sInd:eInd, chunkInd) ;
  descrs(1:size(data,1),(lastInd+1):(lastInd+numel(chunkInd))) = data(:,chunkInd-sInd+1);
  lastInd = lastInd + numel(chunkInd) ;
  clear data sInd eInd chunkInd;
end
clear lastInd ;
%descrs = cat(2,descrs{:}) ;
if ~all(isfinite(descrs(:)))
  error('ENCODEIMAGE:InfNaN', 'Some values are Inf or NaN.');
end

descrsTime.wallTime = toc(wallTimeStart) ;
descrsTime.cpuTime = cputime - cpuTimeStart ;
descrsTime.numImages = size(descrs, 2) ;


% --------------------------------------------------------------------
function [psi,descrsTime] = processChunk(encoder, im, descrsTime)
% --------------------------------------------------------------------
psi = cell(1,numel(im)) ;
if numel(im) > 1 && exist('matlabpool', 'file') && matlabpool('size') > 1
  parfor i = 1:numel(im)
    psi{i} = encodeOne(encoder, im{i}, descrsTime) ;
  end
else
  % avoiding parfor makes debugging easier
  for i = 1:numel(im)
    [psi{i},descrsTime] = encodeOne(encoder, im{i}, descrsTime) ;
  end
end
psi = cat(2, psi{:}) ;

% --------------------------------------------------------------------
function [psi,descrsTime] = encodeOne(encoder, im, descrsTime)
% --------------------------------------------------------------------

tWall = tic; tCpu = cputime;
im = encoder.readImageFn(im) ;
descrsTime.wallTimeIO = descrsTime.wallTimeIO + toc(tWall) ;
descrsTime.cpuTimeIO = descrsTime.cpuTimeIO + cputime - tCpu ;

tWall = tic; tCpu = cputime;
features = encoder.extractorFn(im) ;
descrsTime.wallTimeExtract = descrsTime.wallTimeExtract + toc(tWall) ;
descrsTime.cpuTimeExtract = descrsTime.cpuTimeExtract + cputime - tCpu ;

tWall = tic; tCpu = cputime;
imageSize = size(im) ;
psi = {} ;
for i = 1:size(encoder.subdivisions,2)
  minx = encoder.subdivisions(1,i) * imageSize(2) ;
  miny = encoder.subdivisions(2,i) * imageSize(1) ;
  maxx = encoder.subdivisions(3,i) * imageSize(2) ;
  maxy = encoder.subdivisions(4,i) * imageSize(1) ;

  ok = ...
    minx <= features.frame(1,:) & features.frame(1,:) < maxx  & ...
    miny <= features.frame(2,:) & features.frame(2,:) < maxy ;

  descrs = encoder.projection * bsxfun(@minus, ...
                                       features.descr(:,ok), ...
                                       encoder.projectionCenter) ;
  if encoder.renormalize
    descrs = bsxfun(@times, descrs, 1./max(1e-12, sqrt(sum(descrs.^2)))) ;
  end

  w = size(im,2) ;
  h = size(im,1) ;
  frames = features.frame(1:2,:) ;
  frames = bsxfun(@times, bsxfun(@minus, frames, [w;h]/2), 1./[w;h]) ;

  descrs = extendDescriptorsWithGeometry(encoder.geometricExtension, frames, descrs) ;

  switch encoder.type
    case 'bovw'
      [words,distances] = vl_kdtreequery(encoder.kdtree, encoder.words, ...
                                         descrs, ...
                                         'MaxComparisons', 100) ;
      z = vl_binsum(zeros(encoder.numWords,1), 1, double(words)) ;
      z = sqrt(z) ;

    case 'fv'
      fvOpts = {} ;
      if encoder.opts.fvSquareRoot, fvOpts{end+1} = 'SquareRoot' ; end %#ok<*AGROW>
      if encoder.opts.fvNormalized, fvOpts{end+1} = 'Normalized' ; end
      if encoder.opts.fvImproved, fvOpts{end+1} = 'Improved' ; end
      z = vl_fisher(descrs, ...
                    encoder.means, ...
                    encoder.covariances, ...
                    encoder.priors, ...
                    fvOpts{:}) ;
      clear fvOpts ;
    case 'vlad'
      vOpts = {} ;
      if encoder.opts.vladUnnormalized, vOpts{end+1} = 'Unnormalized' ; end
      if encoder.opts.vladNormalizeComponents, vOpts{end+1} = 'NormalizeComponents' ; end
      if encoder.opts.vladNormalizeMass, vOpts{end+1} = 'NormalizeMass' ; end
      if encoder.opts.vladSquareRoot, vOpts{end+1} = 'SquareRoot' ; end
      [words,distances] = vl_kdtreequery(encoder.kdtree, encoder.words, ...
                                         descrs, ...
                                         'MaxComparisons', 15) ;
      assign = zeros(encoder.numWords, numel(words), 'single') ;
      assign(sub2ind(size(assign), double(words), 1:numel(words))) = 1 ;
      z = vl_vlad(descrs, ...
                  encoder.words, ...
                  assign, ...
                  vOpts{:}) ;
      clear vOpts ;
  end
  z = z / max(sqrt(sum(z.^2)), 1e-12) ;
  psi{i} = z(:) ;
end
psi = cat(1, psi{:}) ;
descrsTime.wallTimeEncode = descrsTime.wallTimeEncode + toc(tWall) ;
descrsTime.cpuTimeEncode = descrsTime.cpuTimeEncode + cputime - tCpu ;

% --------------------------------------------------------------------
function psi = getFromCache(name, cache)
% --------------------------------------------------------------------
[drop, name] = fileparts(name) ;
cachePath = fullfile(cache, [name '.mat']) ;
if exist(cachePath, 'file')
  data = load(cachePath) ;
  psi = data.psi ;
else
  psi = [] ;
end

% --------------------------------------------------------------------
function storeToCache(name, cache, psi)
% --------------------------------------------------------------------
[drop, name] = fileparts(name) ;
cachePath = fullfile(cache, [name '.mat']) ;
vl_xmkdir(cache) ;
data.psi = psi ;
save(cachePath, '-STRUCT', 'data', '-v7') ;
