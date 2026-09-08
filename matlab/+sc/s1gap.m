function g = s1gap(W, egoS, egoE, obs, egoDim, opts)
%S1GAP  THE LIVE GAP ARITHMETIC. Measured every step from real poses.
%
%   This is the S1 result. Not a constant computed once at the top of a script and
%   printed on screen - the free width is re-measured from wherever the obstacle
%   actually is, every frame, so the HUD number is the planner's own measurement.
%
%   For each obstacle ahead of the ego inside the look-ahead, its lateral band is
%   projected onto the road normal using its OWN yaw and its OWN asserted mesh
%   dimensions - which is what caught the cow standing broadside in Phase 3, where a
%   0.64 m width had been assumed for an animal occupying 2.05 m.
%
%   g.Free      m   widest clear width beside the binding obstacle
%   g.Side      +1 pass on the LEFT of it, -1 pass on the RIGHT
%   g.PassE     m   lateral offset of the centre of that gap
%   g.Margin    m   (Free - ego width) / 2, i.e. clearance each side
%   g.Fits      logical, Margin >= opts.Require
%   g.Binding   the obstacle index, and .Range m ahead

arguments
    W struct; egoS (1,1) double; egoE (1,1) double
    obs struct; egoDim (1,3) double
    opts.Look    (1,1) double = 60
    opts.Require (1,1) double = 0.90        % SPEC: ">= 0.90 m each side"
end

CW = W.Width;  P = W.Path;
g = struct('Free', CW, 'Side', -1, 'PassE', -CW/4, 'Margin', (CW-egoDim(2))/2, ...
           'Fits', true, 'Binding', 0, 'Range', inf, 'OccNear', NaN, 'OccFar', NaN);

best = inf;
for i = 1:numel(obs)
    rng_ = obs(i).s - egoS;
    if rng_ > opts.Look, continue; end
    [~, hRoad] = P.at(obs(i).s, 0);
    th = obs(i).yaw - hRoad;                              % yaw relative to the road
    halfW = (abs(obs(i).dim(1)*sin(th)) + abs(obs(i).dim(2)*cos(th))) / 2;
    halfL = (abs(obs(i).dim(1)*cos(th)) + abs(obs(i).dim(2)*sin(th))) / 2;
    % AN OBSTACLE YOU ARE LEVEL WITH IS STILL AN OBSTACLE. Skipping everything with
    % rng_ < 0 meant the cow stopped counting the instant the ego drew alongside, so
    % the gap read 7.00 m - the whole carriageway - at exactly the moment the number
    % matters most. Anything still overlapping longitudinally stays in.
    if rng_ < -(egoDim(1)/2 + halfL), continue; end
    near = obs(i).e - halfW;  far = obs(i).e + halfW;     % + is LEFT
    if far < -CW/2 || near > CW/2, continue; end          % not on the carriageway
    key = max(0, rng_);          % anything level with us sorts first
    if key < best
        best = key;
        freeRight = near - (-CW/2);                       % clear width to its right
        freeLeft  = (CW/2) - far;                         % clear width to its left
        if freeRight >= freeLeft
            g.Free = freeRight;  g.Side = -1;  g.PassE = (near + (-CW/2))/2;
        else
            g.Free = freeLeft;   g.Side = +1;  g.PassE = (far + (CW/2))/2;
        end
        g.Margin  = (g.Free - egoDim(2)) / 2;
        g.Binding = i;  g.Range = rng_;
        g.OccNear = near;  g.OccFar = far;
    end
end
g.Fits = g.Margin >= opts.Require;
end
