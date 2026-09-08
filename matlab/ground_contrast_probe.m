%GROUND_CONTRAST_PROBE  Measure the real ground's (shoulder/verge/forest-floor) local
%   contrast off Aditya's own dashcam frames, at MATCHED metres-per-pixel, so
%   sc.groundTexture's amplitude is SOLVED rather than guessed - the same
%   discipline REF-17 s22b used for the road ("the largest available win" turned
%   out to be a smaller one once measured), applied here because nobody has
%   measured the ground yet (REF-17 s19j: "Phase 5's GROUND half... has not been
%   measured and may now be the better half of it").
%
%   THREE PASSES, TIGHTER EACH TIME - same tell as the road: every refinement
%   LOWERS the number, because a brighter intruder (sky, a vehicle body, a
%   painted marking) only ever ADDS contrast it should not be carrying.
%     pass 1  naive fixed rectangle, lower-left of frame          - contaminated
%     pass 2  best-of-N candidate per frame by vegetation/earth score - still some
%     pass 3  + reject sky / flat-grey (road, vehicle paint) / shadow / blown
%             highlight / near-uniform patches, at MATCHED metres-per-pixel
%
%   CONTACT-SHEETED: every crop pass 3 ACCEPTS is written to one image and must
%   be LOOKED AT before the number is trusted (matlab-render-hazards memory s4 -
%   "the single sample I checked after pass 1 was visibly grass").
%
%   CAMERA ASSUMPTIONS, STATED SO THEY CAN BE CHALLENGED RATHER THAN HIDDEN:
%     - 140 deg horizontal FOV, rectilinear first-order (REF-01 s12: corrected
%       from an earlier wrong 24 mm-equivalent assumption)
%     - 1.35 m mount height - THIS IS NOT A MEASURED DASHCAM FIGURE. It is this
%       project's own driver-eye height (used elsewhere for the render camera),
%       reused here for lack of anything better. Flagged in the printed report,
%       not silently assumed.
%     - level camera (horizon at the vertical centre row) - a dashcam pitches
%       with the vehicle in reality; not modelled.
%   Every one of these is a FIRST-ORDER approximation, exactly as this project's
%   own "140 deg dashcam = 8 mm equivalent, rectilinear" already is elsewhere.
%   4 of 64 frames (the drive_01 clip) are PORTRAIT (478x850, no EXIF tag to
%   explain it) and are excluded rather than guessed-rotated.

DIR = fullfile(sc.refRoot(), "world", "video", "frames");
files = dir(fullfile(DIR, "*.jpg"));
assert(~isempty(files), "sc:groundProbeNoFrames", "no dashcam frames found in %s", DIR);

HFOV = deg2rad(140);      % REF-01 s12
CAMH = 1.35;              % UNVERIFIED for the dashcam itself - see header
TARGET_MPP = 0.060;       % match sc.roadTexture's opts.MPP, so the two textures
                          % are solved to the same physical grain scale
N_CAND = 24;

outDir = fullfile(sc.refRoot(), "matlab", "renders");
if ~isfolder(outDir), mkdir(outDir); end

pass1 = [];  pass2 = [];
accepted = {};  acceptedCoV = [];  acceptedFile = {};
nPortrait = 0;  nFrames = 0;

for i = 1:numel(files)
    f = fullfile(files(i).folder, files(i).name);
    I = imread(f);
    [H, W, nc] = size(I);
    if nc < 3 || H > W, nPortrait = nPortrait + (H > W); continue; end
    nFrames = nFrames + 1;
    Id = im2double(I);

    % ---------------------------------------------------------- pass 1, naive
    y0 = round(0.68*H); y1 = round(0.86*H);
    x0 = round(0.02*W); x1 = round(0.22*W);
    pass1(end+1) = localCoV(Id(y0:y1, x0:x1, :));                          %#ok<AGROW>

    % ---------------------------------------------------------- candidates
    best2Score = -inf; best2Patch = [];
    for k = 1:N_CAND
        side = mod(k, 2);
        yc = 0.58 + 0.30*rand01k(i, k);
        y0k = max(1, round((yc-0.045)*H));  y1k = min(H, round((yc+0.045)*H));
        if side == 0
            x0k = max(1, round((0.02 + 0.24*rand01k(i, k+50))*W));
        else
            x0k = max(1, round((0.72 + 0.24*rand01k(i, k+50))*W));
        end
        x1k = min(W, x0k + round(0.075*W));
        if y1k-y0k < 8 || x1k-x0k < 8, continue; end
        patch = Id(y0k:y1k, x0k:x1k, :);

        mR = mean(patch(:,:,1),'all'); mG = mean(patch(:,:,2),'all'); mB = mean(patch(:,:,3),'all');
        score = (mG + mR) - 2*mB;               % vegetation/earth, never sky
        if score > best2Score, best2Score = score; best2Patch = patch; end

        % ------------------------------------------------------ pass 3 reject
        mx = max([mR mG mB]); mn = min([mR mG mB]); sat = (mx-mn) / max(mx,1e-6);
        bright = (mR+mG+mB)/3;
        isSky     = mB > mR && mB > mG;
        isFlat    = sat < 0.06 && bright > 0.50;    % road / vehicle bodywork
        isShadow  = bright < 0.12;
        isBlown   = bright > 0.92;
        L = 0.2989*patch(:,:,1) + 0.5870*patch(:,:,2) + 0.1140*patch(:,:,3);
        isUniform = std(L,0,'all') < 0.010;         % vehicle paint, sky, flat road
        % REF-13 s7 measured plains vegetation at ~31 % saturation and called alpine's
        % 51 % too saturated for this project's own palette. A tile above even that
        % ceiling is paint or signage, not a leaf - two such tiles (a flat painted
        % green gate, a wood/tarp panel) slipped through the filters above.
        isOverSat = sat > 0.55;

        % HUE BAND. Pass 1/2's own trap in a new place: a green/earth SCORE does
        % not reject a saturated red/magenta/blue patch, it merely fails to
        % PREFER it - and best-of-N still had to pick something. Direct rejection
        % by hue is what pass 1's contact sheet showed was missing: shop
        % signage, tail-lights, clothing and painted walls are saturated colours
        % no natural ground surface carries. Earth runs ~20-45 deg, vegetation
        % ~60-150 deg; pure red/orange signage sits under 20, magenta/blue/cyan
        % (clothing, painted walls, shade bleed) sits over 170.
        hueDeg = rgbHueDeg(mR, mG, mB);
        isOffHue = sat > 0.20 && (hueDeg < 8 || hueDeg > 185);

        % EDGE-DOMINANCE. A lane-marking edge, a kerb line or a sign border
        % crossing the patch reads as HIGH CONTRAST from one sharp transition,
        % not from distributed texture - and localCoV cannot tell those apart.
        % If a small fraction of pixels carries most of the gradient energy,
        % the "texture" is a single line, not aggregate/leaf-litter/patchiness.
        gx = diff(L,1,2); gy = diff(L,1,1);
        ge = [gx(:).^2; gy(:).^2];
        ge = sort(ge, 'descend');
        topN = max(1, round(0.12*numel(ge)));
        isEdgeDominated = sum(ge(1:topN)) > 0.70*max(sum(ge), 1e-9);

        if isSky || isFlat || isShadow || isBlown || isUniform || isOffHue || isEdgeDominated || isOverSat
            continue
        end

        yc_px = (y0k+y1k)/2;
        mpp = groundMPP(yc_px, H, W, HFOV, CAMH);
        if isnan(mpp) || mpp <= 0, continue; end
        zoom = mpp / TARGET_MPP;
        if ~isfinite(zoom) || zoom <= 0, continue; end
        patchR = imresize(patch, zoom, 'bilinear');
        if numel(patchR) < 64, continue; end

        accepted{end+1}    = patchR;                                       %#ok<AGROW>
        acceptedCoV(end+1) = localCoV(patchR);                             %#ok<AGROW>
        acceptedFile{end+1}= files(i).name;                                %#ok<AGROW>
    end
    if ~isempty(best2Patch), pass2(end+1) = localCoV(best2Patch); end      %#ok<AGROW>
end

fprintf('[ground probe] %d landscape frames, %d portrait excluded\n', nFrames, nPortrait);
fprintf('[ground probe] pass1 naive:     median %.4f (n=%d)\n', median(pass1), numel(pass1));
fprintf('[ground probe] pass2 best-of-N: median %.4f (n=%d)\n', median(pass2), numel(pass2));
if isempty(acceptedCoV)
    fprintf('[ground probe] pass3 REJECTED EVERYTHING - the filters are too tight, look at pass2\n');
else
    p = prctile(acceptedCoV, [25 50 75]);
    fprintf(['[ground probe] pass3 contamination-rejected: median %.4f (p25 %.4f, p75 %.4f), ' ...
             'n=%d of %d candidates accepted\n'], p(2), p(1), p(3), numel(acceptedCoV), nFrames*N_CAND);
end

% ---------------------------------------------------------------- contact sheet
% EVERY ACCEPTED CROP, LOOKED AT - not a sample of them, all of them, because the
% road probe's own trap was a filter that looked right and had passed grass.
if ~isempty(accepted)
    TH = 96;
    thumbs = cell(size(accepted));
    for k = 1:numel(accepted)
        thumbs{k} = imresize(accepted{k}, [TH TH]);
    end
    nCols = 10; nRows = ceil(numel(thumbs)/nCols);
    sheet = ones(nRows*(TH+4)+4, nCols*(TH+4)+4, 3) * 0.85;
    for k = 1:numel(thumbs)
        r = floor((k-1)/nCols); c = mod(k-1, nCols);
        y0 = r*(TH+4)+4; x0 = c*(TH+4)+4;
        sheet(y0+1:y0+TH, x0+1:x0+TH, :) = thumbs{k};
    end
    sheetPath = fullfile(outDir, 'ground_probe_contact_sheet.png');
    imwrite(sheet, sheetPath);
    fprintf('[ground probe] contact sheet: %s (%d crops)\n', sheetPath, numel(thumbs));
end

% =======================================================================================
function cv = localCoV(patch)
%LOCALCOV  std/mean of luminance within one patch - the fraction the multiplier field
%   has to reproduce, self-normalising per patch so it costs no separate calibration
%   step against the render's own absolute brightness.
L = 0.2989*patch(:,:,1) + 0.5870*patch(:,:,2) + 0.1140*patch(:,:,3);
cv = std(double(L(:))) / max(mean(double(L(:))), 1e-6);
end

function mpp = groundMPP(yPix, H, W, hfovRad, camH)
%GROUNDMPP  Metres-per-pixel on the ground plane at image row yPix, rectilinear,
%   level camera, first order - see the file header for what this assumes.
vfov = 2*atan(tan(hfovRad/2) * H/W);
dy = (yPix - H/2) / (H/2);                    % -1 top .. +1 bottom
theta = atan(tan(vfov/2) * dy);               % below horizontal, rad
if theta <= deg2rad(1), mpp = NaN; return; end % at/above the horizon - depth blows up
depth = camH / tan(theta);
mpp = depth * tan(hfovRad/2) / (W/2);
end

function hueDeg = rgbHueDeg(r, g, b)
%RGBHUEDEG  Standard HSV hue in degrees, 0-360, for a single averaged RGB triple.
mx = max([r g b]); mn = min([r g b]); d = mx - mn;
if d < 1e-6, hueDeg = 0; return; end
if mx == r,      hueDeg = mod((g-b)/d, 6) * 60;
elseif mx == g,  hueDeg = ((b-r)/d + 2) * 60;
else,            hueDeg = ((r-g)/d + 4) * 60;
end
end

function h = rand01k(i, k)
%RAND01K  Deterministic per-(frame,candidate) hash in [0,1) - no dependence on the
%   global rand stream, so this probe cannot disturb anything else that draws from it.
h = mod(sin(i*12.9898 + k*78.233) * 43758.5453, 1);
end
