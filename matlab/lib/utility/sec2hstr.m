function [str] = sec2hstr(seconds)
%SEC2HSTR Convert seconds to a short human-readable string.
% [str]=SEC2HSTR(seconds) Converts seconds to a human-readable string
min = 60; hour = 60*min; day = 24*hour;
if seconds < min
  str = sprintf('%d sec', round(seconds));
elseif seconds < hour
  str = sprintf('%.1f mins', seconds/min);
elseif seconds < day
  str = sprintf('%.1f hours', seconds/hour);
else
  str = sprintf('%.1f days', seconds/day);
end
