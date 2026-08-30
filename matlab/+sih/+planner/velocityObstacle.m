function vo = velocityObstacle(egoPos, egoVel, trkPos, trkVel, dMin_m)
%VELOCITYOBSTACLE  Collision-cone geometry for one ego-agent pair.
%
%   Implements the velocity obstacle formulation verified in research section 15.
%   Every quantity is scalar and cheap; this runs per track, per step.
%
%   INPUTS
%     egoPos  1x2 double  [x y] ego position,   m
%     egoVel  1x2 double  [vx vy] ego velocity, m/s
%     trkPos  1x2 double  [x y] agent position, m
%     trkVel  1x2 double  [vx vy] agent velocity, m/s
%     dMin_m  double      minimum separation (sum of radii + margin), m
%
%   OUTPUT  vo struct
%     .d         range, m
%     .beta      cone half-angle, rad     beta = asin(dMin/d)
%     .lambda    angle between relative velocity and line of sight, rad
%     .h         barrier value lambda - beta.  h >= 0 is safe
%     .colliding true iff lambda < beta
%     .tcpa      time to closest approach, s.  Negative = opening
%     .dcpa      distance at closest approach, m
%     .bearing   absolute bearing of the agent, rad
%
%   WHY THE VO FORM, NOT THE COLLISION-CONE FORM
%   The collision-cone barrier is undefined when relative velocity is zero - exactly the
%   standing-still case an Indian junction produces constantly. The VO form stays defined.
%   Research section 15.

arguments
    egoPos (1,2) double
    egoVel (1,2) double
    trkPos (1,2) double
    trkVel (1,2) double
    dMin_m (1,1) double {mustBePositive}
end

r  = trkPos - egoPos;
d  = norm(r);
vr = egoVel - trkVel;
nv = norm(vr);

vo = struct('d',d,'beta',NaN,'lambda',NaN,'h',NaN, ...
            'colliding',false,'tcpa',NaN,'dcpa',d,'bearing',NaN);

if d <= dMin_m
    vo.beta=pi/2; vo.lambda=0; vo.h=-pi/2;
    vo.colliding=true; vo.tcpa=0; vo.dcpa=d;
    vo.bearing=atan2(r(2),r(1));
    return
end

vo.beta = asin(dMin_m / d);

if nv < 1e-6
    vo.lambda    = pi;
    vo.h         = pi - vo.beta;
    vo.colliding = false;
    vo.tcpa      = Inf;
    vo.dcpa      = d;
else
    c            = dot(vr, r) / (nv * d);
    vo.lambda    = acos( min(1, max(-1, c)) );
    vo.colliding = vo.lambda < vo.beta;
    vo.h         = vo.lambda - vo.beta;
    vo.tcpa      = dot(r, vr) / (nv^2);
    vo.dcpa      = norm(r - vo.tcpa * vr);
end

vo.bearing = atan2(r(2), r(1));
end
