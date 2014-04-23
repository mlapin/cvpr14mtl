function features = getLCS(im, frames, binSize, normComponents, normAll, squareRoot)
%GETLCS Extract Local Color Statistics feature
%   FEATURES = GETLCS(IM, FRAMES, BINSIZE) extract LCS features from
%   image IM around frame centers FRAMES with 4x4 bins of size BINSIZE.
%
%   FEATURES = GETLCS(IM, FRAMES, BINSIZE, NORMCOMPONENTS, NORMALL)
%   If NORMCOMPONENTS is true, normalize features per component,
%   i.e. every 16 dimensions are square L2 normalized.
%   If NORMALL is true, normalize the full feature vector, i.e. 96 dimensions.
%

if size(im,3) ~= 3 && size(im,3) ~= 1
  error('GETLCS:NumberOfChannels', ...
    'Unexpected number of color channels: %d', size(im,3));
end

if nargin < 4, normComponents = false; end
if nargin < 5, normAll = false; end
if nargin < 6, squareRoot = false; end

% 4x4 grid around the frame center
binOffsets = ((-1.5:1.5)' .* binSize) * ones(1,4);

% Convolution filter to compute means at each bin
binSize = round(binSize);
meanFilter = ones(binSize) / binSize / binSize;

% Indices of all bin centers (16 x numel(frames))
binIndX = uint32(floor(bsxfun(@plus, frames(1,:), binOffsets(:))));
binOffsets = binOffsets';
binIndY = uint32(floor(bsxfun(@plus, frames(2,:), binOffsets(:))));
try
  binInd = sub2ind(size(im), binIndY(:), binIndX(:));
catch me
  disp(me);
end
clear binOffsets binIndX binIndY;

features = zeros(96, size(frames,2), 'single');
for channel = 1:size(im,3)
  im_ = im(:,:,channel);
  
  % Mean
  M = conv2(im_, meanFilter, 'same');
  ind = 32*(channel-1)+1 : 32*(channel-1)+16;
  features(ind,:) = reshape(M(binInd), 16, size(frames,2));
  if normComponents, features(ind,:) = snorm(features(ind,:)); end
  
  % Standard deviation
  im_ = (im_ - M).^2;
  M = sqrt(conv2(im_, meanFilter, 'same'));
  ind = 32*(channel-1)+17 : 32*(channel-1)+32;
  features(ind,:) = reshape(M(binInd), 16, size(frames,2));
  if squareRoot, features(ind,:) = sqrt(features(ind,:)); end
  if normComponents, features(ind,:) = snorm(features(ind,:)); end
end
clear im_ M ind binInd meanFilter;

% Replicate features from the first channel
if size(im,3) == 1
  features(33:64,:) = features(1:32,:);
  features(65:96,:) = features(1:32,:);
end

if normAll, features = snorm(features); end

function x = snorm(x)
x = bsxfun(@times, x, 1./max(1e-5,sqrt(sum(x.^2,1)))) ;
