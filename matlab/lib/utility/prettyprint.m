function [str] = prettyprint(a, indent, instruct)
%PRETTYPRINT Pretty print MATLAB variables
%   [STR] = PRETTYPRINT(A) Pretty prints the variable A into a string STR.
%

if nargin < 2
  indent = '';
end
if nargin < 3
  instruct = false;
end

switch class(a)
  case {'int8', 'int16', 'int32', 'int64', ...
        'uint8', 'uint16', 'uint32', 'uint64', 'single', 'double'}
    str = mat2str(a);
  case {'logical'}
    if numel(a) == 1
      if a
        str = 'true';
      else
        str = 'false';
      end
    else
      str = mat2str(a);
    end
  case {'char'}
    str = sprintf('''%s''', strrep(a, '''', ''''''));
  case {'cell'}
    if instruct
      str = '{{';
    else
      str = '{';
    end
    [m,n] = size(a);
    for i = 1:m
      for j = 1:n
        str = sprintf('%s%s', str, prettyprint(a{i,j}, indent, false));
        if j < n
          str = sprintf('%s, ', str);
        end
      end
      if i < m
        str = sprintf('%s; ', str);
      end
    end
    if instruct
      str = sprintf('%s}}', str);
    else
      str = sprintf('%s}', str);
    end
  case {'struct'}
    if numel(a) > 1
      error('PRETTYPRINT:NOTSUPPORTED', ...
        'Arrays of structures are not supported.');
    end
    newindent = sprintf('%s  ', indent);
    str = sprintf('struct( ...\n');
    fnames = fieldnames(a);
    n = numel(fnames);
    for i = 1:n
      b = a.(fnames{i});
      str = sprintf('%s%s''%s'', %s', str, newindent, fnames{i}, ...
        prettyprint(b, newindent, true));
      if i < n
        str = sprintf('%s,', str);
      end
      str = sprintf('%s ...\n', str);
    end
    str = sprintf('%s%s)', str, indent);
  case {'function_handle'}
    str = func2str(a);
    if str(1) ~= '@'
      str = sprintf('@%s', str);
    end
  otherwise
    str = sprintf('''<%s>''', class(a));
end
