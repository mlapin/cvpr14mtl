function [mACC] = svmtraintest_kfolds(Ytrain, Ktrain, svmC, folds)

ACC = repmat(-Inf, size(folds, 1), 1) ;
for k = 1:size(folds, 1)
  trn = ~folds(k,:) ;
  tst = folds(k,:) ;
  Ytrn = Ytrain(trn) ;
  Ytst = Ytrain(tst) ;
  Ktrn = Ktrain(trn,trn) ;
  Ktst = Ktrain(trn,tst) ;
  lambda = 1 / (svmC * size(Ktrn,1)) ;
  [~,~,~,acc] = svmtraintest_onevsall(Ytrn, Ktrn, Ytst, Ktst, lambda) ;
  ACC(k) = acc ;
end
mACC = mean(ACC) ;
