function [imds, blds] = readDetectionData(imgDir, annDir, classNames)
%READDETECTIONDATA  Read IDD-Detection Pascal-VOC XML into datastores YOLOX can train on.
%
%   [imds, blds] = sih.models.readDetectionData(imgDir, annDir, classNames)
%
%   IDD Detection ships Pascal VOC XML: one .xml per image holding <object><name> and
%   <bndbox><xmin/ymin/xmax/ymax>. MATLAB has no built-in VOC reader, so this is it.
%
%   CLASS NAME MAPPING IS THE PART THAT GOES WRONG. IDD's own vocabulary is not ours:
%   it says "autorickshaw", we say "auto-rickshaw" (S5 ClassID 4). An unmapped name is
%   DROPPED, not guessed, and the count of dropped names is printed - a silent drop is how a
%   detector ends up never having seen a cow.
%
%   INPUTS
%     imgDir      string  folder of .jpg/.png images
%     annDir      string  folder of matching .xml annotations
%     classNames  string  the S5 class list from sih.util.classNames("detector")
%
%   OUTPUTS
%     imds  imageDatastore     images that have at least one usable box
%     blds  boxLabelDatastore  boxes as [x y w h] with categorical labels

arguments
    imgDir     (1,1) string
    annDir     (1,1) string
    classNames (1,:) string
end

% IDD's spelling -> ours. Extend this table rather than renaming anything in S5.
alias = dictionary( ...
    ["autorickshaw", "auto rickshaw", "rickshaw", "motorcycle", "bike", "person", ...
     "rider", "animal", "cattle", "traffic sign", "trafficsign", "vehicle fallback", ...
     "caravan", "trailer", "cart"], ...
    ["auto-rickshaw", "auto-rickshaw", "auto-rickshaw", "motorbike", "motorbike", ...
     "pedestrian", "motorbike", "cow", "cow", "static obstacle", "static obstacle", ...
     "static obstacle", "van", "truck", "pushcart"]);

xmls = dir(fullfile(annDir, '*.xml'));
files = strings(0, 1);
boxes = {};
labels = {};
dropped = dictionary(string.empty, double.empty);

for i = 1:numel(xmls)
    xmlPath = fullfile(xmls(i).folder, xmls(i).name);
    try
        doc = readstruct(xmlPath);
    catch
        continue                                     % unreadable file, not a fatal error
    end

    img = iFindImage(imgDir, erase(xmls(i).name, '.xml'));
    if img == ""
        continue
    end

    if ~isfield(doc, 'object')
        continue                                     % an image with no objects teaches nothing
    end
    objs = doc.object;
    if ~isstruct(objs); continue; end

    b = zeros(0, 4);
    l = strings(0, 1);
    for k = 1:numel(objs)
        raw = lower(strtrim(string(objs(k).name)));
        nm = raw;
        if isKey(alias, raw)
            nm = alias(raw);
        end
        if ~ismember(nm, classNames)
            if isKey(dropped, raw); dropped(raw) = dropped(raw) + 1;
            else; dropped(raw) = 1; end
            continue
        end
        bb = objs(k).bndbox;
        x1 = double(bb.xmin); y1 = double(bb.ymin);
        x2 = double(bb.xmax); y2 = double(bb.ymax);
        if x2 <= x1 || y2 <= y1
            continue                                 % zero-area box
        end
        b(end+1, :) = [x1, y1, x2 - x1, y2 - y1];    %#ok<AGROW>
        l(end+1, 1) = nm;                            %#ok<AGROW>
    end

    if isempty(b)
        continue
    end
    files(end+1, 1) = img;                           %#ok<AGROW>
    boxes{end+1, 1} = b;                             %#ok<AGROW>
    labels{end+1, 1} = categorical(l, classNames);   %#ok<AGROW>
end

if isempty(files)
    error('sih:models:noBoxes', ...
        ['No usable boxes found in %s.\nEither the folder is empty or every class name was ' ...
         'dropped - check the alias table at the top of this file.'], annDir);
end

imds = imageDatastore(files);
blds = boxLabelDatastore(table(boxes, labels, 'VariableNames', {'boxes', 'labels'}));

fprintf('Read %d images with at least one box.\n', numel(files));
if ~isempty(keys(dropped))
    k = keys(dropped);
    fprintf('Dropped %d unmapped class name(s) - add them to the alias table if they matter:\n', numel(k));
    for i = 1:numel(k)
        fprintf('  %-24s %d box(es)\n', k(i), dropped(k(i)));
    end
end
end


function p = iFindImage(imgDir, stem)
for ext = [".jpg", ".jpeg", ".png"]
    c = fullfile(imgDir, stem + ext);
    if isfile(c)
        p = string(c);
        return
    end
end
p = "";
end
