function varargout = plotframe(varargin)
% VL_PLOTFRAME  Plot feature frame
%  VL_PLOTFRAME(FRAME) plots the frames FRAME.  Frames are attributed
%  image regions (as, for example, extracted by a feature detector). A
%  frame is a vector of D=2,3,..,6 real numbers, depending on its
%  class. VL_PLOTFRAME() supports the following classes:
%
%  Point::
%    FRAME(1:2) are the x,y coordinates of the point
%
%  Circle::
%    FRAME(1:2) are the x,y coordinates of the center. FRAME(3)
%    is the circle radius..
%
%  Oriented circle::
%    FRAME(1:2) are the x,y coordiantes of the center. FRAME(3) is the
%    radius. FRAME(4) is the orientation, expressed as a ppsitive
%    rotation (note that images use a left-handed system with the Y
%    axis pointing downwards).
%
%  Ellipse::
%    FRAME(1:2) are the x,y coordiantes of the center. FRAME(3:5) are
%    the element S11, S12, S22 of a 2x2 covariance matrix S (a positive
%    semidefinite matrix) defining the ellipse shape. The ellipse
%    is the set of points {x + T: x' inv(S) x = 1}, where T is the center.
%
%  Oriented ellipse::
%    FRAME(1:2) are the x,y coordiantes of the center. FRAME(3:6) is
%    the column-wise stacking of a 2x2 matrix A defining the ellipse
%    shape and orientation. The ellipse is obtaine by transforming
%    a unit circle by A as the set of points {A x + T : |x| = 1}, where
%    T is the center.
%
%  All frames can be thought of as an affine transformation of the unit circle.
%  For unoriented frames, the affine transformation is selected so that
%  the positive Y direction (downwards, graviy vector) is preserved.
%
%  H = VL_PLOTFRAME(...) returns the handle H of the graphical object
%  representing the frames.
%
%  VL_PLOTFRAME(FRAMES) for a matrix of FRAMES plots multiple frames.
%  Using this call is much faster than calling VL_PLOTFRAME() for each frame.
%
%  VL_PLOTFRAME(FRAMES,...) passes any extra argument to the
%  underlying plot function. The first optional argument can be a line
%  specification string such as the one used by PLOT().
%
%  See also: VL_FRAME2OELL(), VL_HELP().
[varargout{1:nargout}] = vl_plotframe(varargin{:});
