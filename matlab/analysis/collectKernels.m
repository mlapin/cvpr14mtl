function collectKernels()
% Collect selected train/test kernels and the associated metadata
% from all source directories (which have cryptic names)
% and save to a single folder using human-readable file names
%

reload = false;
suffix = '2014-04-09';
resFile = sprintf('experiments/results_%s.mat', suffix);

if ~reload && exist(resFile, 'file')
  load(resFile, 'results');
else
  tic;
  results = readExperimentResults(); %#ok<*NASGU>
  toc;
  save(resFile, 'results');
end

defineIndexes;

collectOneSeed(r(iN05 & iSIFT & iKhel), 1, 'N05-SIFT', 'Khell');
collectOneSeed(r(iN05 & iLCSPNL2 & iKhel), 1, 'N05-SIFT-LCS-PN-L2', 'Khell');

collectOneSeed(r(iN10 & iSIFT & iKhel), 1, 'N10-SIFT', 'Khell');
collectOneSeed(r(iN10 & iLCSPNL2 & iKhel), 1, 'N10-SIFT-LCS-PN-L2', 'Khell');

collectOneSeed(r(iN20 & iSIFT & iKhel), 1, 'N20-SIFT', 'Khell');
collectOneSeed(r(iN20 & iLCSPNL2 & iKhel), 1, 'N20-SIFT-LCS-PN-L2', 'Khell');

collectAllSeeds(r(iN50 & iSIFT & iKhel), 'N50-SIFT', 'Khell');
collectAllSeeds(r(iN50 & iLCSPNL2 & iKhel), 'N50-SIFT-LCS-PN-L2', 'Khell');

end

function collectAllSeeds(r, features, kernel)
for seed = 1:10
  collectOneSeed(r, seed, features, kernel)
end
end

function collectOneSeed(r, seed, features, kernel)

tgtDir = 'data/kernels';

fprintf('Seed %2d, %s-%s\n', seed, features, kernel);

res = r([r.seed] == seed)';
srcDir = unique(regexprep({res.fname},'^(.*)/[^/]+$','$1'));
assert(numel(srcDir) == 1);
srcDir = srcDir{1};

imdb = load(fullfile(srcDir, 'imdb.mat'));
encoder = load(fullfile(srcDir, 'encoder.mat'));
Ytrn = double(imdb.images.class(imdb.images.set ~= 3));
Ytst = double(imdb.images.class(imdb.images.set == 3));

save(fullfile(tgtDir, sprintf('meta-S%02d-%s.mat', seed, features)), ...
  'imdb', 'encoder', 'srcDir', '-v7');
fprintf('  metadata saved\n');
clear imdb encoder;

Ktrn = load(fullfile(srcDir, sprintf('result-%s-trn-nobias.mat', kernel)), 'Ktrn');
Ktrn = single(Ktrn.Ktrn);
save(fullfile(tgtDir, ...
  sprintf('Train-S%02d-%s-%s.mat', seed, features, kernel)), 'Ytrn', 'Ktrn', '-v7');
fprintf('  trn kernel saved\n');
clear Ktrn;

Ktst = load(fullfile(srcDir, sprintf('result-%s-tst-nobias.mat', kernel)), 'Ktst');
Ktst = single(Ktst.Ktst);
save(fullfile(tgtDir, ...
  sprintf('Test-S%02d-%s-%s.mat', seed, features, kernel)), 'Ytst', 'Ktst', '-v7');
fprintf('  tst kernel saved\n');
clear Ktst;

end
