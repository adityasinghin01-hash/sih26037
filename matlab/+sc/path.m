classdef path < handle
%PATH  A road centreline with a station/lateral frame, resampled to exact metres.
%
%   Everything in a scenario is described as "s metres along, e metres to the left".
%   That is how the written scripts describe it ("the culvert at 158 m", "the cow steps
%   out at 300 m"), so the code should speak the same language.
%
%   SIGN CONVENTION - GET THIS WRONG AND EVERY ENCOUNTER INVERTS
%   e is metres from the centreline, POSITIVE IS LEFT of the direction of travel.
%   INDIA DRIVES ON THE LEFT, so our own lane is POSITIVE (+W/4) and oncoming
%   traffic is NEGATIVE. Matches chooseVelocity's "positive is left" frame.

    properties
        P      (:,2) double     % resampled centreline, 1 m stations
        Hdg    (:,1) double     % heading at each station, rad, unwrapped
        Len    (1,1) double     % total length, m
        Step   (1,1) double = 1.0
    end

    methods
        function o = path(centre, step)
            if nargin<2, step=1.0; end
            o.Step = step;
            s = [0; cumsum(vecnorm(diff(centre),2,2))];
            [s, iu] = unique(s,'stable'); centre = centre(iu,:);
            q = (0:step:s(end))';
            if q(end) < s(end), q(end+1) = s(end); end
            o.P = [interp1(s,centre(:,1),q), interp1(s,centre(:,2),q)];
            o.Len = s(end);
            d = [diff(o.P); o.P(end,:)-o.P(end-1,:)];
            o.Hdg = unwrap(atan2(d(:,2), d(:,1)));
            assert(all(isfinite(o.P(:))), "sc:pathNaN", "path contains NaN");
            assert(o.Len > 1, "sc:pathShort", "path is only %.2f m", o.Len);
        end

        function [xy, hdg] = at(o, s, e)
            %AT  World position at station s, lateral offset e (+ is LEFT).
            if nargin<3, e=0; end
            s = max(0, min(o.Len, s));
            i = max(1, min(size(o.P,1)-1, floor(s/o.Step)+1));
            f = (s - (i-1)*o.Step)/o.Step;
            xy0 = o.P(i,:)*(1-f) + o.P(i+1,:)*f;
            hdg = o.Hdg(i)*(1-f) + o.Hdg(i+1)*f;
            nrm = [-sin(hdg), cos(hdg)];        % left normal
            xy  = xy0 + e.*nrm;
        end

        function [s, e] = inverse(o, xy)
            %INVERSE  Nearest station and lateral offset of a world point.
            d = vecnorm(o.P - xy, 2, 2);
            [~,i] = min(d);
            s = (i-1)*o.Step;
            h = o.Hdg(i); nrm = [-sin(h), cos(h)];
            e = dot(xy - o.P(i,:), nrm);
        end

        function k = curvature(o, win)
            %CURVATURE  |dheading/ds|, smoothed. High where the road bends.
            if nargin<2, win=25; end
            k = movmean(abs(gradient(o.Hdg))/o.Step, win);
        end

        function d = sightDistance(o, s, occluders, maxLook, targetE, eyeE)
            %SIGHTDISTANCE  How far ahead a target at lateral offset targetE is visible.
            %   Marches forward and returns the first distance at which the line of
            %   sight is CLEAR, having been blocked closer in.
            %
            %   THIS IS WHAT MAKES THE REVEAL GEOMETRIC RATHER THAN SCRIPTED: the cow
            %   becomes visible because the treeline and the bend stop hiding it, not
            %   because a timer fired. targetE matters - the cow emerges at the LEFT
            %   VERGE, tucked behind the undergrowth, so the line that decides the
            %   reveal runs to +4.6 m, not to the centreline.
            arguments
                o; s (1,1) double; occluders double
                maxLook (1,1) double = 140
                targetE (1,1) double = 0
                eyeE    (1,1) double = 1.75
            end
            eye = o.at(s, eyeE); d = maxLook;
            for ds = maxLook:-2:4
                tgt = o.at(s+ds, targetE);
                if occluded(eye, tgt, occluders), d = ds; return; end
            end
            d = 0;                                  % clear all the way
        end

        function [tf, blocker] = visible(o, sEye, eEye, sTgt, eTgt, occ)
            %VISIBLE  Is the target visible from the eye, and if not, what blocks it?
            %   The single question the S1 result rests on, exposed so a render can be
            %   CHECKED against it rather than eyeballed. Returns the blocking occluder
            %   row so the picture and the number can be matched to the same bush.
            a = o.at(sEye, eEye);
            b = o.at(sTgt, eTgt);
            blocker = [];
            if isempty(occ), tf = true; return; end
            ab = b - a; L2 = sum(ab.^2);
            if L2 < 1e-9, tf = true; return; end
            t  = ((occ(:,1)-a(1))*ab(1) + (occ(:,2)-a(2))*ab(2)) / L2;
            t  = max(0, min(1, t));
            dd = hypot(occ(:,1) - (a(1)+t*ab(1)), occ(:,2) - (a(2)+t*ab(2)));
            hit = dd < occ(:,3);
            tf = ~any(hit);
            if ~tf
                k = find(hit);
                [~, j] = min(dd(k) - occ(k,3));      % the deepest intrusion
                blocker = occ(k(j), :);
            end
        end

        function d = revealDistance(o, targetS, targetE, occluders, maxLook)
            %REVEALDISTANCE  How far short of the target the driver first sees it.
            %   Walks the approach and returns the largest gap at which the sight line
            %   to the target is CLEAR and stays clear. That distance is the reveal.
            arguments
                o; targetS (1,1) double; targetE (1,1) double
                occluders double; maxLook (1,1) double = 160
            end
            d = 0;
            for gap = 4:2:maxLook
                s = targetS - gap;
                if s < 0, break; end
                eye = o.at(s, 1.75);
                tgt = o.at(targetS, targetE);
                if occluded(eye, tgt, occluders)
                    return                          % blocked here -> the last clear gap stands
                end
                d = gap;
            end
        end
    end
end

function tf = occluded(a, b, occ)
%OCCLUDED  Does the segment a->b pass within r of any occluder centre?
tf = false;
if isempty(occ), return; end
ab = b-a; L2 = sum(ab.^2);
if L2 < 1e-9, return; end
t = ((occ(:,1)-a(1))*ab(1) + (occ(:,2)-a(2))*ab(2)) / L2;
t = max(0, min(1, t));
px = a(1) + t*ab(1);  py = a(2) + t*ab(2);
dist = hypot(occ(:,1)-px, occ(:,2)-py);
tf = any(dist < occ(:,3));
end
