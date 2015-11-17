function c = imarisrgb2statistics(r,g,b, nrgb)
%
% c = imarisrgb2statistics(rgb, nrgb)
%
% description:
%     convert a rgb color to a stistisctics value consistent with the colormap
%     generated by imarisrgbstatisticscolormap
%
% input:
%     rgb     rgb values [r,g,b]
%     ncols   (optional) number of different colors (256)
%
% output:
%    c        color indices for use with colormap.pal
%
% See also: imarisrgbstatisticscolormap

if nargin >= 3
   rgb = [r,g,b];
   if nargin < 4
      nrgb = 8;
   end
else
   rgb = r;
   if nargin < 2
      nrgb = 8;
   else
      nrgb = g;
   end 
end

% scale rgbs between 0 and nrgb-1
rgb = floor(rgb * (nrgb-1));
c = rgb * [1, nrgb, nrgb*nrgb]';
c = c / ( nrgb*nrgb*nrgb - 1);

end


