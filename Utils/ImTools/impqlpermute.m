function pimg = impqlpermute(img, in_format, out_format)
%
% img = impqlpermute(img, in_format, out_format)
%
% description: 
%     takes a image and moves them into a format out_format assuming the in_format
%
% input:
%     img        input image
%     in_format  (optional) format of input image as characters (imformat(stack))
%     out_format (optional) format of output image, special names: 'matlab' = 'qpclt', 'imgj' = pqclt', ('matlab' = 'qpclt')
%
% output:
%     pimg       reshaped image
%
% note:
%     'x' = 'p', 'y' = reverse 'q', 'z' = 'l'
%
% See also: imformat

if nargin < 2 || isempty(in_format)
   in_format = imformat(img);
end
if nargin < 3 || isempty(out_format)  % autoconvert to matlab img format
   out_format = 'matlab';
end

if strcmp(in_format, 'matlab')
   in_format = 'qpclt';
end
if strcmp(out_format, 'matlab')
   out_format = 'qpclt';
end
if strcmp(in_format, 'imagej')
   in_format = 'pqclt';
end
if strcmp(out_format, 'imagej')
   out_format = 'pqclt';
end

if length(unique(in_format)) ~= length(in_format)
   error('impqlpermute: labels appear more than one in input format: %s', in_format)
end
if length(unique(out_format)) ~= length(out_format)
   error('impqlpermute: labels appear more than one in output format: %s', out_format)
end

%if length(in_format) ~= ndims(img) % matlab is inconssitent if last dimension is 1 
%   error('impqlpermute: input img and format inconsistent!')
%end

in_format = strrep(in_format, 'x', 'p');
in_format = strrep(in_format, 'z', 'l');

out_format = strrep(out_format, 'x', 'p');
out_format = strrep(out_format, 'z', 'l');

%reverse in y if requested
ypos = strfind(in_format, 'y');
if ~isempty(ypos)
   pimg = flip(img, ypos);
   in_format(ypos) = 'q';
else
   pimg = img;
end
ypos = strfind(out_format, 'y');
if ~isempty(ypos)
   out_format(ypos) = 'q';
end
%in_format
%out_format


%shape = ones(length(out_format),1);
for i = 1:length(out_format)
   sf = strfind(in_format, out_format(i));
   if ~isempty(sf)
      %shape(i) = size(img,sf(1));
   else
      in_format(end+1) = out_format(i);  %#ok<AGROW> % add to the end as this would introduce a new dimensions of size 1 in the original array
   end
end
%shape 
%in_format
%out_format



% find dimensions to squeeze 
for i = 1:length(in_format)
   sf = strfind(out_format, in_format(i));
   if isempty(sf) % removing of dimensions only if it is of size 1 (squeeze)
      if size(pimg,i) == 1
         out_format = [out_format, in_format(i)]; %#ok<AGROW> %% appending it effectively removes dimensions of size 1
      else
         error('impqlpermute: dimension %s not specified in output format %of but is non-trivial', in_format(i), out_format);
      end
   end
end
% now out_format and in_format have same size
%in_format
%out_format
%ypos

per = ones(1, length(in_format));
for i = 1:length(in_format)
   per(i) = strfind(in_format, out_format(i));
end
%per

% premute and reshape the img coordinates
pimg = permute(pimg, per);

%reverse in y if requested
if ~isempty(ypos)
   ypos = strfind(out_format, 'q');
   pimg = flip(pimg, ypos);
end

end
   