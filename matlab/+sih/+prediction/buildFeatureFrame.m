function frame = buildFeatureFrame(boxes, prevBoxes, ego, imgW, imgH)
%BUILDFEATUREFRAME  The MATLAB twin of python/meteor/features.py.
%
%   Produces a FeatureFrame (AGENTS.md S2) from image-plane bounding boxes. Every quantity
%   here is computable BOTH from a METEOR annotation and from a simulated lidar track
%   projected down through a virtual camera. Nothing needs depth.
%
%   THIS FILE AND python/meteor/features.py MUST AGREE TO THE LAST BIT.
%   The model is trained in Python and runs here. If the two builders disagree, the network
%   is fed different numbers at inference than it saw in training, nothing errors, and the
%   symptom looks like a planner fault. python/tests/test_parity.py writes a fixture and
%   matlab/tests/testFeatureParity.m checks this function against it. Keep it passing.
%
%   INPUTS
%     boxes      struct array  one image-plane detection per element, fields:
%                  UMin, VMin, UMax, VMax  double  pixels
%                  ClassID  uint8   AGENTS.md S5
%                  TrackID  uint32  stable across frames
%                  T        double  seconds
%     prevBoxes  struct array  the same tracks one frame earlier; may be empty
%     ego        struct  .Speed m/s  .YawRate rad/s  .Accel m/s^2  .CandAction (S6)
%     imgW,imgH  double  image size in pixels
%
%   OUTPUT
%     frame  struct  FeatureFrame (S2):
%              .Data       [N x 31 single]
%              .Adjacency  [N x N single]
%              .TrackIDs   [N x 1 uint32]
%              .Timestamp  double
%
%   See also sih.prediction.predictYield

arguments
    boxes      struct
    prevBoxes  struct
    ego        (1,1) struct
    imgW       (1,1) double {mustBePositive}
    imgH       (1,1) double {mustBePositive}
end

FEATURE_DIM = 31;
N_CLASSES   = 16;
TAU_CLAMP   = 100.0;      % seconds; tau is unbounded as dh/dt -> 0
ADJ_RADIUS  = 0.25;       % normalised image distance counted as "interacting"

n = numel(boxes);
data = zeros(n, FEATURE_DIM, 'single');
ids  = zeros(n, 1, 'uint32');

if n == 0
    % S1 rule 3: a consumer must not error on an empty list.
    frame = struct('Data', data, 'Adjacency', zeros(0, 0, 'single'), ...
                   'TrackIDs', ids, 'Timestamp', 0);
    return
end

for i = 1:n
    b = boxes(i);
    ids(i) = b.TrackID;

    w        = (b.UMax - b.UMin) / imgW;
    h        = (b.VMax - b.VMin) / imgH;
    u_c      = ((b.UMin + b.UMax) / 2) / imgW;
    v_c      = ((b.VMin + b.VMax) / 2) / imgH;
    v_bottom = b.VMax / imgH;

    % rates, from the previous frame of the SAME track. Absent track -> zero, exactly as
    % the Python builder does; do not substitute a guess.
    p = iFindTrack(prevBoxes, b.TrackID);
    if ~isempty(p) && (b.T - p.T) > 1e-6
        dt = b.T - p.T;
        ph = (p.VMax - p.VMin) / imgH;
        pu = ((p.UMin + p.UMax) / 2) / imgW;
        pv = ((p.VMin + p.VMax) / 2) / imgH;
        du = (u_c - pu) / dt;
        dv = (v_c - pv) / dt;
        dh = (h - ph) / dt;
    else
        du = 0.0; dv = 0.0; dh = 0.0;
    end

    % feature 10: looming. tau = h / (dh/dt) -> time to contact from 2-D expansion alone
    tau = min(max(iSafeDiv(h, dh, TAU_CLAMP), -TAU_CLAMP), TAU_CLAMP);

    % feature 11: lateral time-to-cross. Seconds until this agent's centre reaches our own
    % path line (the image centre) from its current sideways drift. The lateral twin of
    % feature 10, and like it computable without any distance.
    latGap = u_c - 0.5;
    if latGap >= 0
        latRate = -du;                  % rate at which the gap shrinks
    else
        latRate = du;
    end
    lat = min(max(iSafeDiv(abs(latGap), latRate, TAU_CLAMP), -TAU_CLAMP), TAU_CLAMP);

    data(i, 1)  = u_c;
    data(i, 2)  = v_c;
    data(i, 3)  = v_bottom;
    data(i, 4)  = w;
    data(i, 5)  = h;
    data(i, 6)  = log(max(w, 1e-6) / max(h, 1e-6));
    data(i, 7)  = du;
    data(i, 8)  = dv;
    data(i, 9)  = dh;
    data(i, 10) = tau;
    data(i, 11) = lat;

    % 12-27: 16-way class one-hot. An out-of-range ClassID becomes 0 (unknown) rather than
    % an error, matching the Python builder. Positions are frozen - see S2.
    cid = double(b.ClassID);
    if cid < 0 || cid >= N_CLASSES
        cid = 0;
    end
    data(i, 12 + cid) = 1.0;

    data(i, 28) = ego.Speed;
    data(i, 29) = ego.YawRate;
    data(i, 30) = ego.Accel;
    data(i, 31) = ego.CandAction;
end

% Adjacency: 1 where two agents are close enough in the image to be interacting.
% The LSTM ignores this. It is emitted anyway so the GNN swap stays a small change - S2
% says never remove it.
adj = zeros(n, n, 'single');
for i = 1:n
    for j = i+1:n
        d = hypot(data(i,1) - data(j,1), data(i,2) - data(j,2));
        if d < ADJ_RADIUS
            adj(i,j) = 1.0;
            adj(j,i) = 1.0;
        end
    end
end

frame = struct('Data', data, 'Adjacency', adj, 'TrackIDs', ids, 'Timestamp', boxes(1).T);
end


function out = iSafeDiv(a, b, defaultVal)
%ISAFEDIV  a/b, or defaultVal when b is too small to divide by.
%   The 1e-9 threshold matches _safe_div in python/meteor/features.py exactly. Changing it
%   here alone silently desynchronises the two builders.
if abs(b) > 1e-9
    out = a / b;
else
    out = defaultVal;
end
end


function p = iFindTrack(prevBoxes, trackID)
%IFINDTRACK  The previous-frame box with this TrackID, or [] when the track is new.
p = [];
for k = 1:numel(prevBoxes)
    if prevBoxes(k).TrackID == trackID
        p = prevBoxes(k);
        return
    end
end
end
