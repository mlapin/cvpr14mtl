%
% Show experimental results reported in the paper:
%
% Maksim Lapin, Bernt Schiele and Matthias Hein
% Scalable Multitask Representation Learning for Scene Classification
% CVPR 2014
%

clc;
clear all;
cd(fileparts(mfilename('fullpath')))

%% Toy datasets
fprintf('Table 1: USPS/MNIST:\n\n');

cd usps
results;
cd ..

cd mnist
results;
cd ..

%% SUN397
clear all;
cd matlab;
myinit;

fprintf('Table 2: SUN397 - first split:\n\n');
resSplitOne;

fprintf('\n');
fprintf('Table 3: SUN397 - all splits:\n\n');
resSplitAll;

fprintf('\n');
fprintf('Figure 1: SUN397 - top-K accuracies:\n\n');
resTopKAccuracy;

fprintf('\n');
fprintf('Figure (web page): SUN397 - comparison with previous work:\n\n');
resTeaserPlot;
cd ..
