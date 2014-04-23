function varargout = frame2oell(varargin)
% FRAMES2OELL   Convert generic feature frames to oriented ellipses
%   EFRAMES = VL_FRAME2OELL(FRAMES) converts the specified FRAMES to
%   the oriented ellipses EFRAMES.
%
%   A frame is either a point, disc, oriented disc, ellipse, or
%   oriented ellipse. These are represened respecively by
%   2, 3, 4, 5 and 6 parameters each, as described in VL_PLOTFRAME().
%
%   An oriented ellipse is the most general frame. When an unoriented
%   frame is converted to an oriented ellipse, the rotation is selected
%   so that the positive Y direction is unchanged.
%
%   See: VL_PLOTFRAME(), VL_HELP().
[varargout{1:nargout}] = vl_frame2oell(varargin{:});
