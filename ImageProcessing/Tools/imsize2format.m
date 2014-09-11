function format = imsize2format(isize)
%
% format = imsize2format(isize)
%
% description:
%     tries to guess the format of an image with size isize
%     channel dimension is detected as having dimensions <= cmaxsize = 3
% 
% input:
%     isize    image size
%
% output:
%     format:
%     'pq'   = p x q matrix = 'pq' (2D grayscale)
%     'pqwc'  = p x q x c matrix (2D multi channel )
%     'pql'  = p x q x l matrix (3D)
%     'pqcl' = p x q x c x l matrix (3D multi channel image, matlab ordering)
%     'pqlc' = p x q x l x c matrix (3D multi channel image)
%     'pqlt'  = p x q x l x t matrix (4D grayscale)
%     'pqclt' = p x q x c x l x t matrix (4D multi channel image, matlab ordering)
%     'pqlct' = p x q x l x c x t matrix (4D multi channel image, time last)
%     'pqlct' = p x q x l x t x c matrix (4D multi channel image, channel last)
%     ''  = not supported format
%     p = x pixel coordinate, q = y pixel coordinate, l = z pixel coordinate, c = color, t = time
%
% note:
%     'pql' = 'pqt', 'pqcl' = 'pqct', 'pqlc' = 'pqtc'
% See also: imformat

cmaxsize = 3;  % max size for channel dimension

dim = length(isize);

format = '';

if dim < 2 || dim > 5
   return
end

switch dim
   case 2
      format = 'pq';
   case 3
      if isize(3) <= cmaxsize
         format = 'pqc';
      else
         format = 'pql';
      end
   case 4
      if isize(3) <= cmaxsize
         format = 'pqcl';
      elseif isize(4) <= cmaxsize
         format = 'pqlc';
      else
         format = 'pqlt';
      end
   case 5
      if isize(3) <= cmaxsize
         format = 'pqclt';
      elseif isize(4) <= cmaxsize
         format = 'pqlct';
      elseif isize(5) <= cmaxsize
         format = 'pqltc';
      else
         format = 'pqlct';
      end     
end

end
      
   




