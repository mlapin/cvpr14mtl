function [str] = sec2str(seconds)
%SEC2STR Convert seconds to a formatted string.
% [str]=SEC2STR(seconds) Converts seconds to a string
% using format 'dd.HH:MM:SS.FFF'.
str = datestr(datenum(0,0,0,0,0,seconds),'dd.HH:MM:SS.FFF');
