function [Cs, mACCs] = svmtraintest_modelselection(classRange, Ytrn, Ktrn, Cs, k)

randn('state', 0) ;
rand('state', 0) ;

folds = false(k, size(Ktrn, 1)) ;
for c = 1:numel(classRange)
  classInd = find(Ytrn == classRange(c)) ;
  permInd = randperm(numel(classInd)) ;
  for fold = 1:k
    sel = mod(permInd, k) == (fold - 1) ;
    folds(fold, classInd(permInd(sel))) = true ;
  end
end

mACCs = repmat(-Inf, numel(Cs), 1) ;
for i = 1:numel(Cs)
  [mACCs(i)] = svmtraintest_kfolds(Ytrn, Ktrn, Cs(i), folds) ;
end

Cs = Cs(:) ;
fprintf('Model selection (all):\n') ;
fprintf('C = %e -> mACC = %5.2f\n', ([Cs, 100*mACCs]')) ;
