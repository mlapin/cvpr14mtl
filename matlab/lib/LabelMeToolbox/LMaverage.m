function Average = LMaverage(D, objectname, HOMEIMAGES, object_size, average_size)
%
% Average = LMaverage(D, objectname, HOMEIMAGES)


% Parameters:
if nargin<4
    object_size = [256 256]; % scale normalized
end
if nargin<5
    average_size = object_size*4; % scale normalized
end

b = ceil((average_size(1)- object_size(1))/2);


disp('selecting objects to average')
D = LMquery(D, 'object.name', objectname,'exact');

disp('removing small and cropped objects from the averaging')
D = addsmallobjectlabel(D, object_size(1)/2, object_size(2)/2);
D = LMquery(D, 'object.name', '-smallobject');
D = LMquery(D, 'object.crop', '0');


% Align all images (scale and translate) and compute averages
Average = zeros([average_size 3], 'single');


[nrows ncols cc] = size(Average);
Counts  = zeros([nrows ncols], 'single');

[x,y] = meshgrid(0:ncols-1, 0:nrows-1);
x = x - ncols/2;
y = y - nrows/2;

figure
for n = 1:length(D)
    clear img imgt Tmp xi yi
    img = LMimread(D, n, HOMEIMAGES);
    
    img = single(img);
    img = img - min(img(:));
    img = uint8(253*img / max(img(:))+2);
    
    if size(img,3)>1
        for k = 1:length(D(n).annotation.object);
            [imgCrop, scaling, seg, warn, valid] = LMobjectnormalizedcrop(img, D(n).annotation, k, b, object_size(1), object_size(2));
            
            imgCrop(isnan(imgCrop))=0;
            
            Counts = Counts + single(valid);
            Average = Average + single(imgCrop);
            
            
            Tmp = Average ./ repmat(Counts+.01, [1 1 3]);
            Tmp = Tmp - min(Tmp(:));
            Tmp = Tmp / max(Tmp(:))*255;
            
            imshow(uint8(Tmp))
            title(n)
            drawnow
        end
    end
end

Average = Average ./ repmat(Counts+.01, [1 1 3]);
Average = Average - min(Average(:));
Average = Average / max(Average(:))*255;

%average = average-prctile(average(:), 3);
%average = 255*average/prctile(average(:), 97);
