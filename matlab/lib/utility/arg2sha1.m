function [sha1] = arg2sha1(varargin)
% ARG2SHA1 Compute SHA1 of the string representation of all input arguments

% Do not enclose a single argument into {}
if numel(varargin) == 1
  str = prettyprint(varargin{1});
else
  str = prettyprint(varargin);
end

% Strip the newline and double quote characters, then echo to sha1sum
[status, cmdout] = system(sprintf('echo "%s1" | sha1sum', ...
  regexprep(str, '[\n"]', '')));

% Return the SHA1 substring or report an error
if status ~= 0
  error('ARG2SHA1:ERROR', ...
    'arg2sha1: sha1sum failed (exit %d): %s', status, cmdout);
else
  sha1 = cmdout(1:40);
end
