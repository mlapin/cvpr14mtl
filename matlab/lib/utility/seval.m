function [varargout] = seval(FNAME, varargin)
%SEVAL Evaluate the specified script.
%   SEVAL(FNAME, x1, ..., xn) evaluates the script specified by
%   the FNAME parameter which is a path to the script file.
%
%   Note: The script can use varargin to access the input parameters.

if ~exist(FNAME, 'file')
  error('SEVAL:FileNotFound', ...
    'File not found: %s\nCurrent directory: %s', FNAME, pwd);
end

fid = fopen(FNAME);
SCRIPT = fread(fid, '*char')';
fclose(fid);
clear fid;

varargout = {};
if isempty(SCRIPT)
  warning('SEVAL:EmptyFile', 'The script file is empty.');
elseif nargout > 0
  varargout = cell(1, nargout);
  [varargout{:}] = eval(SCRIPT);
else
  eval(SCRIPT);
end
