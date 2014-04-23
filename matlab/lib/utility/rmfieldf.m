function [s] = rmfieldf(s, field)
if iscell(field)
  for i = 1:numel(field)
    s = rmfieldf(s, field{i}) ;
  end
elseif isfield(s, field)
  s = rmfield(s, field) ;
end
