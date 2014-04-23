function splits()
%SPLITS Create individual split files per file extension

% Make sure the folders exist
warning('off', 'MATLAB:MKDIR:DirectoryExists');
mkdir('jpg');
mkdir('png');

splitsFile = 'split10';

S = load(splitsFile);
S = S.split;

% Create individual split files
for i = 1:numel(S)
  fname = sprintf('jpg/%s_%02d.mat', splitsFile, i);
  fprintf('Creating split %s\n', fname);
  split = S{i}; %#ok<NASGU>
  save(fname, 'split', '-v7');
end

% Replace extensions
for i = 1:10
    fname = sprintf('png/%s_%02d.mat', splitsFile, i);
    fprintf('Creating split %s\n', fname);
    split = load(sprintf('jpg/%s_%02d.mat', splitsFile, i));
    split = split.split;
    for j = 1:numel(split)
        for k = 1:numel(split{j}.Training)
            split{j}.Training{k} = regexprep(split{j}.Training{k}, ...
                '^(.*)\.jpg$','$1.png');
        end
        for k = 1:numel(split{j}.Testing)
            split{j}.Testing{k} = regexprep(split{j}.Testing{k}, ...
                '^(.*)\.jpg$','$1.png');
        end
    end
    save(fname, 'split', '-v7');
end
