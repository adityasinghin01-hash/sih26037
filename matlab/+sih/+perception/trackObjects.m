function tracks = trackObjects(dets, tracker, t)
%TRACKOBJECTS  One frame of sensor detections -> the frozen S1 TrackList
%   (AGENTS.md section 3), via a trackerGNN (sih.perception.newTracker).
%
%   Does NOT read any ActorID - sih.perception.simulateSensors never puts one
%   on a detection, on purpose. A real sensor has no such field; this tracker
%   is written to prove it does not need one, only geometry (trackerGNN's own
%   nearest-neighbour gated association) and a motion model (initcvekf).
%
%   INPUTS
%     dets     1xN cell array of objectDetection, sih.perception.simulateSensors.
%              MAY BE EMPTY (cell(1,0)) - a genuine "nothing detected this
%              step", not an error.
%     tracker  a trackerGNN System object, already constructed by the caller
%              (sih.perception.newTracker) and reused across the WHOLE run -
%              see newTracker's own header for why.
%     t        double, seconds, STRICTLY INCREASING across calls (the
%              tracker's own clock; it errors on a repeated or decreasing t).
%
%   OUTPUT
%     tracks  the S1 TrackList struct array. MAY BE EMPTY (S1 guarantee 3).
%             Sorted by TrackID (guarantee 1). No NaN/Inf in Position - a
%             track that would produce one is dropped, not surfaced
%             (guarantee 4). Never contains the ego (guarantee 2 - trivially
%             true, the ego is never a detected object here).
%
%   FIELD MAPPING, and why each one means what it says (not a passthrough):
%     TrackID     trackerGNN's own - already stable, never reused, for free
%     ClassID     the associated detection's ObjectClassID (S5 - passed
%                 through sensing unchanged; classification error is a
%                 camera/ML-model concern, AGENTS.md section 2 keeps the
%                 camera OFFLINE, so there is no classifier to be wrong here)
%     Position,
%     Velocity    read straight off the constant-velocity filter's own state
%                 vector [x vx y vy z vz] - Velocity is never a measured
%                 quantity, it is the Kalman filter's own estimate, which is
%                 the actual point of running a filter instead of a
%                 finite-difference shortcut
%     Existence   mean(TrackLogicState) - the tracker's own M-of-N recent-hit
%                 window as a fraction, e.g. 2 hits of the last 3 -> 0.667.
%                 A real, continuous confidence derived from tracker
%                 internals, not a fudged constant
%     Age         trackerGNN's own frame counter since the track was created
%     SensorMask  bit-OR of every contributing detection's SensorBit this
%                 cycle (AGENTS.md S1: bit0 lidar, bit1 radar, bit3
%                 near-field ring). When two sensors both hit the same
%                 object in the same frame, trackerGNN keeps BOTH detections'
%                 ObjectAttributes on the track (ObjectAttributes becomes a
%                 struct array, not a scalar) - found by running this, not
%                 assumed; OR-ing across it is exactly what SensorMask is for.
%
%   A FRESH, NEVER-YET-CALLED tracker errors if its first call has zero
%   detections ("The first call to 'step' must have at least one detection.")
%   - found by running this, not documented anywhere obvious. Guarded below
%   via isLocked: before the tracker has ever seen a real detection, an empty
%   frame just returns an empty TrackList directly, matching S1 guarantee 3
%   without ever making the call that would error.

tracks = struct('TrackID',{},'ClassID',{},'Position',{},'Velocity',{}, ...
                'Extent',{},'Yaw',{},'Existence',{},'Age',{},'SensorMask',{});

if isempty(dets) && ~isLocked(tracker)
    return
end
tr = tracker(dets, t);

for k = 1:numel(tr)
    x   = tr(k).State;
    pos = [x(1) x(3) x(5)];
    vel = [x(2) x(4) x(6)];
    if any(~isfinite(pos)) || any(~isfinite(vel))
        continue                      % S1 guarantee 4: drop, never surface a NaN/Inf
    end
    att = tr(k).ObjectAttributes;     % may be a struct ARRAY - see header
    mask = uint8(0);
    for j = 1:numel(att)
        mask = bitor(mask, uint8(att(j).SensorBit));
    end
    existence = mean(double(tr(k).TrackLogicState(:)));

    tracks(end+1) = struct( ...                                       %#ok<AGROW>
        'TrackID',    uint32(tr(k).TrackID), ...
        'ClassID',    uint8(tr(k).ObjectClassID), ...
        'Position',   pos, ...
        'Velocity',   vel, ...
        'Extent',     att(1).Extent, ...
        'Yaw',        att(1).Yaw, ...
        'Existence',  existence, ...
        'Age',        uint32(tr(k).Age), ...
        'SensorMask', mask);
end

if ~isempty(tracks)
    [~, ord] = sort([tracks.TrackID]);
    tracks   = tracks(ord);
end
end
