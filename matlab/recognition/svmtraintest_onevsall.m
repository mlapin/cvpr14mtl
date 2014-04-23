function [A,info,scores,acc,timing] = svmtraintest_onevsall(Ytrn, Ktrn, Ytst, Ktst, lambda)

tWall = tic; tCpu = cputime;
[A,info] = svmsdca(Ytrn,Ktrn,lambda,'Epsilon',1e-3) ;
timing.wallTimeTrn = toc(tWall) ; timing.cpuTimeTrn = cputime - tCpu ;

tWall = tic; tCpu = cputime;
scores = A' * Ktst ;
[~,preds] = max(scores) ;
acc = mean(preds == Ytst) ;
timing.wallTimeTst = toc(tWall) ; timing.cpuTimeTst = cputime - tCpu ;
