function rowSplitAll(r,ix,iN05,iN10,iN20,iN50)
% Display a row of results in Table 3 (all splits)

assert(sum(ix) == 40);
% if sum(ix) ~= 40, fprintf('!!!'); end

displayAccuracy(r(ix & iN05));
displayAccuracy(r(ix & iN10));
displayAccuracy(r(ix & iN20));
displayAccuracy(r(ix & iN50));
fprintf('%s\n', '\\');

end

function displayAccuracy(r)
fprintf('& %.1f (%.1f) ', mean([r.mAcc]), std([r.mAcc]));
assert(numel(r) == 10);
% if numel(r) ~= 10, fprintf('!!!'); end
end
