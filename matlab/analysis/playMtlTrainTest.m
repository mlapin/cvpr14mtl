function [A,Kw,info,scores,acc,timing]=playMtlTrainTest(Ytrn,Ktrn,Ytst,Ktst,C1,C2,stlA)

classes = unique(Ytrn);

Ztrn = stlA'*Ktrn;
KZtrn = Ztrn'*Ztrn;
lambda = 1/(C1*size(Ktrn,1));
mu = 1/(C2*size(Ktrn,1)*numel(classes));

[A,Kw,info,scores,acc,timing] = mtltraintest_onevsall(Ytrn,Ktrn,KZtrn,Ytst,Ktst,lambda,mu);

fprintf('Selected model:\n');
fprintf('  C1 = %g (lambda = %g), C2 = %g (mu = %g):\n', C1, lambda, C2, mu);
fprintf('Test accuracy: %5.2f%%\n', 100*acc);
