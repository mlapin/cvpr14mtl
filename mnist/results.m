
clear all;

eps1 = 1e-3;
eps2 = 1e-3;
normalize = true;
addbias = false;
Ns = [5 10 20 50 100];
resFolder = 'results';
texFile = 'table.tex';

acc = nan(numel(Ns), 2);
dev = nan(numel(Ns), 2);
for i = 1:numel(Ns)
  Npos = Ns(i);
  clear accuracy;

  f = dir(sprintf('%s/results_%03d_%e_%e_%g_%g_*', resFolder, Npos, eps1, eps2, normalize, addbias));
  assert(numel(f) == 1);

  load(fullfile(resFolder, f.name), 'accuracy');
  assert(all(isfinite(accuracy(:))));
  assert(all(accuracy(:) > 0));

  acc(i,:) = mean(accuracy);
  dev(i,:) = std(accuracy) ./ sqrt(size(accuracy,1));
end

res(1,:,:) = acc;
res(2,:,:) = dev;

[~,dataset] = fileparts(pwd);
fprintf('Dataset: %s\n', dataset);
fprintf('& %.1f (%.1f) ', res(:,:,1));
fprintf('\\\\\n');
fprintf('& %.1f (%.1f) ', res(:,:,2));
fprintf('\\\\\n');
fprintf('MTL is better:\n');
disp(acc(:,1)' < acc(:,2)');
