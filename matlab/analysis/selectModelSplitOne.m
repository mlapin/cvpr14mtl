function selectModelSplitOne(r,ix,iN05,iN10,iN20,iN50,C1s,C2s)

if numel(C2s) == 1, figure; hold on; grid on; end

bestParameters(r(ix & iN05),C1s,C2s,'r');
bestParameters(r(ix & iN10),C1s,C2s,'g');
bestParameters(r(ix & iN20),C1s,C2s,'b');
bestParameters(r(ix & iN50),C1s,C2s,'m');

end

function bestParameters(r,C1s,C2s,c)
if numel(r) ~= numel(C1s)*numel(C2s), fprintf('!!!'); end

r = nestedSortStruct(r, {'mtl_C1', 'mtl_C2'});
[~,ix] = max([r.mAcc]);

n = r(1).info.NumExamples; T = r(1).info.NumTasks;
fprintf('  %4.1f: C1 = %e (lambda = %e), C2 = %e (mu = %e)\n', ...
  r(ix).mAcc, r(ix).mtl_C1, 1/r(ix).mtl_C1/n, r(ix).mtl_C2, 1/r(ix).mtl_C2/n/T);

if numel(C2s) == 1
  plot(log10([r.mtl_C1]), [r.mAcc],c);
  plot(log10(r(ix).mtl_C1), r(ix).mAcc,'o');
  text(log10(r(ix).mtl_C1), r(ix).mAcc+1, num2str(r(ix).mtl_C1));
  xlabel('C1, log10 scale');
elseif numel(r) == numel(C1s)*numel(C2s)
  figure; hold on; grid on; view(-45, 45);
  [x,y] = meshgrid(C1s, C2s);
  surf(log10(y), log10(x), reshape([r.mAcc], numel(C2s), numel(C1s)));
  plot3(log10(r(ix).mtl_C2), log10(r(ix).mtl_C1), r(ix).mAcc, 'o');
  xlabel('C2, log10 scale'); ylabel('C1, log10 scale');
  title(sprintf('Npos = %d', r(ix).numTrain));
end

end
