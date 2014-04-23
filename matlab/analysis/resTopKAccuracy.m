% clc;
clear;
close all;

reload = false;
suffix = '2014-04-09';
resFile = sprintf('experiments/results_%s.mat', suffix);
accFile = sprintf('experiments/topacc_%s.mat', suffix);

if ~reload && exist(resFile, 'file')
  load(resFile, 'results');
else
  tic;
  results = readExperimentResults();
  toc;
  save(resFile, 'results');
end

defineIndexes;


% Top-K accuracies
topAll = 1:397;
topK = 1:20;

if ~reload && exist(accFile, 'file')
  load(accFile);
else
  tic;
  
  ix = iStl & iSIFT & iKhel & iN05;
  accStlSift05 = computeAllAccuracies(r(ix), topAll);

  ix = iStl & iSIFT & iKhel & iN10;
  accStlSift10 = computeAllAccuracies(r(ix), topAll);

  ix = iStl & iSIFT & iKhel & iN20;
  accStlSift20 = computeAllAccuracies(r(ix), topAll);

  ix = iStl & iSIFT & iKhel & iN50;
  accStlSift50 = computeAllAccuracies(r(ix), topAll);
  
  ix = iMtlM & iSIFT & iKhel & iMtlMModel & iN05;
  accMtlSift05 = computeAllAccuracies(r(ix), topAll);

  ix = iMtlM & iSIFT & iKhel & iMtlMModel & iN10;
  accMtlSift10 = computeAllAccuracies(r(ix), topAll);

  ix = iMtlM & iSIFT & iKhel & iMtlMModel & iN20;
  accMtlSift20 = computeAllAccuracies(r(ix), topAll);

  ix = iMtlM & iSIFT & iKhel & iMtlMModel & iN50;
  accMtlSift50 = computeAllAccuracies(r(ix), topAll);
  
  
  ix = iStl & iLCSPNL2 & iKhel & iN05;
  accStlSiftLcs05 = computeAllAccuracies(r(ix), topAll);

  ix = iStl & iLCSPNL2 & iKhel & iN10;
  accStlSiftLcs10 = computeAllAccuracies(r(ix), topAll);

  ix = iStl & iLCSPNL2 & iKhel & iN20;
  accStlSiftLcs20 = computeAllAccuracies(r(ix), topAll);

  ix = iStl & iLCSPNL2 & iKhel & iN50;
  accStlSiftLcs50 = computeAllAccuracies(r(ix), topAll);
  
  ix = iMtlM & iLCSPNL2 & iKhel & iMtlMModel & iN05;
  accMtlSiftLcs05 = computeAllAccuracies(r(ix), topAll);

  ix = iMtlM & iLCSPNL2 & iKhel & iMtlMModel & iN10;
  accMtlSiftLcs10 = computeAllAccuracies(r(ix), topAll);

  ix = iMtlM & iLCSPNL2 & iKhel & iMtlMModel & iN20;
  accMtlSiftLcs20 = computeAllAccuracies(r(ix), topAll);

  ix = iMtlM & iLCSPNL2 & iKhel & iMtlMModel & iN50;
  accMtlSiftLcs50 = computeAllAccuracies(r(ix), topAll);
  
  toc;
  save(accFile);
end



GoodWorkersAccuracy = 0.68478;

ColorStl = 'b';% [43 84 163] ./ 255;
ColorMtl = 'r';%[203 18 112] ./ 255; %[125 44 139] ./ 255;
ColorHuman = 'k';%[32 166 155] ./ 255;
LineWidth = 2;

% SIFT, no color
figure; hold on; grid on; box on;
ax = [0 numel(topK)+3.5 0.2 0.9];
axis(ax); 
set(gca, 'Xtick', 1:ax(2));
set(gca, 'Ytick', ax(3):0.05:ax(4));
set(gca, 'YtickLabel', 100*(ax(3):0.05:ax(4)));
set(gca, 'FontSize', 12);

m = mean(accStlSift05(:,topK)); s = std(accStlSift05(:,topK));
errorbar(1:numel(m), m, s, '-', 'Color', ColorStl, 'LineWidth', LineWidth);
text(20.5, m(end), 'Ntrain=5', 'BackgroundColor', 'w', 'FontSize', 12);
m = mean(accMtlSift05(:,topK)); s = std(accMtlSift05(:,topK));
errorbar(1:numel(m), m, s, '-', 'Color', ColorMtl, 'LineWidth', LineWidth);

plot([1 topK(end)], [GoodWorkersAccuracy GoodWorkersAccuracy], 'Color', ColorHuman, 'LineWidth', LineWidth);

m = mean(accStlSift10(:,topK)); s = std(accStlSift10(:,topK));
errorbar(1:numel(m), m, s, '-', 'Color', ColorStl, 'LineWidth', LineWidth);
text(20.5, m(end), 'Ntrain=10', 'BackgroundColor', 'w', 'FontSize', 12);
m = mean(accMtlSift10(:,topK)); s = std(accMtlSift10(:,topK));
errorbar(1:numel(m), m, s, '-', 'Color', ColorMtl, 'LineWidth', LineWidth);

m = mean(accStlSift20(:,topK)); s = std(accStlSift20(:,topK));
errorbar(1:numel(m), m, s, '-', 'Color', ColorStl, 'LineWidth', LineWidth);
text(20.5, m(end), 'Ntrain=20', 'BackgroundColor', 'w', 'FontSize', 12);
m = mean(accMtlSift20(:,topK)); s = std(accMtlSift20(:,topK));
errorbar(1:numel(m), m, s, '-', 'Color', ColorMtl, 'LineWidth', LineWidth);

m = mean(accStlSift50(:,topK)); s = std(accStlSift50(:,topK));
errorbar(1:numel(m), m, s, '-', 'Color', ColorStl, 'LineWidth', LineWidth);
text(20.5, m(end), 'Ntrain=50', 'BackgroundColor', 'w', 'FontSize', 12);
m = mean(accMtlSift50(:,topK)); s = std(accMtlSift50(:,topK));
errorbar(1:numel(m), m, s, '-', 'Color', ColorMtl, 'LineWidth', LineWidth);

plot(1, GoodWorkersAccuracy, 'o', 'Color', ColorHuman, 'LineWidth', LineWidth);

xlabel('Number of guesses');
ylabel('Accuracy (%)');
legend('STL-SDCA, Sqr, SIFT', 'MTL-SDCA, Sqr, SIFT', 'Human, 1 guess', 'Location', 'South');

printpdf('topkaccuracysift');


% Sift + Color
figure; hold on; grid on; box on;
ax = [0 numel(topK)+3.5 0.2 0.9];
axis(ax); 
set(gca, 'Xtick', 1:ax(2));
set(gca, 'Ytick', ax(3):0.05:ax(4));
set(gca, 'YtickLabel', 100*(ax(3):0.05:ax(4)));
set(gca, 'FontSize', 12);

m = mean(accStlSiftLcs05(:,topK)); s = std(accStlSiftLcs05(:,topK));
errorbar(1:numel(m), m, s, '-', 'Color', ColorStl, 'LineWidth', LineWidth);
text(20.5, m(end), 'Ntrain=5', 'BackgroundColor', 'w', 'FontSize', 12);
m = mean(accMtlSiftLcs05(:,topK)); s = std(accMtlSiftLcs05(:,topK));
errorbar(1:numel(m), m, s, '-', 'Color', ColorMtl, 'LineWidth', LineWidth);

plot([1 topK(end)], [GoodWorkersAccuracy GoodWorkersAccuracy], 'Color', ColorHuman, 'LineWidth', LineWidth);

m = mean(accStlSiftLcs10(:,topK)); s = std(accStlSiftLcs10(:,topK));
errorbar(1:numel(m), m, s, '-', 'Color', ColorStl, 'LineWidth', LineWidth);
text(20.5, m(end), 'Ntrain=10', 'BackgroundColor', 'w', 'FontSize', 12);
m = mean(accMtlSiftLcs10(:,topK)); s = std(accMtlSiftLcs10(:,topK));
errorbar(1:numel(m), m, s, '-', 'Color', ColorMtl, 'LineWidth', LineWidth);

m = mean(accStlSiftLcs20(:,topK)); s = std(accStlSiftLcs20(:,topK));
errorbar(1:numel(m), m, s, '-', 'Color', ColorStl, 'LineWidth', LineWidth);
text(20.5, m(end), 'Ntrain=20', 'BackgroundColor', 'w', 'FontSize', 12);
m = mean(accMtlSiftLcs20(:,topK)); s = std(accMtlSiftLcs20(:,topK));
errorbar(1:numel(m), m, s, '-', 'Color', ColorMtl, 'LineWidth', LineWidth);

m = mean(accStlSiftLcs50(:,topK)); s = std(accStlSiftLcs50(:,topK));
errorbar(1:numel(m), m, s, '-', 'Color', ColorStl, 'LineWidth', LineWidth);
text(20.5, m(end), 'Ntrain=50', 'BackgroundColor', 'w', 'FontSize', 12);
m = mean(accMtlSiftLcs50(:,topK)); s = std(accMtlSiftLcs50(:,topK));
errorbar(1:numel(m), m, s, '-', 'Color', ColorMtl, 'LineWidth', LineWidth);

plot(1, GoodWorkersAccuracy, 'o', 'Color', ColorHuman, 'LineWidth', LineWidth);

xlabel('Number of guesses');
ylabel('Accuracy (%)');
legend('STL-SDCA, Sqr, SIFT+LCS+PN+L2', 'MTL-SDCA, Sqr, SIFT+LCS+PN+L2', 'Human, 1 guess', 'Location', 'South');

printpdf('topkaccuracysiftcolor');

