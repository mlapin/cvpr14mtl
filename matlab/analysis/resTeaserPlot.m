% clc;
clear;
% close all;

reload = false;
suffix = '2014-04-09';
resFile = sprintf('experiments/results_%s.mat', suffix);

if ~reload && exist(resFile, 'file')
  load(resFile, 'results');
else
  tic;
  results = readExperimentResults();
  toc;
  save(resFile, 'results');
end

defineIndexes;

% Previous work (mean/std, Ntrain=5,10,20,50)
ntrain = [5 10 20 50];
xiao = [14.5 0; 20.9 0; 28.1 0; 38.0 0];
sujurie = [nan nan; nan nan; nan nan; 35.6 0.4];
donahue = [nan nan; nan nan; nan nan; 40.9 0.3];
sanchezSift = [19.2 0.4; 26.6 0.4; 34.2 0.3; 43.3 0.2];
sanchezSiftLcs = [21.1 0.3; 29.1 0.3; 37.4 0.3; 47.2 0.2];

% From the work of Xiao et al., see human_analysis.m
allworkers = [nan nan; nan nan; nan nan; 4654/7940 0];
goodworkers = [nan nan; nan nan; nan nan; 2735/3994 0];

meanstd = @(ix) [mean([r(ix).mAcc]) std([r(ix).mAcc])];
getStats = @(ix) [meanstd(ix & iN05); meanstd(ix & iN10); meanstd(ix & iN20); meanstd(ix & iN50)];
getLegend = @(authors, acc) sprintf('%s (%.1f)', authors, acc(end,1));

stlSift = getStats(iStl & iSIFT & iKhel);
stlSiftLcs = getStats(iStl & iLCSPNL2 & iKhel);
mtlSift = getStats(iMtlM & iSIFT & iKhel & iMtlMModel);
mtlSiftLcs = getStats(iMtlM & iLCSPNL2 & iKhel & iMtlMModel);

colors = [44,162,95; 136,86,167; 67,162,202; 201,148,199; 221,28,119; 8,81,156; 49,130,189; 165,15,21; 222,45,38];
colors = colors ./ 255;
LineWidth = 1.5;
MarkerSize = 12;

figure; hold on; grid on;

errorbar(ntrain, xiao(:,1), xiao(:,2), '.-', 'Color', colors(1,:), 'LineWidth', LineWidth, 'MarkerSize', MarkerSize);
errorbar(ntrain, sujurie(:,1), sujurie(:,2), '.-', 'Color', colors(2,:), 'LineWidth', LineWidth, 'MarkerSize', MarkerSize);
errorbar(ntrain, donahue(:,1), donahue(:,2), '.-', 'Color', colors(3,:), 'LineWidth', LineWidth, 'MarkerSize', MarkerSize);
errorbar(ntrain, sanchezSift(:,1), sanchezSift(:,2), '.--', 'Color', colors(4,:), 'LineWidth', LineWidth, 'MarkerSize', MarkerSize);
errorbar(ntrain, sanchezSiftLcs(:,1), sanchezSiftLcs(:,2), '.--', 'Color', colors(5,:), 'LineWidth', LineWidth, 'MarkerSize', MarkerSize);
errorbar(ntrain, stlSift(:,1), stlSift(:,2), '.-', 'Color', colors(6,:), 'LineWidth', LineWidth, 'MarkerSize', MarkerSize);
errorbar(ntrain, mtlSift(:,1), mtlSift(:,2), '.-', 'Color', colors(7,:), 'LineWidth', LineWidth, 'MarkerSize', MarkerSize);
errorbar(ntrain, stlSiftLcs(:,1), stlSiftLcs(:,2), '.-', 'Color', colors(8,:), 'LineWidth', LineWidth, 'MarkerSize', MarkerSize);
errorbar(ntrain, mtlSiftLcs(:,1), mtlSiftLcs(:,2), '.-', 'Color', colors(9,:), 'LineWidth', LineWidth, 'MarkerSize', MarkerSize);

set(gca, 'XTick', ntrain);
xlabel('Number of training examples per class');
ylabel('Accuracy (%)');
legend(getLegend('Xiao et al.', xiao), getLegend('Su and Jurie', sujurie), getLegend('Donahue et al.', donahue), ...
  getLegend('Sanchez et al., SIFT', sanchezSift), getLegend('Sanchez et al., SIFT+LCS', sanchezSiftLcs), ...
  getLegend('STL-SDCA, SIFT', stlSift), getLegend('MTL-SDCA, SIFT', mtlSift), ...
  getLegend('STL-SDCA, SIFT+LCS', stlSiftLcs), getLegend('MTL-SDCA, SIFT+LCS', mtlSiftLcs), ...
  'Location', 'SouthEast');

printpdf('sun397results');
