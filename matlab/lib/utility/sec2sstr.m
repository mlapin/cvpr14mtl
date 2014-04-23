function [str] = sec2sstr(seconds)
%SEC2SSTR Convert seconds to a short formatted string.
% [str]=SEC2SSTR(seconds) Converts seconds to a short string
if seconds < 60
  str = datestr(datenum(0,0,0,0,0,seconds),'SS');
elseif seconds < 60 * 60
  str = datestr(datenum(0,0,0,0,0,seconds),'MM:SS');
elseif seconds < 60 * 60 * 24
  str = datestr(datenum(0,0,0,0,0,seconds),'HH:MM:SS');
else
  str = datestr(datenum(0,0,0,0,0,seconds),'dd.HH:MM:SS');
end
