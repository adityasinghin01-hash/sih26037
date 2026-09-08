%TOOLS_CROP  Crop and magnify a region of a render so it can be judged by eye.
%   crop(file, x0, y0, w, h, scale) -> writes /tmp/crop_<name>.png
function tools_crop(f, x0, y0, w, h, k)
if nargin<6, k=3; end
I = imread(f);
I = I(y0:min(end,y0+h-1), x0:min(end,x0+w-1), :);
I = imresize(I, k, 'lanczos3');
[~,n] = fileparts(f);
o = fullfile('/tmp', sprintf('crop_%s.png', n));
imwrite(I, o);
fprintf('%s  %dx%d\n', o, size(I,2), size(I,1));
end
