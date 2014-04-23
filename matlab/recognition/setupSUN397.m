function imdb = setupSUN397(datasetDir, varargin)
% SETUPSUN397    Setup SUN 297 Dataset

opts.lite = false ;
opts.seed = 1 ;
opts.numTrain = 50 ;
opts.numVal = 0 ;
opts.numTest = 50 ;
opts.autoDownload = false ;
opts.splitsFile = '' ;
opts.expectedNumClasses = 397 ;
opts = vl_argparse(opts, varargin) ;

vl_xmkdir(datasetDir) ;
if exist(fullfile(datasetDir, 'y', 'youth_hostel'), 'dir')
  % ok
else
  error('SUN397 not found in %s', datasetDir) ;
end

% Load the train/test splits
if isempty(opts.splitsFile)
  opts.splitsFile = fullfile(datasetDir, ...
    sprintf('split10_%02d.mat', opts.seed)) ;
end
try
  split = load(opts.splitsFile, 'split') ;
  split = split.split;
  fprintf('Loaded split: %s\n', opts.splitsFile)
catch
  error('Cannot load split from "%s".', opts.splitsFile) ;
end

% Construct image database imdb structure
imdb.meta.sets = {'train', 'val', 'test'} ;

sets = {} ;
names = {} ;
classes = {} ;
imdb.meta.classes = cell(size(split)) ;
for c = 1:numel(split)
  randn('state', opts.seed) ;
  rand('state', opts.seed) ;
  selTrain = vl_colsubset(1:numel(split{c}.Training), opts.numTrain) ;
  selTest = vl_colsubset(1:numel(split{c}.Testing), opts.numTest) ;

  imdb.meta.classes{c} = split{c}.ClassName ;
  sets{c} = [ones(1, opts.numTrain), repmat(3, 1, opts.numTest)] ;
  names{c} = [fullfile(split{c}.ClassName, split{c}.Training(selTrain)), ...
              fullfile(split{c}.ClassName, split{c}.Testing(selTest))] ;
  classes{c} = repmat(c, 1, numel(names{c})) ;
end

sets = cat(2, sets{:}) ;
names = cat(2, names{:}) ;
classes = cat(2, classes{:}) ;
ids = 1:numel(names) ;

numClasses = numel(imdb.meta.classes) ;
if ~isempty(opts.expectedNumClasses) && numClasses ~= opts.expectedNumClasses
  error('Expected %d classes in image database at %s.', opts.expectedNumClasses, datasetDir) ;
end

ok = find(sets ~= 0) ;
imdb.images.id = ids(ok) ;
imdb.images.name = names(ok) ;
imdb.images.set = sets(ok) ;
imdb.images.class = classes(ok) ;
imdb.imageDir = datasetDir ;

if opts.lite
  ok = {} ;
  % some of the most confusing class tuples:
  % 4 '/a/alley' - 239 '/m/medina'
  % 10 '/a/apse/indoor' - 85 '/c/cathedral/indoor'
  % 62 '/b/boxing_ring' - 395 '/w/wrestling_ring/indoor'
  % 79 '/c/car_interior/backseat' - 80 '/c/car_interior/frontseat'
  % 141 '/d/drugstore' - 274 '/p/pharmacy'
  % 287 '/p/poolroom/home' - 299 '/r/recreation_room'
  % 203 '/i/industrial_area' - 288 '/p/power_plant/outdoor' - 251 '/n/nuclear_power_plant/outdoor'
  % 326 '/s/sky'
  % 292 '/p/putting_green'
  % 152 '/f/field/cultivated' - 390 '/w/wheat_field' - 153 '/f/field/wild' - 271 '/p/pasture'
  % 186 '/h/hill'
  %
  % 1 203 '/i/industrial_area'
  % 2 288 '/p/power_plant/outdoor'
  % 3 251 '/n/nuclear_power_plant/outdoor'
  % 4 292 '/p/putting_green'
  % 5 152 '/f/field/cultivated' 
  % 6 390 '/w/wheat_field' 
  % 7 153 '/f/field/wild' 
  % 8 271 '/p/pasture'
  % 9 186 '/h/hill'
  liteClasses = [203 288 251 292 152 390 153 271 186];
  for c = liteClasses
    ok{end+1} = vl_colsubset(find(imdb.images.class == c & imdb.images.set == 1), 5) ;
    ok{end+1} = vl_colsubset(find(imdb.images.class == c & imdb.images.set == 2), 5) ;
    ok{end+1} = vl_colsubset(find(imdb.images.class == c & imdb.images.set == 3), 5) ;
  end
  ok = cat(2, ok{:}) ;
  imdb.meta.classes = imdb.meta.classes(liteClasses) ;
  imdb.images.id = imdb.images.id(ok) ;
  imdb.images.name = imdb.images.name(ok) ;
  imdb.images.set = imdb.images.set(ok) ;
  imdb.images.class = imdb.images.class(ok) ;

  %imdb.meta.classWeights = ones(numel(liteClasses), numel(liteClasses)) ;
  
  %imdb.meta.classWeights(6:7, 8) = 0 ;
  %imdb.meta.classWeights(7:8, 9) = 0 ;
  %imdb.meta.classWeights(6:7, 5) = 0 ;
  
  % remap class IDs to preserve class order
  % (and hence the block structure of the confusion matrix)
  for c = 1:numel(liteClasses)
    imdb.images.class(imdb.images.class == liteClasses(c)) = c;
  end
end
