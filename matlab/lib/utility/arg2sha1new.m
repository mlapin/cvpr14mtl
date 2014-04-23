function [sha1] = arg2sha1(varargin)
% ARG2SHA1 Compute SHA1 of the string representation of all input arguments

% Do not enclose a single argument into {}
if numel(varargin) == 1
  str = prettyprint(varargin{1});
else
  str = prettyprint(varargin);
end

varname = 'ARG2SHA1_STR';
setenv(varname, str);
[status, cmdout] = system(sprintf('echo "${%s}" | sha1sum', varname));

% Return the SHA1 substring or report an error
if status ~= 0
  error('ARG2SHA1:ERROR', ...
    'arg2sha1: sha1sum failed (exit %d): %s', status, cmdout);
else
  sha1 = cmdout(1:40);
end
