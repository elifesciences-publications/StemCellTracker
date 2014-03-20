function rimage = impqlreshape(image, in_format, out_format)
%
% image = impqlreshape(image, in_format, out_format)
%
% description: 
%     takes a image and moves them into a format out_format assuming the in_format
%
% input:
%     image      input image
%     in_format  (optional) format of ipnut image as characters (imformat(stack))
%     out_format (optional) format of output image  ('matlab' = 'pqclt')
%
% output:
%     rimage      reshaped image
%
% note:
%     'matlab' here is defined as 'pqclt' which only corrects the color ordering not the x,y exchange !
%
% See also: imformat

if nargin < 2 || isempty(in_format)
   in_format = imformat(image);
end
if nargin < 3 || isempty(out_format)  % autoconvert to matlab image format
   out_format = 'matlab';
end

if strcmp(in_format, 'matlab')
   in_format = 'pqclt';
end
if strcmp(out_format, 'matlab')
   out_format = 'pqclt';
end
%if length(in_format) ~= ndims(image) % matlab is inconssitent if last dimension is 1 
%   error('impqlreshape: input image and format inconsistent!')
%end
if length(unique(in_format)) ~= length(in_format)
   error('impqlreshape: labels appear more than one in input format: %s', in_format)
end
if length(unique(out_format)) ~= length(out_format)
   error('impqlreshape: labels appear more than one in output format: %s', out_format)
end


%find output shape and possible additional dimensions
shape = ones(length(out_format),1);
k = 1;
for i = 1:length(out_format)
   sf = strfind(in_format, out_format(i));
   if ~isempty(sf)
      shape(i) = size(image,sf(1));
      of(k) = out_format(i);  %#ok<AGROW>
      k = k + 1;
   end
end

% find positions
k = 1;
for i = 1:length(in_format)
   sf = strfind(of, in_format(i));
   if isempty(sf) % removing of dimensions only if it is of size 1 (squeeze)
      if size(image,i) == 1
         siz = size(image); siz(i) = [];
         image = reshape(image, siz);
      else
         error('impqlreshape: dimension %s are not specified in format: %s', in_format(i), format);
      end
   else
      per(k) = sf(1); %#ok<AGROW>
      k = k + 1;
   end
end

% premute and reshape the image coordinates
rimage = reshape(permute(image, per), shape(:)');

end
   