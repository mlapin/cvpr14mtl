function [A,Kw,info,scores,acc,timing] = mtltraintest_onevsall(Ytrn, Ktrn, KZtrn, Ytst, Ktst, lambda, mu)

tWall = tic; tCpu = cputime;
[A,Kw,info] = mtlsdca(Ytrn,Ktrn,KZtrn,lambda,mu,'Epsilon',1e-3,'SvmEpsilon',1e-3,'UEpsilon',1e-3);
timing.wallTimeTrn = toc(tWall) ; timing.cpuTimeTrn = cputime - tCpu ;

tWall = tic; tCpu = cputime;
scores = Kw * A' * Ktst ;
[~,preds] = max(scores) ;
acc = mean(preds == Ytst) ;
timing.wallTimeTst = toc(tWall) ; timing.cpuTimeTst = cputime - tCpu ;
