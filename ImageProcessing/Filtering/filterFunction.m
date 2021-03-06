function out = filterFunction(img, ksize, func, padding, chunkfactor)
%
% out = filterFunction(img, ksize, func, padding)
%
% description:
%     replaces each pixel by applying the function fun to the vector of 
%     values in the neighbourhood specified by radius
%
% input:
%     img            img to filter (2d or 3d grayscale)
%     ksize            h x w (x l) filter size
%     func             name or handle to function applied to an array of values 
%                      with row corresponding to values in a pixel neighbourhood
%                      e.g. for a median fitler use func = @(x)(median(x,2))
%                      possible names: 'median', 'min', 'max'
%     padding          padding option for fitering at boundaries ('symmetric')
%
% output:
%     out              filtered img
%
% See also: filterMeanShift, filterBilateral, filterMedian


% prolog


if isscalar(img), out = img; return, end
sizI = size(img);
d = ndims(img);

if d < 1 || d > 3
   error('filterFunction: img should be 1d, 2d or 3d gray scale img')
end


if nargin < 2
   ksize = 3;
else
   ksize = ksize(:)';
end


if numel(ksize)==2
    ksize = [ksize 1];
elseif isscalar(ksize)
    if sizI(1)==1
        ksize = [1 ksize 1];
    else
        ksize = [ksize 1 1];
    end
end

if nargin < 3
   func = @(x)(median(x,2));
elseif ischar(func)
   switch func
      case 'median'
        func = @(x)(median(x,2));
      case 'min'
        func = @(x)(min(x,[],2));
      case 'max'
        func = @(x)(max(x,[],2));
      case 'std'
        func = @(x)(std(double(x),0, 2));
      case 'var'
        func = @(x)(var(double(x),0, 2));     
   end
end

if nargin < 4
   padding = 'replicate';
end

if nargin < 5
    chunkfactor = 1;
end
if chunkfactor<1, chunkfactor = 1; end

% class0 = class(img);
% if ~isa(img,'float')
%     img = double(img);
% end


% initialize 

N = numel(img);
radius = ceil((ksize-1)/2);
n = prod(2*radius+1);
if n==1, out = img; return, end
nchunk = (1:ceil(N/n/chunkfactor):N);
if nchunk(end)~=N, nchunk = [nchunk N]; end

out = img;
img = padarray(img, radius, padding);
sizP = size(img);
if numel(sizI)==2
    sizI = [sizI 1];
    sizP = [sizP 1];
end

% Creating the index arrays (INT32)
inc = zeros([3 2*radius+1],'int32');
radius = int32(radius);
[inc(1,:,:,:), inc(2,:,:,:), inc(3,:,:,:)] = ndgrid(...
    [0:-1:-radius(1) 1:radius(1)],...
    [0:-1:-radius(2) 1:radius(2)],...
    [0:-1:-radius(3) 1:radius(3)]);
inc = reshape(inc,1,3,[]);

I = zeros([sizI 3],'int32');
sizI = int32(sizI);
[I(:,:,:,1), I(:,:,:,2), I(:,:,:,3)] = ndgrid(...
    (1:sizI(1))+radius(1),...
    (1:sizI(2))+radius(2),...
    (1:sizI(3))+radius(3));
I = reshape(I,[],3);


% Filtering

for i = 1:length(nchunk)-1

    Im = repmat(I(nchunk(i):nchunk(i+1),:),[1 1 n]);
    Im = bsxfun(@plus,Im,inc);

    I0 = Im(:,1,:) +...
        (Im(:,2,:)-1)*sizP(1) +...
        (Im(:,3,:)-1)*sizP(1)*sizP(2);
    I0 = squeeze(I0);
    
    out(nchunk(i):nchunk(i+1)) = func(img(I0));
end

%out = cast(out,class0);

end