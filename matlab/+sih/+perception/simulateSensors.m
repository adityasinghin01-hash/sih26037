function dets = simulateSensors(gt, egoPose, suite, t, rs)
%SIMULATESENSORS  Ground truth (sih.scenario.groundTruthTrack) -> this frame's
%   raw returns from every sensor in the suite, as objectDetection objects
%   ready for sih.perception.trackObjects (which feeds a trackerGNN).
%
%   PIPELINE POSITION: scenario (truth) -> HERE (sensing) -> trackObjects
%   (tracking) -> the S1 TrackList. Nothing upstream of here has noise;
%   nothing downstream of here ever sees ground truth again.
%
%   INPUTS
%     gt       struct array, sih.scenario.groundTruthTrack, WORLD frame
%     egoPose  struct .Position(1x3,world,m) .Yaw(rad,world) - the sensor mount
%     suite    struct array, sih.scenario.sensorSuite()
%     t        double, seconds - stamped onto every objectDetection. Must be
%              STRICTLY INCREASING across the calls of one run - trackerGNN
%              enforces this on the consuming side.
%     rs       RandStream, reused across the WHOLE run - constructing a fresh
%              one per frame would silently re-correlate every sensor's noise
%              from frame to frame. One seed makes an entire run reproducible.
%
%   OUTPUT
%     dets  1xN cell array of objectDetection (N may be 0 - a real frame in
%           which nothing was seen is not an error). Camera is never modelled:
%           AGENTS.md section 2 settled "lidar and radar in the loop, camera
%           offline" - sih.scenario.sensorSuite never returns a camera row, so
%           there is no camera branch here to skip.
%
%   PER (object, sensor) PAIR:
%     1. world position -> ego-relative range r and bearing theta (0 = dead
%        ahead, + = left, matching S1's "y left" convention)
%     2. cull: r > Range_m, or |theta| > FOV_rad/2 -> no return
%     3. probabilistic miss: detection probability ramps PdNear -> PdFar
%        linearly with r/Range_m (occlusion/RCS falloff stand-in - this
%        simulator does not ray-cast, so an occluded-by-another-vehicle miss
%        is not modelled, only a range-dependent one; disclosed limitation)
%     4. if detected: additive Gaussian noise in RANGE and BEARING, never in
%        raw xy - a real lidar/radar's bearing error grows with range and its
%        range error does not, and noising xy directly gets exactly this
%        backwards. The Cartesian MeasurementNoise handed to the tracker is
%        the first-order rotation of diag(sigma_r^2, (r*sigma_theta)^2) into
%        the world-aligned frame, not a flat isotropic guess.

arguments
    gt (1,:) struct
    egoPose (1,1) struct
    suite (1,:) struct
    t (1,1) double
    rs (1,1) RandStream
end

dets = {};
fwd = [cos(egoPose.Yaw) sin(egoPose.Yaw)];
lft = [-sin(egoPose.Yaw) cos(egoPose.Yaw)];

for i = 1:numel(gt)
    rel = gt(i).Position(1:2) - egoPose.Position(1:2);
    xF  = rel*fwd.';   xL = rel*lft.';
    r   = hypot(xF, xL);
    th  = atan2(xL, xF);

    for s = 1:numel(suite)
        cfg = suite(s);
        if r > cfg.Range_m || abs(th) > cfg.FOV_rad/2
            continue
        end
        pd = cfg.PdNear + (cfg.PdFar - cfg.PdNear) * min(1, r/cfg.Range_m);
        if rand(rs) > pd
            continue                                   % missed this frame
        end

        rN  = max(0, r + cfg.RangeNoiseStd_m   * randn(rs));
        thN = th       + cfg.BearingNoiseStd_rad * randn(rs);
        xFn = rN*cos(thN);  xLn = rN*sin(thN);
        posW = egoPose.Position(1:2) + xFn*fwd + xLn*lft;
        zN   = gt(i).Position(3) + 0.02*randn(rs);

        c  = cos(th);  si = sin(th);
        rot  = [c -si; si c];
        cov2 = rot * diag([cfg.RangeNoiseStd_m^2, (r*cfg.BearingNoiseStd_rad)^2]) * rot.';
        R    = blkdiag(cov2, 0.02^2);

        dets{end+1} = objectDetection(t, [posW zN].', ...                 %#ok<AGROW>
            'MeasurementNoise', R, 'SensorIndex', s, ...
            'ObjectClassID', gt(i).ClassID, ...
            'ObjectAttributes', struct('Extent',gt(i).Extent, 'Yaw',gt(i).Yaw, ...
                                        'SensorBit',cfg.Bit));
    end
end
end
