clc;
clear;
close all;

reload = false;
suffix = '2014-04-09';
resFile = sprintf('experiments/results_%s.mat', suffix);
supFile = sprintf('experiments/supplemental_%s.mat', suffix);

if ~reload && exist(resFile, 'file')
  load(resFile, 'results');
else
  tic;
  results = readExperimentResults();
  toc;
  save(resFile, 'results');
end

defineIndexes;

% ixStl = iStl & iSIFT & iKhel & iN50;
% ixMtl = iMtlM & iSIFT & iKhel & iMtlMModel & iN50;

ixStl = iStl & iSIFT & iKhel & iN20;
ixMtl = iMtlM & iSIFT & iKhel & iMtlMModel & iN20;

load data/good_workers_confusion.mat;
C = C ./ 100;

[~,rankings] = sort(C,2,'descend');
confusions = C > 0;

[numconf,highconfclasses] = sort(sum(confusions,2),'descend');
highconfclasses = highconfclasses(numconf > 3);

maxK = 5;

if ~reload && exist(supFile, 'file')
  load(supFile);
else
  tic;
  
  selcmp = [];
  selimg = {};
  seltruth = [];
  selstlpred = [];
  selmtlpred = [];
  selstlscor = [];
  selmtlscor = [];
  selstlfnames = {};
  selmtlfnames = {};
  for seed = 1:10
    fprintf('Seed = %g\n', seed);
    ixSeed = [r.seed] == seed;
    stl = r(ixStl & ixSeed);
    mtl = r(ixMtl & ixSeed);
    folder = fileparts(stl.fname);
    assert(strcmp(folder, fileparts(mtl.fname)));

    load(fullfile(folder, 'imdb.mat'), 'images');

    stlscores = load(stl.fname, 'scores');
    stlscores = stlscores.scores;
    mtlscores = load(mtl.fname, 'scores');
    mtlscores = mtlscores.scores;

    images.class = images.class(images.set==3);
    images.name = images.name(images.set==3);

    [stlscor,stlpred] = sort(stlscores,1,'descend');
    [mtlscor,mtlpred] = sort(mtlscores,1,'descend');

    for j = 1:numel(highconfclasses)
      cind = highconfclasses(j);
      expected = find(confusions(cind,:))';
      expected = expected(1:min(maxK,end));
      cimgind = images.class == cind;
      stlres = stlpred(1:numel(expected),cimgind);
      mtlres = mtlpred(1:numel(expected),cimgind);
      stlcmp = zeros(1,size(stlres,2));
      mtlcmp = zeros(1,size(stlres,2));
      for i = 1:size(stlres,2)
        stlcmp(i) = numel(intersect(stlres(:,i), expected));
        mtlcmp(i) = numel(intersect(mtlres(:,i), expected));
      end

      sel = mtlcmp - stlcmp > 2 & mtlcmp > 2;
      if any(sel)
        selcmp = [selcmp mtlcmp(sel)]; %#ok<*AGROW>
        selind = find(cimgind);
        selind = selind(sel);
        seltruth = [seltruth images.class(selind)];
        selimg = [selimg images.name(selind)];
        selstlpred = [selstlpred stlpred(:,selind)];
        selmtlpred = [selmtlpred mtlpred(:,selind)];
        selstlscor = [selstlscor stlscor(:,selind)];
        selmtlscor = [selmtlscor mtlscor(:,selind)];
        selstlfnames = [selstlfnames repmat({stl.fname}, 1, sum(sel))];
        selmtlfnames = [selmtlfnames repmat({mtl.fname}, 1, sum(sel))];
      end
    end
  end
  
  save(supFile);
  
  toc;
end


dbpath = 'data/SUN397-R100K';
thumbspath = 'data/SUN397-thumbs-R100K';
thumbs = strrep(labelMat(1:397,1:2),'.jpg','.png');
classes = arrayfun(@(x) x{1}(4:end), labelMat(1:397,1), 'UniformOutput', false);
classes = strrep(classes, '_', ' ');
classes = strrep(classes, '/', ', ');

imgdir = 'data/images';
vl_xmkdir(imgdir);

fid = fopen('supp.tex','w');

ind =  [5 9 4 2 3 6 8 7 1];
for i = 1:numel(ind)
  ix = ind(i);
  cind = seltruth(ix);
  [humconf, humpred] = sort(C(cind,:), 'descend');
  K = min(maxK, sum(humconf > 0));
  topstlpred = selstlpred(1:maxK,ix);
  topmtlpred = selmtlpred(1:maxK,ix);
  tophumpred = humpred(1:K);
  
  fprintf(fid, '%s\n', '\begin{suppfigure}');
  fprintf(fid, '%s\n', '\begin{tabular}{>{\centering}m{.15\textwidth}m{.83\textwidth}}');

  [~,imname,imext] = fileparts(selimg{ix});
  if ~exist(fullfile(imgdir, [imname imext]), 'file')
    copyfile(fullfile(dbpath, selimg{ix}), fullfile(imgdir, [imname imext]));
  end
  I = imread(fullfile(dbpath, selimg{ix}));
  fprintf(fid, 'Test image\n');
  if false % size(I,2) < 1.5 * size(I,1)
    fprintf(fid, '\\includegraphics[height=1.5cm]{%s}\n', imname);
  else
    fprintf(fid, '\\includegraphics[width=2.5cm]{%s}\n', imname);
  end
  fprintf(fid, 'Ground truth:\\linebreak\\textbf{%s} & \n', classes{cind});
  
  % Inner table begin
  fprintf(fid, '%s\n', '\begin{tabular}{m{6pt}>{\centering}m{.15\textwidth}%');
  fprintf(fid, '%s\n', '>{\centering}m{.15\textwidth}>{\centering}m{.15\textwidth}%');
  fprintf(fid, '%s\n', '>{\centering}m{.15\textwidth}>{\centering}m{.15\textwidth}}');
  
  
  % STL
  fprintf(fid, '%s\n', '\multirow{2}{*}{\rotatebox{90}{STL}} &');
  for j = 1:maxK
    stlpred = selstlpred(j,ix);
    if ~exist(fullfile(imgdir, thumbs{stlpred,2}), 'file')
      copyfile(fullfile(thumbspath, thumbs{stlpred,:}), fullfile(imgdir, thumbs{stlpred,2}));
    end
    I = imread(fullfile(thumbspath, thumbs{stlpred,:}));
    if j > 1
      fprintf(fid, ' & ');
    end
    if size(I,2) < 1.5 * size(I,1)
      fprintf(fid, '\\includegraphics[height=1.5cm]{%s}\n', thumbs{stlpred,2});
    else
      fprintf(fid, '\\includegraphics[width=2.5cm]{%s}\n', thumbs{stlpred,2});
    end
  end
  %fprintf(fid, ' & \\includegraphics[width=2.5cm]{stlconf%d.pdf}\n', ix);
  fprintf(fid, '\\tabularnewline\n');
  for j = 1:maxK
    %fprintf(fid, ' & %.3f: \\textbf{%s}\n', selstlscor(j,ix), classes{selstlpred(j,ix)});
    if ismember(selstlpred(j,ix), tophumpred)
      %fprintf(fid, ' & %d: \\textbf{%s}\\linebreak (score: %.3f)\n', j, classes{selstlpred(j,ix)}, selstlscor(j,ix));
      fprintf(fid, ' & %d: \\textbf{%s}\\vspace*{5pt}\n', j, classes{selstlpred(j,ix)});
    else
      %fprintf(fid, ' & %d: %s\\linebreak (score: %.3f)\n', j, classes{selstlpred(j,ix)}, selstlscor(j,ix));
      fprintf(fid, ' & %d: %s\\vspace*{5pt}\n', j, classes{selstlpred(j,ix)});
    end
  end
  fprintf(fid, '\\tabularnewline\n');

  
  % MTL
  fprintf(fid, '%s\n', '\multirow{2}{*}{\rotatebox{90}{MTL}} &');
  for j = 1:maxK
    mtlpred = selmtlpred(j,ix);
    if ~exist(fullfile(imgdir, thumbs{mtlpred,2}), 'file')
      copyfile(fullfile(thumbspath, thumbs{mtlpred,:}), fullfile(imgdir, thumbs{mtlpred,2}));
    end
    I = imread(fullfile(thumbspath, thumbs{mtlpred,:}));
    if j > 1
      fprintf(fid, ' & ');
    end
    if size(I,2) < 1.5 * size(I,1)
      fprintf(fid, '\\includegraphics[height=1.5cm]{%s}\n', thumbs{mtlpred,2});
    else
      fprintf(fid, '\\includegraphics[width=2.5cm]{%s}\n', thumbs{mtlpred,2});
    end
  end
  %fprintf(fid, ' & \\includegraphics[width=2.5cm]{mtlconf%d.pdf}\n', ix);
  fprintf(fid, '\\tabularnewline\n');
  for j = 1:maxK
    %fprintf(fid, ' & %.3f: \\textbf{%s}\n', selmtlscor(j,ix), classes{selmtlpred(j,ix)});
    if ismember(selmtlpred(j,ix), tophumpred)
      %fprintf(fid, ' & %d: \\textbf{%s}\\linebreak (score: %.3f)\n', j, classes{selmtlpred(j,ix)}, selmtlscor(j,ix));
      fprintf(fid, ' & %d: \\textbf{%s}\\vspace*{5pt}\n', j, classes{selmtlpred(j,ix)});
    else
      %fprintf(fid, ' & %d: %s\\linebreak (score: %.3f)\n', j, classes{selmtlpred(j,ix)}, selmtlscor(j,ix));
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
      fprintf(fid, '\\vspace*{5pt}\\includegraphics[height=1.5cm]{%s}\n', thumbs{pred,2});
    else
      fprintf(fid, '\\vspace*{5pt}\\includegraphics[width=2.5cm]{%s}\n', thumbs{pred,2});
    end
  end
  for j = (j+1):maxK
    fprintf(fid, ' & ');
  end
  %fprintf(fid, ' & \\includegraphics[width=2.5cm]{humconf%d.pdf}\n', ix);
  fprintf(fid, '\\tabularnewline\n');
  for j = 1:K
    %fprintf(fid, ' & %.2f: \\textbf{%s}\n', humconf(j), classes{humpred(j)});
    if ismember(humpred(j), topstlpred) || ismember(humpred(j), topmtlpred)
      fprintf(fid, ' & %d: \\textbf{%s}\\linebreak (confidence: %.2f)\n', j, classes{humpred(j)}, humconf(j));
    else
      fprintf(fid, ' & %d: %s\\linebreak (confidence: %.2f)\n', j, classes{humpred(j)}, humconf(j));
    end
  end
  for j = (j+1):maxK
    fprintf(fid, ' & ');
  end
  fprintf(fid, '\\tabularnewline\n');
  
  
  % Inner table end
  fprintf(fid, '%s\n', '\end{tabular}');
  
  
  fprintf(fid, '\\end{tabular}\n');
  fprintf(fid, '\\end{suppfigure}\n');
  
end

fclose(fid);

