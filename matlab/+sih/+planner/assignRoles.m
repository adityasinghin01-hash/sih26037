function roles = assignRoles(egoPos, egoVel, egoYaw, tracks, opts)
%ASSIGNROLES  COLREGs-style role assignment from geometry alone.
%
%   No radio. No infrastructure. No shared map. Only relative geometry - which is what a
%   lidar tracker already gives us, and exactly why this works where auction- and V2I-based
%   methods cannot. A cow cannot bid in an auction, but a cow has a bearing and a course.
%
%   Sector boundaries 22.5 / 90 / 112.5 deg; the sign of tCPA separates a closing encounter
%   from an opening one. Verified in research section 12.
%
%   INPUTS
%     egoPos 1x2 double  ego position, m
%     egoVel 1x2 double  ego velocity, m/s
%     egoYaw double      ego heading, rad
%     tracks struct array  TrackList  (AGENTS.md section 3 S1)
%     opts.dMin_m      minimum separation, default 2.5 m
%     opts.maxRange_m  ignore agents beyond this, default 50 m
%
%   OUTPUT
%     roles  struct array  Role (AGENTS.md section 3 S4), same order as tracks

arguments
    egoPos (1,2) double
    egoVel (1,2) double
    egoYaw (1,1) double
    tracks struct
    opts.dMin_m     (1,1) double = 2.5
    opts.maxRange_m (1,1) double = 50
end

TH1 = deg2rad(22.5);
TH2 = deg2rad(90);
TH3 = deg2rad(112.5);

SAFE=uint8(0); GIVE_WAY=uint8(1); STAND_ON=uint8(2); HEAD_ON=uint8(3); OVERTAKING=uint8(4);

n = numel(tracks);
proto = struct('TrackID',uint32(0),'Role',SAFE,'Beta',NaN,'Lambda',NaN,'TCPA',NaN);
if n == 0
    roles = proto([]);          % honour the empty-TrackList guarantee, S1 rule 3
    return
end
roles = repmat(proto, n, 1);

for k = 1:n
    t = tracks(k);
    roles(k).TrackID = t.TrackID;

    vo = sih.planner.velocityObstacle(egoPos, egoVel, ...
            t.Position(1:2), t.Velocity(1:2), opts.dMin_m);

    roles(k).Beta   = vo.beta;
    roles(k).Lambda = vo.lambda;
    roles(k).TCPA   = vo.tcpa;

    if vo.d > opts.maxRange_m || vo.tcpa < 0
        roles(k).Role = SAFE;                 % out of range, or opening
        continue
    end

    relBearing = iWrapToPi(vo.bearing - egoYaw);
    trkYaw     = atan2(t.Velocity(2), t.Velocity(1));
    relHeading = iWrapToPi(trkYaw - egoYaw);

    absB = abs(relBearing);
    absH = abs(relHeading);

    if absH > (pi - TH1)
        roles(k).Role = HEAD_ON;              % Rule 14, reciprocal courses
    elseif absB > TH3
        roles(k).Role = STAND_ON;             % Rule 13, they overtake us -> we hold
    elseif absH < TH1 && absB < TH2
        roles(k).Role = OVERTAKING;           % Rule 13, we overtake them
    elseif relBearing < 0
        roles(k).Role = GIVE_WAY;             % Rule 15, agent to starboard
    else
        roles(k).Role = STAND_ON;             % Rule 17, hold course and speed
    end
end
end

function a = iWrapToPi(a)
a = mod(a + pi, 2*pi) - pi;
end
