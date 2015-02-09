%======================================================================
%SLIC demo
% Copyright (C) 2015 Ecole Polytechnique Federale de Lausanne
% File created by Radhakrishna Achanta
% Please also read the copyright notice in the file slicmex.c 
%======================================================================
%Input parameters are:
%[1] 8 bit images (color or grayscale)
%[2] Number of required superpixels (optional, default is 200)
%[3] Compactness factor (optional, default is 10)
%
%Ouputs are:
%[1] labels (in raster scan order)
%[2] number of labels in the image (same as the number of returned
%superpixels
%
%NOTES:
%[1] number of returned superpixels may be different from the input
%number of superpixels.
%[2] you must compile the C file using mex slicme.c before using the code
%below
%======================================================================

img8 = imrescale(imgf, 'class', 'uint8');

[labels, numlabels] = slicmex(img8,3500,7); %numlabels is the same as number of superpixels

figure(4)
implot(imcolorize(labels));

lbssurf = impixelsurface(labels);
figure(1); clf
implot(imoverlaylabel(imgf, lbssurf, false));

