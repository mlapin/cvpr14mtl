function [t]=rowTimings(r,ix,iN05,iN10,iN20,iN50,tt)

assert(sum(ix) == 40);
% if sum(ix) ~= 40, fprintf('!!!'); end

t(1) = displayTime(r(ix & iN05),tt(1));
t(2) = displayTime(r(ix & iN10),tt(2));
t(3) = displayTime(r(ix & iN20),tt(3));
t(4) = displayTime(r(ix & iN50),tt(4));
fprintf('%s\n', '\\');

end

function [t]=displayTime(r,tt)
info = [r.info];
T = [info.CpuTime] + [r.KTtrn] + tt;
% t = mean(T);
% fprintf('& %s (%s) x %.1f ', sec2sstr(mean(T)), sec2sstr(std(T)), t/tt);
t = median(T);
fprintf('& %s (%s) x %.1f ', sec2sstr(median(T)), sec2sstr(std(T)), t/tt);
assert(numel(r) == 10);
end
