function [cvC,cvAcc,A,info,scores,acc,timing]=playSvmModelSelectionTrainTest(Ytrn,Ktrn,Ytst,Ktst,svmCs)

kfolds = 2;
classes = unique(Ytrn);

tic;
[Cs,mACCs] = svmtraintest_modelselection(classes,Ytrn,Ktrn,svmCs,kfolds);
toc;

[cvAcc,ix] = max(mACCs);
cvC = Cs(ix);

lambda = 1/(cvC*numel(Ytrn));
[A,info,scores,acc,timing] = svmtraintest_onevsall(Ytrn,Ktrn,Ytst,Ktst,lambda);

fprintf('Selected model (CV accuracy: %5.2f%%):\n', 100*cvAcc);
fprintf('  C = %g (lambda = %g):\n', cvC, lambda);
fprintf('Test accuracy: %5.2f%%\n', 100*acc);
