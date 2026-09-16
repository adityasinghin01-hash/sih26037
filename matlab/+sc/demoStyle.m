function S = demoStyle()
%DEMOSTYLE  The locked look for the checkpoint-driven 2D demo's close-up
%   drive view - Concept A (Survey/Blueprint) from the 11 Sep 2026 design
%   pick, with Concept B's boldness: same calm paper background and ink
%   road colour, but the road drawn wider and its edge darker/heavier so
%   it stays legible from across a room, which was the original complaint
%   this whole styling pass exists to answer.
%
%   ONE STRUCT, EVERY COLOUR AND WEIGHT IN IT - so the drive view, the
%   minimap (Phase 6) and any future renderer draw from the same source
%   and can never quietly drift apart into two different "locked" looks.
%
%   Deliberately NOT applied to sc.plannerView.m or demo_play.m - both are
%   shared with the live team's own Round 2 demo, and this is new,
%   additive code, not a change to what they already rely on.
%
%   opts.RoadWidthMult (not a param here, a constant below) exaggerates
%   the DRAWN road width beyond the real carriageway on purpose, the same
%   convention the pothole marker already uses (sc:s1... markers are map
%   symbols, not to scale) - a real 7 m carriageway drawn at true scale
%   reads as a hairline once anything else is on screen with it.

S.Background   = [0.97 0.96 0.93];   % Concept A paper tone, unchanged
S.RoadFill     = [0.20 0.19 0.17];   % darker than Concept A's 0.24 - more contrast
S.RoadEdge     = [0.08 0.07 0.06];   % near-black, Concept B's edge weight
S.RoadEdgeW    = 2.4;                % pt, up from Concept A's 1.2
S.RoadWidthMult= 1.35;               % drawn road is 1.35x the real carriageway width -
                                      % a legibility exaggeration, disclosed, not a claim
                                      % about the real road

S.LaneDash     = [0.97 0.95 0.90];   % bright, reads at a glance
S.LaneDashW    = 2.2;                % up from Concept A's 1.4
S.LaneSeg_m    = 4.0;   S.LaneGap_m = 3.0;

S.BuildingFill = [0.80 0.74 0.62];   % Concept A, unchanged - already read fine
S.BuildingEdge = [0.35 0.30 0.22];

S.EgoFill      = [0.13 0.32 0.60];   % navy, Concept A's ego colour, slightly deepened
S.EgoEdge      = [1 1 1];
S.EgoSize      = 15;                 % pt marker size

S.HazardRing   = [0.55 0.15 0.12];   % the pothole marker - Concept A's palette
S.HazardFill   = [0.30 0.10 0.08];
S.HazardR_m    = 1.3;                % drawn radius, m - a map symbol size, see header

S.TextColor    = [0.20 0.19 0.17];
S.TextBg       = [1 1 1 0.85];

% ---- Phase 2: forest (S1) and gyratory (S2) tokens, same locked family ----
S.ForestFill   = [0.32 0.42 0.24];   % muted olive - reads as canopy, not a lawn green
S.ForestAlpha  = 0.55;               % overlapping crowns should DENSIFY, not just stack edges
S.ForestEdge   = 'none';

S.IslandFill   = [0.38 0.46 0.28];   % S2's planted central island - close to ForestFill,
                                      % same "real vegetation" family, deliberately
S.RingFill     = S.RoadFill;         % the circulating carriageway IS a road surface
S.RingEdge     = S.RoadEdge;
S.PlinthFill   = [0.62 0.60 0.55];   % stone/concrete grey
S.PlinthEdge   = [0.30 0.29 0.26];

% ---- Phase 3: the rest of a scenario's furniture, one consistent family ----
S.PoleColor    = [0.45 0.42 0.36];
S.SignColor    = [0.55 0.30 0.15];
S.DrainColor   = [0.45 0.55 0.60];   % a cool grey-blue - reads as "wet/infrastructure"
S.ServiceColor = [0.55 0.52 0.44];
S.SideRoadColor= [0.62 0.60 0.54];
S.TreeDotFill  = S.ForestFill;       % roadside scatter trees match the forest family

% ---- Phase 4: density actors, grouped by kind not by the full S5 ClassID list ----
S.PersonColor  = [0.70 0.45 0.20];
S.AnimalColor  = [0.50 0.36 0.22];
S.CowColor     = [0.35 0.28 0.22];
S.VehicleColor = [0.25 0.35 0.55];

% ---- Phase 6: the minimap ----
S.MinimapRing  = S.RoadEdge;
S.MinimapBg    = [1 1 1];
end
