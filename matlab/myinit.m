addpath(pwd);
addpath(fullfile(pwd, 'analysis'));
addpath(fullfile(pwd, 'recognition'));

addpath(fullfile(pwd, 'lib', 'yael'));
addpath(fullfile(pwd, 'lib', 'utility'));
addpath(fullfile(pwd, 'lib', 'mtlsdca'));

run(fullfile(pwd, 'lib', 'vlfeat', 'toolbox', 'vl_setup.m'));
