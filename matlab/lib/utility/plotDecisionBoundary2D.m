function plotDecisionBoundary2D(X,Y,varargin)


classRange = unique(Y);
T = numel(classRange);
ScatterSize = 10;

minXY = min(X(1:2,:), [], 2);
maxXY = max(X(1:2,:), [], 2);

ax = [minXY(1) maxXY(1) minXY(2) maxXY(2)];

% Plot data
cmap = hsv(T);
for c=1:T
  scatter(X(1,Y==c), X(2,Y==c), ScatterSize, cmap(c,:));
end

axis(ax);

% Plot decision boundaries
cmap = lines(numel(varargin));
for c=1:numel(varargin)
  f = varargin{c};
  if isa(f, 'function_handle')
    h = ezplot(f, ax);
    set(h, 'LineWidth', 2.5, 'Color', cmap(c,:), 'LineStyle', '-');
  end
end



