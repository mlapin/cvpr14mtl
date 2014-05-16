%
% Produce visualizations for the supplementary material
%

clc;
clear;
close all;

topK = 5;
Ntrain = 20;
selection = 'best';

% MTL over STL threshold
% Used to select examples on which MTL is closer to human predictions
% than STL by that many 'guesses'
marginThreshold = 3;


reload = false;
suffix = '2014-04-09';
resFile = sprintf('experiments/results_%s.mat', suffix);
supFile = sprintf('experiments/supplemental_%s_N%d_top%d.mat', '2014-04-25', Ntrain, topK);

if ~reload && exist(resFile, 'file')
  load(resFile, 'results');
else
  tic;
  results = readExperimentResults();
  toc;
  save(resFile, 'results');
end

defineIndexes;

% Select an experimental setting
if Ntrain == 50
  ixStl = iStl & iSIFT & iKhel & iN50;
  ixMtl = iMtlM & iSIFT & iKhel & iMtlMModel & iN50;
elseif Ntrain == 20
  ixStl = iStl & iSIFT & iKhel & iN20;
  ixMtl = iMtlM & iSIFT & iKhel & iMtlMModel & iN20;
else
  assert(0);
end

load data/good_workers_confusion.mat;
C = C ./ 100;

% Classes most confused by humans (AMT workers)
confusions = C > 0;
[numconf,confclasses] = sort(sum(confusions,2),'descend');
confclasses = confclasses(numconf > 1);

if ~reload && exist(supFile, 'file')
  load(supFile);
else
  tic;

  clear supresults;
  for seed = 1:10
    supresults(seed).seed = seed; %#ok<*SAGROW>
    fprintf('Seed = %g\n', seed);
    ixSeed = [r.seed] == seed;
    stl = r(ixStl & ixSeed);
    mtl = r(ixMtl & ixSeed);
    folder = fileparts(stl.fname);
    assert(strcmp(folder, fileparts(mtl.fname)));

    load(fullfile(folder, 'imdb.mat'), 'images');
    images.class = images.class(images.set==3);
    images.name = images.name(images.set==3);
    supresults(seed).images = images;
    
    allclasses = unique(images.class)';

    load(stl.fname, 'scores', 'confusion');
    [stlscores,stlpredictions] = sort(scores,1,'descend');
    stlscores = stlscores(1:topK,:);
    stlpredictions = single(stlpredictions(1:topK,:));
    stlconfusion = confusion;
    supresults(seed).stlscores = stlscores;
    supresults(seed).stlpredictions = stlpredictions;
    supresults(seed).stlconfusion = stlconfusion;
    clear scores confusion;

    load(mtl.fname, 'scores', 'confusion');
    [mtlscores,mtlpredictions] = sort(scores,1,'descend');
    mtlscores = mtlscores(1:topK,:);
    mtlpredictions = single(mtlpredictions(1:topK,:));
    mtlconfusion = confusion;
    supresults(seed).mtlscores = mtlscores;
    supresults(seed).mtlpredictions = mtlpredictions;
    supresults(seed).mtlconfusion = mtlconfusion;
    clear scores confusion;

    % Assume all classes have the same number of test examples
    Ntst = sum(images.class == 1);

    imgids = zeros(Ntst, numel(confclasses));
    stlcmp = zeros(Ntst, numel(confclasses));
    mtlcmp = zeros(Ntst, numel(confclasses));
    amtconfsum = zeros(3, numel(confclasses));
    stlconfsum = zeros(3, numel(confclasses));
    mtlconfsum = zeros(3, numel(confclasses));
    for j = 1:numel(confclasses)
      classid = confclasses(j);
      humanpredictions = find(confusions(classid,:))';
      ids = find(images.class == classid);
      imgids(:,j) = ids;
 
      % Compare the STL/MTL and human top-K predictions:
      % how many of the classes were also predicted (confused) by humans?
      for i = 1:Ntst
        stlcmp(i,j) = numel(intersect(stlpredictions(:,ids(i)), humanpredictions));
        mtlcmp(i,j) = numel(intersect(mtlpredictions(:,ids(i)), humanpredictions));
      end

      % Confusion matrix analysis:
      % For each of the confused classes and for each method (AMT/STL/MTL),
      % compute 3 numbers from the corresponding confusion matrix:
      % 1) true class accuracy (value on the diagonal of the conf matrix);
      % 2) sum up confusion over classes mixed by humans;
      % 3) sum up confusion over the rest of the classes.
      mixed = setdiff(humanpredictions, classid);
      rest = setdiff(allclasses, [classid; mixed]);

      amtconfsum(1,j) = C(classid,classid);
      amtconfsum(2,j) = sum(C(classid,mixed));
      amtconfsum(3,j) = sum(C(classid,rest));
      assert(amtconfsum(3,j) == 0);

      stlconfsum(1,j) = stlconfusion(classid,classid);
      stlconfsum(2,j) = sum(stlconfusion(classid,mixed));
      stlconfsum(3,j) = sum(stlconfusion(classid,rest));

      mtlconfsum(1,j) = mtlconfusion(classid,classid);
      mtlconfsum(2,j) = sum(mtlconfusion(classid,mixed));
      mtlconfsum(3,j) = sum(mtlconfusion(classid,rest));

    end
    supresults(seed).imgids = imgids;
    supresults(seed).stlcmp = stlcmp;
    supresults(seed).mtlcmp = mtlcmp;
    supresults(seed).amtconfsum = amtconfsum;
    supresults(seed).stlconfsum = stlconfsum;
    supresults(seed).mtlconfsum = mtlconfsum;

    clear images stlscores stlpredictions stlconfusion mtlscores mtlpredictions mtlconfusion mixed rest;
  end

  save(supFile, 'supresults');

  toc;
end


% Compare how the top-K prediction results changed overall
% - are MTL predictions closer to human on average?
diff = [supresults.mtlcmp] - [supresults.stlcmp];
diff = diff(:);

[nelements, centers] = hist(diff, -4:4);
visIx = centers >= marginThreshold;

figure; hold on; grid on; set(gca, 'FontSize', 12);
bar(centers, log10(nelements));
bar(centers(visIx), log10(nelements(visIx)), 'r');
xlabel('f_{MTL} - f_{STL}'); ylabel('Number of examples, log10 scale');
text(centers(1), max(log10(nelements)), sprintf('#<0: %d\n#>0: %d', ...
  sum(diff < 0), sum(diff > 0)), ...
  'BackgroundColor', 'w', 'EdgeColor', 'k', 'FontName', 'FixedWidth', 'FontSize', 16);
printpdf('suppnumex');

figure; hold on; grid on; set(gca, 'FontSize', 12);
f = nelements/trapz(centers,nelements);
bar(centers, f);
plot(centers, cumsum(f), '.-r', 'LineWidth', 2);
bar(centers(visIx), f(visIx), 'r');
xlabel('f_{MTL} - f_{STL}'); ylabel('Empirical distribution (normalized)');
text(centers(1), max(f), sprintf('%%<0: %5.2f\n%%>0: %5.2f', ...
  100*sum(f(centers < 0)), 100*sum(f(centers > 0))), ...
  'BackgroundColor', 'w', 'EdgeColor', 'k', 'FontName', 'FixedWidth', 'FontSize', 16);
printpdf('suppdist');


% Select a small subset of AMT/STL/MTL predictions for visualization

% For the random subset
reset(RandStream.getGlobalStream);
numperseed = 5;

seltruth = [];
selimg = [];
selstlpred = [];
selmtlpred = [];
selmargin = [];
for seed = 1:10
  res = supresults(seed);
  diff = res.mtlcmp - res.stlcmp;

  if strcmpi(selection, 'best')
    % Find examples where MTL predictions are closer to human with a margin
    visIx = diff >= marginThreshold;
  else
    visIx = randi(numel(res.imgids), numperseed, 1);
  end

  selected = res.imgids(visIx);
  seltruth = [seltruth res.images.class(selected)];
  selimg = [selimg res.images.name(selected)];
  selstlpred = [selstlpred res.stlpredictions(:,selected)];
  selmtlpred = [selmtlpred res.mtlpredictions(:,selected)];
  selmargin = [selmargin diff(visIx)'];

end

% Produce the visualization (tex it)

dbpath = 'data/SUN397-R100K';
thumbspath = 'data/SUN397-thumbs-R100K';
thumbs = strrep(labelMat(1:397,1:2),'.jpg','.png');
classes = arrayfun(@(x) x{1}(4:end), labelMat(1:397,1), 'UniformOutput', false);
classes = strrep(classes, '_', ' ');
classes = strrep(classes, '/', ', ');

imgdir = 'data/images';
vl_xmkdir(imgdir);

capwidth = .02;
imwidth = (.96 - 1.5*capwidth) / (topK + 1);

fid = fopen('supp.tex','w');

% Select a subset in a particular order
ind = [12 10 4 7 5 6 14];
for i = 1:numel(ind)
  ix = ind(i);
  classid = seltruth(ix);
  fprintf('%3d: %s\n', i, classes{classid});

  [humconf, humpred] = sort(C(classid,:), 'descend');
  K = min(topK, sum(humconf > 0));
  topstlpred = selstlpred(1:topK,ix);
  topmtlpred = selmtlpred(1:topK,ix);
  tophumpred = humpred(1:K)';

  fprintf(fid, '%s\n', '\begin{suppfigure}');
  fprintf(fid, '\\begin{tabular}{>{\\centering}m{%.3f\\textwidth}l}\n', imwidth + .5*capwidth);

  [~,imname,imext] = fileparts(selimg{ix});
  if ~exist(fullfile(imgdir, [imname imext]), 'file')
    copyfile(fullfile(dbpath, selimg{ix}), fullfile(imgdir, [imname imext]));
  end
  I = imread(fullfile(dbpath, selimg{ix}));
  fprintf(fid, 'Test image\n');
  fprintf(fid, '\\includegraphics[width=%.3f\\textwidth]{%s}\n', imwidth, imname);
  fprintf(fid, 'Ground truth:\\linebreak\\textbf{%s} & \n', classes{classid});

  % Inner table begin
  fprintf(fid, '\\begin{tabular}{m{%.3f\\textwidth}\n', capwidth);
  for j = 1:topK
    fprintf(fid, '>{\\centering}m{%.3f\\textwidth}', imwidth);
  end
  fprintf(fid, '}\n');


  % STL
  fprintf(fid, '%s\n', '\multirow{2}{*}{\rotatebox{90}{STL}} &');
  for j = 1:topK
    stlpredictions = selstlpred(j,ix);
    if ~exist(fullfile(imgdir, thumbs{stlpredictions,2}), 'file')
      copyfile(fullfile(thumbspath, thumbs{stlpredictions,:}), fullfile(imgdir, thumbs{stlpredictions,2}));
    end
    I = imread(fullfile(thumbspath, thumbs{stlpredictions,:}));
    if j > 1
      fprintf(fid, ' & ');
    end
    if size(I,2) < 1.5 * size(I,1)
      fprintf(fid, '\\includegraphics[width=%.3f\\textwidth]{%s}\n', imwidth/1.5, thumbs{stlpredictions,2});
    else
      fprintf(fid, '\\includegraphics[width=%.3f\\textwidth]{%s}\n', imwidth, thumbs{stlpredictions,2});
    end
  end
  fprintf(fid, '\\tabularnewline\n');
  for j = 1:topK
    if ismember(selstlpred(j,ix), tophumpred)
      fprintf(fid, ' & %d: \\textbf{%s}\\vspace*{5pt}\n', j, classes{selstlpred(j,ix)});
    else
      fprintf(fid, ' & %d: %s\\vspace*{5pt}\n', j, classes{selstlpred(j,ix)});
    end
  end
  fprintf(fid, '\\tabularnewline\n');


  % MTL
  fprintf(fid, '%s\n', '\multirow{2}{*}{\rotatebox{90}{MTL}} &');
  for j = 1:topK
    mtlpredictions = selmtlpred(j,ix);
    if ~exist(fullfile(imgdir, thumbs{mtlpredictions,2}), 'file')
      copyfile(fullfile(thumbspath, thumbs{mtlpredictions,:}), fullfile(imgdir, thumbs{mtlpredictions,2}));
    end
    I = imread(fullfile(thumbspath, thumbs{mtlpredictions,:}));
    if j > 1
      fprintf(fid, ' & ');
    end
    if size(I,2) < 1.5 * size(I,1)
      fprintf(fid, '\\includegraphics[width=%.3f\\textwidth]{%s}\n', imwidth/1.5, thumbs{mtlpredictions,2});
    else
      fprintf(fid, '\\includegraphics[width=%.3f\\textwidth]{%s}\n', imwidth, thumbs{mtlpredictions,2});
    end
  end
  fprintf(fid, '\\tabularnewline\n');
  for j = 1:topK
    if ismember(selmtlpred(j,ix), tophumpred)
      fprintf(fid, ' & %d: \\textbf{%s}\\vspace*{5pt}\n', j, classes{selmtlpred(j,ix)});
    else
      fprintf(fid, ' & %d: %s\\vspace*{5pt}\n', j, classes{selmtlpred(j,ix)});
    end
  end
  fprintf(fid, '\\tabularnewline\n');


  % Human
  fprintf(fid, '\\midrule\n%s\n', '\multirow{2}{*}{\rotatebox{90}{Human}} &');
  for j = 1:K
    pred = humpred(j);
    if ~exist(fullfile(imgdir, thumbs{pred,2}), 'file')
      copyfile(fullfile(thumbspath, thumbs{pred,:}), fullfile(imgdir, thumbs{pred,2}));
    end
    I = imread(fullfile(thumbspath, thumbs{pred,:}));
    if j > 1
      fprintf(fid, ' & ');
    end
    if size(I,2) < 1.5 * size(I,1)
      fprintf(fid, '\\vspace*{5pt}\\includegraphics[width=%.3f\\textwidth]{%s}\n', imwidth/1.5, thumbs{pred,2});
    else
      fprintf(fid, '\\vspace*{5pt}\\includegraphics[width=%.3f\\textwidth]{%s}\n', imwidth, thumbs{pred,2});
    end
  end
  for j = (j+1):topK
    fprintf(fid, ' & ');
  end
  fprintf(fid, '\\tabularnewline\n');
  for j = 1:K
    if ismember(humpred(j), topstlpred) || ismember(humpred(j), topmtlpred)
      fprintf(fid, ' & %d: \\textbf{%s}\\linebreak (confidence: %.2f)\n', j, classes{humpred(j)}, humconf(j));
    else
      fprintf(fid, ' & %d: %s\\linebreak (confidence: %.2f)\n', j, classes{humpred(j)}, humconf(j));
    end
  end
  for j = (j+1):topK
    fprintf(fid, ' & ');
  end
  fprintf(fid, '\\tabularnewline\n');


  % Inner table end
  fprintf(fid, '%s\n', '\end{tabular}');


  fprintf(fid, '\\end{tabular}\n');
  fprintf(fid, '\\end{suppfigure}\n');

  if mod(i,10) == 0, fprintf(fid, '\\clearpage\n'); end

end

fclose(fid);
