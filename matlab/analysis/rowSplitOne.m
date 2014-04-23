function rowSplitOne(r,ix,iN05,iN10,iN20,iN50,iKlin,iKhel,iKchi)
% Display a row of results in Table 2 (Split 1)

assert(sum(ix) == 12);

displayAccuracy(r(ix & iN05 & iKlin));
displayAccuracy(r(ix & iN05 & iKhel));
displayAccuracy(r(ix & iN05 & iKchi));
displayAccuracy(r(ix & iN10 & iKlin));
displayAccuracy(r(ix & iN10 & iKhel));
displayAccuracy(r(ix & iN10 & iKchi));
displayAccuracy(r(ix & iN20 & iKlin));
displayAccuracy(r(ix & iN20 & iKhel));
displayAccuracy(r(ix & iN20 & iKchi));
displayAccuracy(r(ix & iN50 & iKlin));
displayAccuracy(r(ix & iN50 & iKhel));
displayAccuracy(r(ix & iN50 & iKchi));
fprintf('%s\n', '\\');

end

function displayAccuracy(r)
assert(numel(r) == 1);
fprintf('& %.1f ', r.mAcc);
end
