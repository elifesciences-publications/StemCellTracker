%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Brain Slices %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all
close all

initialize()
bfinitialize
%initializeParallelProcessing(12)

addpath('./Scripts/User/Zeeshan/BrainSlices/2015_11');

%datadir = '/data/Science/Projects/StemCells/Experiment/BrainSections_2015_11/';
datadir = '/home/ckirst/Science/Projects/StemCells/Experiment/BrainSections_2015_11/';

dataname = 'PCW10 Sample G CTIP2 SATB2 TBR1 NURR1';

datafield = ' 1';

verbose = true;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Data Source %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

is = ImageSourceBF([datadir  dataname '.lsm']);
clc
is.printInfo

%%

is.setReshape('S', 'Uv', [8, 17]);
is.setCellFormat('UV')
is.setRange('C', 1);
clc; is.printInfo

%%
%is.setRange('C', 1);
%is.plotPreviewStiched('overlap', 102, 'scale', 0.1);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Inspect Data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%region = struct('U', [8:11], 'V', [9:12], 'C', 1);
%region = struct('U', 10, 'V', 11, 'C', 1, 'X', 1:300, 'Y', 1:300);
%region = struct('U', 10, 'V', 11, 'C', 1);
region = struct('U', 6:7, 'V', 12:13, 'C', 1);

imgs = is.cell(region);
size(imgs)

if verbose > 1
   figure(1); clf
   implottiling(imgs, 'link', false)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Align
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc
sh = alignImages(imgs, 'alignment', 'RMS', 'overlap.max', 150);
stmeth = 'Interpolate';
%stmeth = 'Pyramid';

if verbose > 1
   img = stitchImages(imgs, sh, 'method', stmeth);
   figure(1); clf; implot(img)
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Stich Data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% nuclear marker
is.resetRange();

nch = 5;

imgsDAPI  = is.cell(region, 'C', 1);
imgsTBR1  = is.cell(region, 'C', 2);
imgsSATB2 = is.cell(region, 'C', 3);
imgsCTIP2 = is.cell(region, 'C', 4);
imgsNURR1  = is.cell(region, 'C', 5);

imgsAllRaw = {imgsSATB2, imgsCTIP2, imgsTBR1, imgsNURR1, imgsDAPI};

chlabel = {'SATB2', 'CTIP2', 'TBR1', 'NURR1', 'DAPI'};

chcols  = {[1,0,0], [0,1,0], [1,1,0], [1, 0, 1], [0,0,1]};
cm      = {'r',      'g',    'y',     'm',       'b'};

%% Test Preprocessing
% 
% for i  = [4]
%    imgsAll{i} = imgsAllRaw{i}(1:2);
%    imgsAll{i} = cellfunc(@(x) filterMedian(x, 3), imgsAll{i});
%    imgsAll{i} = cellfunc(@(x) x - imopen(x, strel('disk', 75)), imgsAll{i});   
%    imgsAll{i} = cellfunc(@(x) x - imopen(x, strel('disk', 10)), imgsAll{i});   
% end
%    
% figure(12); clf;
% implottiling({imgsAllRaw{i}{1:2}; imgsAll{i}{:}})

%% Preprocess

parfor i = 1:nch
   imgsAll{i} = imgsAllRaw{i};
   %thrs = 0 * [0, 720, 430, 0, 600];
   %imgsAll{i} = cellfunc(@(x) (x > thrs(i)) .* x,  imgsAll{i});
   %imgsAll{i} = cellfunc(@(x) x - imopen(x, strel('disk', 100)), imgsAll{i});   
   %imgsAll{i} = cellfunc(@(x) x - imopen(x, strel('disk', 10)), imgsAll{i});   
   %imgsAll{i} = cellfunc(@(x) filterAutoContrast(x/max(x(:))), imgsAll{i});
   imgsAll{i} = cellfunc(@(x) filterMedian(x, 3), imgsAll{i});
   imgsAll{i} = cellfunc(@(x) x - imopen(x, strel('disk', 75)), imgsAll{i});   
   imgsAll{i} = cellfunc(@(x) x - imopen(x, strel('disk', 10)), imgsAll{i});   
end

%%
imgsSt = cell(1,nch);
imgsStRaw = cell(1,nch);

for i = 1:nch
   imgsStRaw{i} = stitchImages(imgsAllRaw{i}, sh, 'method', stmeth);
   imgsStRaw{i} = mat2gray(imgsStRaw{i});
   
   
   imgSt = stitchImages(imgsAll{i}, sh, 'method', stmeth);
   
   %imgSt = imgSt - imopen(imgSt, strel('disk', 20));
   %imgsS = filterAutoContrast(imgsS/max(imgsS(:)));
   
   if verbose
      figure(16);
      subplot(nch+1,1,i); 
      hist(imgSt(:), 256);
   end
   
   imgsSt{i} = mat2gray(imgSt);
   %imgsSt{i} = mat2gray(imclip(imgSt, 0, cl(i)));
   
end

if verbose
   figure(1); clf; colormap jet
   set(gcf, 'Name', 'Stitched and Preprocessed Data')
   implottiling({imgsSt{:}; imgsStRaw{:}}', 'titles', {chlabel{:}, chlabel{:}})
end

%% Save preporcessing state

savefile = [datadir, dataname, datafield, '.mat'];
%save(savefile)
%load(savefile)

%%

nch = 5;

weights = [0.5, 0.5, 0.5, 0, 1]; % exclude NURR1 as it is fuzzy
chcols  = {[1,0,0], [0,1,0], [1,1,0], [1, 0, 1], [0,0,1]};

imgsWs = cellfunc(@(x,y) x * y, imgsSt(1:nch), num2cell(weights));

imgC = zeros([size(imgsWs{1}), 3]);
for i = 1:nch
   for c = 1:3
      imgC(:,:,c) = imgC(:,:,c) + chcols{i}(c) * (imgsWs{i}); % - imopen(imgsWs{i}, strel('disk', 10)));
   end
end
    
%imgC = imclip(imgC, 0, 2500);
imgC = imgC / max(imgC(:));
imgC = filterAutoContrast(imgC);

imgI = sum(imgC,3);

if verbose
   figure(2); clf;
   set(gcf, 'Name', 'Data')
   implottiling({imgC, imgsSt{5}, imgI}', 'titles' , {'color','DAPI','intensity'});
end

%% Restrict to sub regoin
sub = false;
subregion = {550:2000, 100:400};

if sub
   imgCsub = imgC(subregion{1}, subregion{2}, :);
   
   if verbose
      figure(4); clf
      implot(imgCsub)
   end
    
   imgC = imgCsub;
   for i = 1: length(imgsSt)
      imgsSt{i} = imgsSt{i}(subregion{:});
      imgsStRaw{i} = imgsStRaw{i}(subregion{:});
   end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Mask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%figure(1); clf; colormap jet
%implottiling(imgsSt, 'titles', chlabel)

%imgm =  imgsSt{5} - imopen(imgsSt{5} , strel('disk', 10));
imgm = imgsSt{5};

imgmaskLo = imgm > 0.1;
imgmaskLo = imopen(imgmaskLo, strel('disk', 2));
imgmaskLo = postProcessSegments(bwlabeln(imgmaskLo), 'volume.min', 15, 'fillholes', false) > 0;


%figure(66); clf;
%implottiling({255*(postProcessSegments(bwlabeln(imgmaskLo), 'volume.min', 10, 'fillholes', false)>0); 2*(bwlabeln(imgmaskLo)); 255*imgmaskLo}')

%get rid of blod vessels
imgmaskHi1 = imgsStRaw{4} > 0.9;
imgmaskHi1 = imdilate(imgmaskHi1, strel('disk', 3));
imgmaskHi1 = postProcessSegments(bwlabeln(imgmaskHi1), 'volume.min', 100, 'fillholes', false) > 0;
imgmaskHi1 = not(imgmaskHi1);

imgmaskHi2 = imgsStRaw{1} > 0.2;
imgmaskHi2 = imdilate(imgmaskHi2, strel('disk', 3));
imgmaskHi2 = postProcessSegments(bwlabeln(imgmaskHi2), 'volume.min', 100, 'fillholes', false) > 0;
imgmaskHi2 = not(imgmaskHi2);

imgmaskHi = and(imgmaskHi1, imgmaskHi2);

imgmask = and(imgmaskLo, imgmaskHi);
imgmask = imopen(imgmask, strel('disk', 2));
imgmask = postProcessSegments(bwlabeln(imgmask), 'volume.min', 15, 'fillholes', false) > 0;

if verbose
   %max(img(:))   
   figure(21); clf;
   set(gcf, 'Name', 'Masking')
   implottiling({imgsSt{5},imgmaskLo; 
                 imgsStRaw{4},imgmaskHi1;
                 imgsStRaw{1},imgmaskHi2;
                 mat2gray(imgm),  imgmask
                 }', 'titles', {'I', 'Lo', 'I','Hi','I', 'Mask'})
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Cell Centers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%imgBM = filterBM(mat2gray(imgC), 'profile', 'np', 'sigma', 9);
%imgCf = imgBM;
%imgI  = sum(imgBM,3);
imgI = imgC(:,:,3);

if verbose > 1
   figure(3); clf;
   set(gcf, 'Name', 'BM')
   implottiling({imgC; imgBM; imgBM(:,:,3); mat2gray(sum(imgBM,3)); mat2gray(imgI)}')
end


%% DoG filter + Cell Detection

%imgBMI = sum(imgBM, 3);
%imgI = imgBM(:,:,3);
%imgI = imgCf(:,:,3) + imgCf(:,:,1) + imgCf(:,:,2);

disk = strel('disk',3);
disk = disk.getnhood;
%imgV = 1 ./ filterStd(imgI, disk) .* imgI ;
imgV = imgI - 3 * filterStd(imgI, disk);
%imgV(imgV > 100) = 100;

if verbose
   figure(31); clf 
   set(gcf, 'Name', 'Variance')
   implottiling({imgC, mat2gray(imgV), mat2gray(filterDoG(imgV, 5)),  mat2gray(imgI)});
end

%%
imgf = imgV;
%imgf = filterDoG(imgV, 8); % .* imgI;
%imgf = filterSphere(imgV, 4);
%imgf = filterDisk(imgI,12,1);
%imgF = imgBMI;


imgf2 = imgf; % - imopen(imgf, strel('disk', 1));

imgmax = imextendedmax(mat2gray(imgf2), 0.025);
%imgmax  = immask(imgmax, imgmask);
%imglab = bwlabeln(imgmax);

if verbose 
   figure(32); clf   
   set(gcf, 'Name', 'Maxima')
   %implottiling({imgC, imgsSt{5}; imgI,  imgf;
   %              imoverlay(mat2gray(imgf2), imgmax), imoverlay(imgC, imgmax); 10 * imgI, 100 * imgsSt{5}}')
   implottiling({imoverlay(mat2gray(imgf2), imgmax), imoverlay(imgC, imgmax)})
end


%figure(67); clf;
%implottiling(bwlabeln(imgmax))


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Cell Shape
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Watershed

%imgWs = imimposemin(iminvert(imgf), imgmax);
imgWs = imimposemin(iminvert(imgsSt{5}), imgmax);
imgWs = watershed(imgWs);
imgWs = immask(imgWs, imgmask);
imgWs = imlabelseparate(imgWs);
imgWs = postProcessSegments(bwlabeln(imgWs), 'volume.min', 15);

if verbose
   %figure(7); clf;
   %implot(imgWs)

   %imglab = bwlabel(imgWs);

   figure(8); clf;
   set(gcf, 'Name', 'Cells from Watershed')
   imgsurf = impixelsurface(imgWs);
   implottiling({imoverlaylabel(imgsSt{5}, imgsurf, false);imoverlaylabel(imgC, imgsurf, false)})
   
end
   
imgS = imgWs;      


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Postprocess
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc
max(imgS(:))

imgSP = imgS;

mode = 'MedianIntensity';

stats = imstatistics(imgSP, {mode}, imgI);

if verbose
   figure(7); clf; 
   hist([stats.(mode)], 256)
   set(gcf, 'Name', mode)
   %hist(imgI(:), 256)
end

%% Remove weak cells

imgSP = postProcessSegments(imgS, imgI, 'intensity.median.min', 0.25, 'volume.min', 15, 'fillholes', false);

if verbose > 1
   imgSp1 = impixelsurface(imgSP);
   imgSp1 = imoverlaylabel(imgC, imgSp1, false);
   figure(5); clf;
   implot(imgSp1);
end

fprintf('watershed    : %d cells\n', max(imgS(:)))
fprintf('postprocessed: %d cells\n', max(imgSP(:)))

%% Remove weak DAPI Cells


statsDAPI = imstatistics(imgSP, {mode},  imgsSt{5});

if verbose 
   figure(6); clf;
   hist([statsDAPI.(mode)], 256)
   title('DAPI intensity')
end

%%
imgSP2 = postProcessSegments(imgSP, imgsSt{5}, 'intensity.median.min', 0.08);

if verbose > 1
   imgSp2 = impixelsurface(imgSP2);
   imgSp2 = imoverlaylabel(imgC, imgSp2, false);
   figure(5); clf;
   implot(imgSp2);
end

fprintf('postprocessed : %d cells\n', max(imgSP(:)))
fprintf('dapi corrected: %d cells\n', max(imgSP2(:)))

%statsDAPI = imstatistics(imgSP2, {mode},  imgsSt{5});
%figure(6); clf;
%hist([statsDAPI.(mode)], 256)
%title('DAPI intensity')


%% Plot Results

imglab = imgSP2;
fprintf('final: %d cells\n', max(imglab(:)))

%%
if verbose 
   
   
   statsF = imstatistics(imglab, {'PixelIdxList', 'Centroid'});
   % mode = 'MedianIntensity';

   figure(7); clf; 
   for c = 1:nch
      statsCh{c} = imstatistics(imglab, statsF, mode, imgsSt{c});
      
      imsubplot(1, nch, c)
      imgch = zeros(size(imglab));
      for i = 1:length(statsF)
         imgch(statsF(i).PixelIdxList) = statsCh{c}(i).(mode);
      end
      implot(imgch);
      %imcolormap(cm(c));
      title(chlabel{c});
      drawnow
   end
end

%% Save Image Preporcessing Result

savefile = [datadir, dataname, datafield, '_ImageProcessing.mat'];
save(savefile)
%load(savefile)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Statistics 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

stats = imstatistics(imglab, {'PixelIdxList', 'Centroid'});

mode = 'MedianIntensity';

clear statsCh
for c = 1:nch
   statsCh{c} = imstatistics(imglab, stats, mode,  imgsStRaw{c});
end
  

%% Cell Center Image 

%imglabc = imlabelapplybw(imglab, @bwulterode);
cc = fix([stats.Centroid]);
imglabc = zeros(size(imglab));
ind = imsub2ind(size(imglab), cc');
imglabc(ind) = 1:length(ind);
imglabc = imdilate(imglabc, strel('disk', 2));

if verbose > 1
    figure(78); clf;
    implottiling({imglabc})
end


%% Plot Detected Cells

if verbose > 1 
   h = figure(7); clf;
   %subreg = {[600:900], [550:950], ':'};
   %subreg = {[200:300], [150:250], ':'};
   subreg = {':', ':', ':'};
   imgCfsub = imgCf(subreg{:});
   imgCsub = imgC(subreg{:});
   imglabsub = imglabc(subreg{:});

   implot(imoverlaylabel(imgCsub, imglabsub > 0, false, 'color.map', [[0,0,0]; 0.5*[1,0,0]]));
   axis off
   xlabel([]); ylabel([])

   %saveas(h, [datadir, dataname, datafield, '_Segmentation_Seeds.pdf'])
end

%% Raw Image Data Color Plot

if verbose
   h = figure(11); clf;

   %implot(filterAutoContrast(imgCf));
   implot(imgC);
   axis off
   xlabel([]); ylabel([])

   saveas(h, [datadir, dataname, datafield, '_Raw.pdf'])
end


%% 

if verbose
   h = figure(7); clf;
   implottiling({imgC, imoverlaylabel(imgC, imglabc> 0,false, 'color.map', [[0,0,0]; [1,0,0]])}');
   
   saveas(h, [datadir, dataname, datafield, '_CellDetection.pdf'])
end


%% Flourescence in Space

xy = [stats.Centroid]';
cl = 100 * [0.1, 0.6, 0.5, 0.5, 0.6];
%ct = [0.110, 0.0, 0.100]

figure(21); clf;
for c = 1:nch
   fi = [statsCh{c}.(mode)]';
   fi = imclip(fi, 0, cl(c));
   
   figure(21);
   subplot(2,nch,c+nch);
   hist(fi, 256)
   h = findobj(gca,'Type','patch');
   h.FaceColor = 'k';
   %h.EdgeColor = 'w';
   
   subplot(2,nch,c);
   %imcolormap(cm{c});
   colormap jet
   scatter(xy(:,1), xy(:,2), 10, fi, 'filled');
   %xlim([0, size(imglab,1)]); ylim([0, size(imglab,2)]);
   title(chlabel{c});
   %freezecolormap(gca)
   
   %h = figure(22); clf
   %colormap jet
   %scatter(xy(:,1), xy(:,2), 10, fi, 'filled');
   %xlim([0, size(imglab,1)]); ylim([0, size(imglab,2)]);
   %title(chlabel{c}); 
   %colorbar('Ticks', [])
   
   %saveas(h, [datadir dataname datafield '_Quantification_' lab{c} '.pdf']);
end


%% Normalized Intensities - Flourescence in Space

clear statsChN
for c = 1:nch
   statsChN{c} = statsCh{c};
   if c < 5
      for i = 1:length(statsCh{c})
         statsChN{c}(i).(mode) = statsCh{c}(i).(mode) / statsCh{5}(i).(mode);
      end
   end
end


xy = [stats.Centroid]';

ha = figure(21); clf;
set(gcf, 'Name', 'Normalized Expression')

fig = gcf;
fig.PaperUnits = 'inches';
fig.PaperPosition = [0 0 30 20];
fig.PaperPositionMode = 'manual';
set(gcf, 'papersize', [30,20]);


for c = 1:nch
   fi = [statsChN{c}.(mode)]';
   
   fis = sort(fi);
   ncs = length(fis);
   p90 = int64(0.9 * ncs);
   fi = imclip(fi, 0, fis(p90));
   
   figure(21);
   subplot(3,nch,c+2*nch);
   [nb,xb] = hist(fi, 256);
   bh = bar(xb,nb);
   set(bh,'facecolor','k');
   
   
   subplot(3,nch,c+nch);
   %imcolormap(cm{c});
   colormap jet
   scatter(xy(:,1), xy(:,2), 10, fi, 'filled');
   xlim([min(xy(:,1)), max(xy(:,1))]); ylim([min(xy(:,2)), max(xy(:,2))]);
   title(chlabel{c});
   %freezecolormap(gca)
   
   subplot(3,nch,c)
   implot(imgsStRaw{c})
      
   %h = figure(22); clf
   %colormap jet
   %scatter(xy(:,1), xy(:,2), 10, fi, 'filled');
   %xlim([0, size(imglab,1)]); ylim([0, size(imglab,2)]);
   %title(chlabel{c}); 
   %colorbar('Ticks', [])
   %saveas(h, [datadir dataname datafield '_Quantification_' lab{c} '.pdf']);
end

saveas(ha, [datadir dataname datafield '_Quantification_Normalized.pdf']);

%% Flourescence Expression

fi = cell(1,3);
for c = 1:nch
   fi{c} = [statsChN{c}.(mode)]';
   
   fis = sort(fi{c});
   ncs = length(fis);
   p95 = int64(0.99 * ncs);
   fi{c} = imclip(fi{c}, 0, fis(p95));
   %fi{c} = mat2gray(fi{c});
end
 
pairs = {[1,2], [1,3], [1,4], [2, 3], [2,4], [3,4]};

np = length(pairs);

figure(22); clf;
for n = 1:np
   subplot(2, np/2,n)
   %fi = imclip(fi, 0, cl(c));
   %scatter(fi{pairs{n}(1)}, fi{pairs{n}(2)}, 10, 'b', 'filled');
   scattercloud(fi{pairs{n}(1)}, fi{pairs{n}(2)}, 50);
   %xlim([0,1]); ylim([0,1]);
   xlabel(chlabel{pairs{n}(1)}); ylabel(chlabel{pairs{n}(2)});
   %freezecolormap(gca)
end
set(gcf, 'Name', 'Normalized Expression')

if verbose > 1
   for n = 1:np
      h = figure(50+n); clf;
      %fi = imclip(fi, 0, cl(c));
      %scatter(fi{pairs{n}(1)}, fi{pairs{n}(2)}, 10, 'b', 'filled');
      scattercloud(fi{pairs{n}(1)}, fi{pairs{n}(2)});
      xlim([0,1]); ylim([0,1]);
      xlabel(chlabel{pairs{n}(1)}); ylabel(chlabel{pairs{n}(2)});

      %saveas(h, [datadir dataname datafield '_Quantification_Scatter_' chlabel{pairs{n}(1)} ,'_' chlabel{pairs{n}(2)} '.pdf']);
      %freezecolormap(gca)
   end
end




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Classify Cells
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Mask for non valid regoins

%xp = [0.5, 44.8458, 67.84, 90.8341, 177.8834, 241.9385, 332.2726, 471.8798, 616.4144, 790.5129, 910.4109, 984.3206, 1028.6665, 1081.2245, 1166.6313, 1212.6196, 1243.8259, 1230.6864, 1252.0381, 1281.602, 1298.0264, 1312.8083, 1319.3781, 1311.1659, 1334.16, 1362.0815, 1403.1424, 1401.5, 1334.16, 1279.9596, 1253.6805, 1207.6923, 1156.7767, 1073.0123, 943.2597, 885.7743, 825.0041, 747.8095, 718.2456, 670.6149, 621.3417, 578.6383, 526.0803, 499.8013, 374.976, -1.1424, 0.5];
%yp = [613.9508, 528.544, 502.2649, 426.7128, 361.0152, 305.1723, 239.4748, 193.4865, 173.7773, 185.2743, 203.3411, 219.7655, 247.687, 278.8933, 323.2392, 375.7972, 398.7913, 413.5733, 439.8523, 482.5557, 526.9015, 559.7503, 592.5991, 622.163, 646.7995, 663.2239, 697.7151, 76.8734, 91.6553, 103.1524, 96.5826, 101.51, 99.8675, 101.51, 96.5826, 88.3705, 67.0188, 47.3095, 52.2368, 47.3095, 17.7456, 21.0305, 16.1032, 4.6061, -5.2485, -3.6061, 613.9508];
%imgbad = ~poly2mask(xp',yp', size(imgI,1), size(imgI,2))';
imgbad = ~logical(zeros(size(imgI)));

if verbose > 1
   figure(6); clf;
   set(gcf, 'Name', 'Bad Image Region');
   implot(imgbad)
end

%% histograms

figure(10); clf
set(gcf, 'Name', 'Histograms');
for c= 1:nch
   subplot(3,nch,c); 
   d = imgsSt{c};
   %hist(d(:), 256);
   implot(imgsSt{c})
   title(['Raw ', chlabel{c}])
   
   subplot(3, nch, c+nch);
   hist([statsCh{c}.(mode)], 256)
   title(chlabel{c})
   
   subplot(3, nch, c+2*nch); 
   hist([statsChN{c}.(mode)], 256)
   title(['Normalized ' chlabel{c}])
   
end

%% Classify

cth = {0.4, 0.5, 0.35, 3, 0};

clear neuroClass
for c = 1:nch
   xy = fix([statsCh{c}.Centroid]);
   xy(1,xy(1,:) > size(imgI,1)) = size(imgI,1); xy(1,xy(1,:) < 1) = 1;
   xy(2,xy(2,:) > size(imgI,2)) = size(imgI,2); xy(2,xy(2,:) < 1) = 1;
   
   isgood = zeros(1, size(xy,2));
   for i = 1:size(xy, 2)
      isgood(i) = imgbad(xy(1,i), xy(2,i));
   end

   neuroClass(c,:) = double(and([statsChN{c}.(mode)] > cth{c}, isgood));
end
neuroClassTotal = int32(fix(neuroClass(1,:) + 2 * neuroClass(2,:) + 4 * neuroClass(3,:) + 8 * neuroClass(4,:)));

neuroBaseColor = {[1,0,0], [0,1,0], [1,1,0], [1,0,1],[0,0,1]};


imgClass1 = cell(1,nch);
for c = 1:nch
   neuroColor1 = {[0,0,0], neuroBaseColor{c}};
   neuroColor1 = neuroColor1(neuroClass(c,:)+1);
   

   R = imgsSt{c}; G = R; B = R;
   for i = 1:length(stats);
      if neuroClass(c,i) > 0
         R(stats(i).PixelIdxList) =  neuroColor1{i}(1);
         G(stats(i).PixelIdxList) =  neuroColor1{i}(2);
         B(stats(i).PixelIdxList) =  neuroColor1{i}(3);
      end
   end
   imgClass1{c} = cat(3, R, G, B);
end


h = figure(7); clf;
implottiling({imgsSt{1:nch}; imgClass1{:}}, 'titles', [chlabel(1:nch)', chlabel(1:nch)']');
set(gcf, 'Name', 'Classifications');

fig = gcf;
fig.PaperUnits = 'inches';
fig.PaperPosition = [0 0 8 30];
fig.PaperPositionMode = 'manual';
set(gcf, 'papersize', [8,30]);

saveas(h, [datadir dataname datafield '_Classification' '.pdf']);


%%
%neuroClassColor = {[0,0,0]; [0.6,0,0]; [0,0.6,0]; [0.33,0.33,0]; [0,0.33,0]; [0.33,0,0.33]; [0,0.33,0.33]; [0.5,0.5,0.5]};
% neuroClassColor = num2cell([0.285714, 0.285714, 0.285714;
%    0.929412, 0.290196, 0.596078;
%    0.462745, 0.392157, 0.67451;
%    0.709804, 0.827451, 0.2;
%    0.984314, 0.690196, 0.25098;
%    0.976471, 0.929412, 0.196078;
%    0.584314, 0.752941, 0.705882;
%    0, 0.682353, 0.803922
%    ], 2);

%neuroClassColor = num2cell(colorcube(max(neuroClassTotal(:))), 2);

ncls = 2^(nch-1);
neuroClassColor = cell(1, ncls);
for i = 1:ncls
   cb = dec2bin(i-1);
   cb = cb(end:-1:1);
   %cb = [cb(end:-1,1), '0000'];
   %cb = cb(1:nch);
   
   col = [0,0,0]; k = 0;
   for l = 1:length(cb)
      if cb(l) == '1'
         col = col + neuroBaseColor{l};
         k = k + 1;
      end
   end
   if k > 1
      col = col / k;
   end
   
   neuroClassColor{i} = col;
end
   

for p = 1:length(stats);
   nc = neuroClassColor{neuroClassTotal(p)+1};
   
   R(stats(p).PixelIdxList) =  nc(1);
   G(stats(p).PixelIdxList) =  nc(2);
   B(stats(p).PixelIdxList) =  nc(3);
end

imgClass = cat(3, R, G, B);

% 
% figure(7); clf;
% implottiling({imgsSt{1:nch}, imgCf, imgClass}', 'tiling', [3,2]);


h = figure(7); clf;
implottiling({imgsStRaw{1:nch}, imgC; imgClass1{:}, imgClass}, 'titles', [[chlabel(1:nch)'; {'merge'}], [chlabel(1:nch)'; {'merge'}]]');

%saveas(h, [datadir dataname datafield '_Classification_Channels' '.pdf']);
%saveas(h, [datadir dataname datafield '_Classification_Image' '.pdf']);


%% Class in Space
isgood = logical(isgood);

xy = [stats.Centroid]';
xy = xy(isgood, :)

h = figure(27)

cdat = (cell2mat({[0,0,0], neuroClassColor{:}}'))
   
scatter(xy(:,1), xy(:,2), 5, cdat(neuroClassTotal(isgood) + 2, :), 'filled');
xlim([0, size(imglab,1)]); ylim([0, size(imglab,2)]);
%title(chlabel{c});
%freezecolormap(gca)

pbaspect([1,1,1])

saveas(h, [datadir dataname datafield '_Quantification_Space.pdf']);



%% Histogram of Cell Classes
 
ncls = length(neuroClassColor);

nstat = zeros(1,ncls);

for i = 1:ncls
   id = num2cell(dec2bin(i-1));
   id = id(end:-1:1);
   for k = length(id)+1:nch
      id{k} = '0';
   end

   clslab{i} = '';
   for c = 1:nch
      if id{c} == '1'
         clslab{i} = [clslab{i}, '_', chlabel{c}];
      end
   end
   clslab{i} = clslab{i}(2:end);
   if isempty(clslab{i})
      clslab{i} = 'None';
   end
   
   nstat(i) = sum(neuroClassTotal + 1== i);
end

nc = num2cell(nstat);
tb = table(nc{:}, 'VariableNames', clslab)


%% save numbers
writetable(tb, [datadir dataname datafield '_Counts.txt'])


%% hist

h = figure(10); clf; hold on

k = 1;
%ord = [1, 5, 3, 6, 7, 8, 4, 2];
ord = 1:ncls
for i = ord
   bar(k, nstat(i), 'FaceColor', neuroClassColor{i});
   
   k = k + 1;
end

set(gca, 'XTickLabel', '')  
xlabetxt = strrep(clslab(ord), '_', '+');
n = length(clslab);
ypos = -max(ylim)/50;
text(1:n,repmat(ypos,n,1), xlabetxt','horizontalalignment','right','Rotation',35,'FontSize',15)

saveas(h, [datadir dataname datafield '_Classification_Statistics' '.pdf']);


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Zones and distances
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%
%figure(101); clf
%implot(imgsStRaw{5})
%
%figure(100); clf
%implot(imgC)
%p  = impoly

%%
outer = [1889.73607594937 2043.61329113924;1902.6917721519 1963.28797468355;1889.73607594937 1857.05126582279;1897.50949367089 1807.81962025317;1884.55379746836 1737.85886075949;1876.78037974684 1722.31202531646;1879.37151898734 1649.76012658228;1876.78037974684 1587.57278481013;1871.59810126582 1561.66139240506;1861.2335443038 1489.10949367089;1856.05126582279 1411.3753164557;1845.68670886076 1307.72974683544;1843.09556962025 1258.49810126582;1856.05126582279 1134.12341772152;1861.2335443038 1043.4335443038;1900.10063291139 929.423417721519;1920.82974683544 856.871518987342;1936.37658227848 763.590506329114;1944.15 696.220886075949;1938.96772151899 634.033544303798;1954.51455696203 574.437341772152;1954.51455696203 525.205696202532;1964.87911392405 434.51582278481;1959.69683544304 356.78164556962;1972.65253164557 268.682911392405;1995.97278481013 154.672784810126;2008.92848101266 66.5740506329112;2016.70189873418 -0.795569620253445];
cortexU = [1835.32215189874 2046.20443037975;1848.27784810127 1999.56392405063;1858.64240506329 1952.92341772152;1863.8246835443 1916.64746835443;1861.2335443038 1867.41582278481;1858.64240506329 1802.63734177215;1848.27784810127 1743.04113924051;1843.09556962025 1678.26265822785;1837.91329113924 1644.57784810127;1848.27784810127 1597.93734177215;1832.73101265823 1538.34113924051;1824.95759493671 1486.51835443038;1822.3664556962 1450.24240506329;1817.18417721519 1377.69050632911;1806.81962025317 1320.68544303798;1804.22848101266 1268.86265822785;1814.59303797468 1211.85759493671;1812.00189873418 1162.62594936709;1819.7753164557 1123.75886075949;1822.3664556962 1095.25632911392;1819.7753164557 1074.52721518987;1832.73101265823 1012.33987341772;1835.32215189874 986.428481012658;1845.68670886076 947.561392405064;1871.59810126582 867.236075949367;1894.91835443038 807.639873417722;1910.46518987342 719.541139240506;1913.05632911392 659.944936708861;1915.64746835443 608.122151898734;1923.42088607595 558.890506329114;1918.23860759494 517.432278481013;1926.01202531646 452.653797468354;1931.19430379747 398.239873417722;1926.01202531646 359.372784810127;1928.60316455696 302.367721518987;1936.37658227848 260.909493670886;1946.74113924051 214.268987341772;1946.74113924051 180.58417721519;1954.51455696203 144.308227848101;1957.10569620253 118.396835443038;1964.87911392405 84.7120253164558;1970.06139240506 32.8892405063289;1977.83481012658 1.79556962025299];
cortexL = [1607.30189873418 2051.38670886076;1594.34620253165 1958.10569620253;1594.34620253165 1885.55379746836;1586.57278481013 1787.09050632911;1576.2082278481 1709.35632911392;1563.25253164557 1662.71582278481;1576.2082278481 1644.57784810127;1573.6170886076 1546.11455696203;1552.88797468354 1478.74493670886;1552.88797468354 1442.46898734177;1560.66139240506 1413.9664556962;1542.52341772152 1377.69050632911;1545.11455696203 1310.32088607595;1550.29683544304 1235.17784810127;1532.15886075949 1134.12341772152;1534.75 1061.57151898734;1532.15886075949 983.837341772152;1539.93227848101 913.876582278481;1526.97658227848 856.871518987342;1547.70569620253 758.408227848101;1555.47911392405 641.806962025317;1563.25253164557 577.028481012658;1560.66139240506 481.156329113924;1552.88797468354 359.372784810127;1545.11455696203 266.091772151899;1545.11455696203 154.672784810126;1545.11455696203 71.756329113924;1545.11455696203 9.56898734177184;1545.11455696203 -0.795569620253445];
inner = [1029.47784810127 2043.61329113924;990.610759493671 1971.06139240506;946.561392405063 1898.50949367089;912.876582278481 1779.3170886076;884.374050632912 1665.30696202532;858.462658227848 1527.97658227848;819.595569620253 1401.01075949367;809.231012658228 1261.08924050633;757.408227848101 1123.75886075949;718.541139240506 981.246202531646;692.629746835443 864.644936708861;653.762658227848 716.95;656.353797468354 600.348734177215;648.580379746835 535.570253164557;633.033544303797 475.974050632911;604.531012658228 349.008227848101;570.846202531646 242.771518987342;537.161392405063 89.8943037974682;519.023417721519 -0.795569620253445];
vz = [1218.63101265823 2048.79556962025;1169.39936708861 1950.33227848101;1112.39430379747 1792.27278481013;1086.48291139241 1693.80949367089;1068.34493670886 1608.30189873418;1050.20696202532 1483.92721518987;1026.88670886076 1382.87278481013;1019.11329113924 1299.95632911392;959.517088607595 1131.53227848101;925.832278481013 1009.74873417722;876.600632911393 890.556329113924;879.191772151899 789.501898734178;855.871518987342 696.220886075949;827.368987341772 589.98417721519;809.231012658228 494.112025316456;796.275316455696 400.831012658228;780.728481012658 294.594303797468;749.634810126582 123.57911392405;734.087974683544 4.38670886075943];

lines = {inner, outer, vz cortexL, cortexU};

% hold on
% for l = 1:length(lines)
%    diff(lines{l})
%    plot(lines{l}(:,1), lines{l}(:,2), 'w', 'LineWidth',2)
% end

nlines = length(lines);
lineshires = cell(1, nlines);
for l = 1:nlines
   lineshires{l} = [interp1(lines{l}(:,2), lines{l}(:,1), 1:size(imgC, 2)); (1:size(imgC,2))];
end
   
if verbose
   h = figure(101); clf
   implot(imgC)
   hold on
   for l = 1:nlines
      plot(lineshires{l}(1,:), lineshires{l}(2,:), 'r', 'LineWidth',1)
   end
   hold off
   
   saveas(h, [datadir dataname datafield '_Annotation' '.pdf']);
end


%% Calculate Relative Cell 

xy = [stats.Centroid];

ncells = size(xy,2);

dinner = zeros(1,ncells);
douter = zeros(1,ncells);
for i = 1:ncells
   if mod(i, 500) == 0
      fprintf('%d / %d\n', i, ncells)
   end
   dinner(i) = minimalDistance(xy(:,i), lineshires{1});
   douter(i) = minimalDistance(xy(:,i), lineshires{end});
end


%% Plot Expressions as relative distances

drel = dinner ./ (dinner + douter);

% non normalized
if verbose
   h  = figure(200); clf;
   for c = 1:nch-1
      dat = [statsCh{c}.(mode)];
      subplot(1,nch-1,c)
      plot(drel, dat, ['.' cm{c}])
      title(chlabel{c})
      xlabel('rel. position')
      ylabel('intensity [AU]')
   end
   
   fig = gcf;
   fig.PaperUnits = 'inches';
   fig.PaperPosition = [0 0 20 8];
   fig.PaperPositionMode = 'manual';
   set(gcf, 'papersize', [20,8]);
   
   saveas(h, [datadir dataname datafield '_RelativePosition_vs_Expression' '.pdf']);
end

%%
if verbose
   h  = figure(200); clf;
   for c = 1:nch-1
      dat = [statsChN{c}.(mode)];
      subplot(1,nch-1,c)
      plot(drel, dat, ['.' cm{c}])
      title(chlabel{c})
      xlabel('rel. position')
      ylabel('intensity [AU]')
   end
   
   fig = gcf;
   fig.PaperUnits = 'inches';
   fig.PaperPosition = [0 0 20 8];
   fig.PaperPositionMode = 'manual';
   set(gcf, 'papersize', [20,8]);
   
   saveas(h, [datadir dataname datafield '_RelativePosition_vs_Expression_DAPINormalized' '.pdf']);
end




%% Save the Statistics to File

statsfile = [datadir dataname datafield '_statistics' '.mat'];
%save(statsfile, 'chlabel', 'stats', 'statsCh', 'statsChN',  'neuroClass', 'lineshires', 'dinner', 'douter');
%load(statsfile)

%% Save For Mathematica

centers = [stats.Centroid];

intensities = zeros(length(statsCh), size(centers,2));
intensities_normalized = zeros(length(statsCh), size(centers,2));
for c = 1:length(statsCh)
   intensities(c, :) = [statsCh{c}.MedianIntensity];
   intensities_normalized(c, :) = [statsChN{c}.MedianIntensity];
end


statsfilemathematica = [datadir dataname datafield '_statistics_mathematica' '.mat'];
save(statsfilemathematica, '-v6', 'chlabel', 'centers', 'dinner', 'douter', 'lineshires', 'intensities', 'intensities_normalized', 'neuroClass');