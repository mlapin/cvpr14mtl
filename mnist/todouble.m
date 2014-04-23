function [a]=todouble(a)
%TODOUBLE If input is char, convert it to double.
if ischar(a), a=str2double(a); end
