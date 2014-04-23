function [acc] = computeAllAccuracies(r, topAll)

n = numel(r);
fprintf('n = %g, topAll = %g\n', n, numel(topAll));

acc = nan(n, numel(topAll));
for i = 1:n
  fprintf('%s\n', r(i).fname);
  load(r(i).fname, 'scores');
  load(fullfile(fileparts(r(i).fname), 'imdb'), 'images');
  labels = images.class;
  tstIX = images.set == 3;
  if size(scores,2) > sum(tstIX)
    scores = scores(:,tstIX);
  end
  acc(i,:) = computeAccuracy(scores, labels(:,tstIX), topAll);
end
