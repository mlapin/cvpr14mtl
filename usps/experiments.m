function experiments(Npos,eps1,eps2,normalize,addbias,usedouble)

if nargin < 1, Npos = 5; end
if nargin < 2, eps1 = 1e-3; end
if nargin < 3, eps2 = 1e-3; end
if nargin < 4, normalize = 1; end
if nargin < 5, addbias = 0; end
if nargin < 6, usedouble = 0; end
Npos = todouble(Npos);
eps1 = todouble(eps1);
eps2 = todouble(eps2);
normalize = todouble(normalize);
addbias = todouble(addbias);
usedouble = todouble(usedouble);

diary off;
randn('state', 0) ;
rand('state', 0) ;

suffix = datestr(now, 'yyyy-mm-dd_HH-MM-SS_FFF');
suffix = sprintf('%03d_%e_%e_%g_%g_%s', Npos, eps1, eps2, normalize, addbias, suffix);
diary(sprintf('logs/diary_%s.txt', suffix));
resultName = sprintf('results/results_%s.mat', suffix);
diary on;
[~,hostname] = system('hostname');
fprintf('host: %s\n', hostname);

fprintf('Npos = %g\n', Npos);

Cs = 2.^(-12:12);
C1s = 2.^(-12:2);
C2s = 2.^(0:12);

disp(C1s);
disp(C2s);

NumSplits = 5;

load split1_usps_1000train.mat;
X = [digit_trainx' digit_validx'];
Y = [digit_trainy' digit_validy'];

Xtst = digit_testx';
Ytst = digit_testy';

clear digit*;

[D,N] = size(X);
classRange = unique(Y);
T = numel(classRange);

SvmParams = {'Epsilon', eps1};
MtlParams = {'Epsilon', eps2, 'SvmEpsilon', eps1, 'UEpsilon', eps1};
disp(SvmParams);
disp(MtlParams);

if normalize
  norm2(X); norm2(Xtst); fprintf('Normalized features.\n');
end
if addbias
  X = [X; ones(1,size(X,2))];
  Xtst = [Xtst; ones(1,size(Xtst,2))];
  fprintf('Added bias.\n');
end

if usedouble
  X = double(X);
  Xtst = double(Xtst);
  fprintf('Use double.\n');
else
  X = single(X);
  Xtst = single(Xtst);
  fprintf('Use single.\n');
end


Ktrain = X' * X;
Ktest = X' * Xtst;

exStartTime = tic;
accuracy = zeros(NumSplits,2);
accuracySvm = zeros(NumSplits,2,numel(Cs));
accuracyMtl = zeros(NumSplits,2,numel(C1s),numel(C2s));
regulSvm = cell(NumSplits,numel(Cs));
regulMtl = cell(NumSplits,numel(C1s),numel(C2s));
infoSvm = cell(NumSplits,numel(Cs));
infoMtl = cell(NumSplits,numel(C1s),numel(C2s));
bestRegulSvm = cell(NumSplits,1);
bestRegulMtl = cell(NumSplits,1);
bestInfoSvm = cell(NumSplits,1);
bestInfoMtl = cell(NumSplits,1);
idx = false(N,NumSplits);
for split = 1:NumSplits
  
  % Permutation
  trn = false(N,1) ;
  for c = 1:numel(classRange)
    classInd = find(Y == c) ;
    permInd = randperm(numel(classInd)) ;
    trn(classInd(permInd(1:Npos))) = true;
  end
  val = ~trn;

  idx(:,split) = trn;
  Ytrn = Y(trn);
  Yval = Y(val);
  
  Ktrn = Ktrain(trn,trn);
  Kval = Ktrain(trn,val);
  Ktst = Ktest(trn,:);
  
  % Model selection: train and test
  for C1i = 1:numel(Cs)
    C1 = Cs(C1i);
    fprintf('C = %g\n', C1);
    diary off; diary on;

    lambda = 1/(C1*sum(trn));

    [A,info] = svmsdca(Ytrn,Ktrn,lambda,SvmParams{:});
    
    [~,preds] = max(A'*Kval);
    accuracySvm(split,1,C1i) = 100*mean(preds == Yval);
    [~,preds] = max(A'*Ktst);
    accuracySvm(split,2,C1i) = 100*mean(preds == Ytst);
    regulSvm{split,C1i} = C1;
    infoSvm{split,C1i} = info;
  end

  % Best parameters
  [~,ind] = max(accuracySvm(split,1,:)); % max accuracy on the validation set
  C1 = regulSvm{split,ind};
  lambda = 1/(C1*sum(trn));
  
  fprintf('\nBest SVM parameters:\n  C1 = %g\n  lambda = %g\n', C1, lambda);
  
  A = svmsdca(Ytrn,Ktrn,lambda,SvmParams{:});
  % U0 = X * A;
  % Z = U0' * X = A' * Ktrn;
  % Kz = Z' * Z = Ktrn * A * A' * Ktrn;
  Kz = Ktrn * A;
  Kz = Kz * Kz';
    
  for C1i = 1:numel(C1s)
    C1 = C1s(C1i);
    fprintf('C1 = %g\n', C1);
    diary off; diary on;
    for C2i = 1:numel(C2s)
      C2 = C2s(C2i);
      fprintf('C2 = %g\n', C2);
      diary off; diary on;

      lambda = 1/(C1*sum(trn));
      mu = 1/(C2*sum(trn)*T);

      [A,Kw,info] = mtlsdca(Ytrn,Ktrn,Kz,lambda,mu,MtlParams{:});

      [~,preds] = max(Kw * A' * Kval);
      accuracyMtl(split,1,C1i,C2i) = 100*mean(preds == Yval);
      [~,preds] = max(Kw * A' * Ktst);
      accuracyMtl(split,2,C1i,C2i) = 100*mean(preds == Ytst);
      regulMtl{split,C1i,C2i} = [C1,C2];
      infoMtl{split,C1i,C2i} = info;
    end

    diary off;
    save(resultName, 'accuracy', 'accuracySvm', 'accuracyMtl', ...
      'regulSvm', 'regulMtl', 'bestRegulSvm', 'bestRegulMtl', ...
      'infoSvm', 'infoMtl', 'bestInfoSvm', 'bestInfoMtl', ...
      'C1s', 'C2s', 'idx', 'Npos', 'eps1', 'eps2', 'normalize', 'addbias', 'usedouble',  '-v7');
    diary on;
  end

  % Best parameters
  [~,ind] = max(accuracySvm(split,1,:)); % max accuracy on the validation set
  bestRegulSvm{split} = regulSvm{split,ind};
  bestInfoSvm{split} = infoSvm{split,ind};
  accuracy(split,1) = accuracySvm(split,2,ind); % accuracy on the test set
  
  [~,ind] = max(accuracyMtl(split,1,:)); % max accuracy on the validation set
  bestRegulMtl{split} = regulMtl{split,ind};
  bestInfoMtl{split} = infoMtl{split,ind};
  accuracy(split,2) = accuracyMtl(split,2,ind); % accuracy on the test set
  
  fprintf('Best solution infos:\n  SVM:\n');
  disp(bestInfoSvm{split});
  fprintf('  MTL:\n');
  disp(bestInfoMtl{split});
  
  fprintf('Best parameters:\n  SVM: C = %g\n', bestRegulSvm{split});
  fprintf('  MTL: C1 = %g, C2 = %g\n', bestRegulMtl{split});

  fprintf('Accuracy:\n  SVM: %.2f\n  MTL: %.2f\n', accuracy(split,:));

  diary off;
  save(resultName, 'accuracy', 'accuracySvm', 'accuracyMtl', ...
    'regulSvm', 'regulMtl', 'bestRegulSvm', 'bestRegulMtl', ...
    'infoSvm', 'infoMtl', 'bestInfoSvm', 'bestInfoMtl', ...
    'C1s', 'C2s', 'idx', 'Npos', 'eps1', 'eps2', 'normalize', 'addbias', 'usedouble',  '-v7');
  diary on;

end

fprintf('\nMean accuracy:\n  SVM: %.2f (%.2f)\n  MTL: %.2f (%.2f)\n', ...
  [mean(accuracy); std(accuracy)/sqrt(NumSplits)]);

fprintf('\nCompleted experiment: %s\n', sec2str(toc(exStartTime))) ; 
diary off;
