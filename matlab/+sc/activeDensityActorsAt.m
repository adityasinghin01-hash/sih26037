function A = activeDensityActorsAt(spec, P, t)
%ACTIVEDENSITYACTORSAT  Which of a density spec's rows exist at time t, and
%   where. Same math as demo_play.m's own local activeActorsAt (a private
%   function there, not exported), duplicated here rather than shared so
%   this initiative never has to edit demo_play.m - see sc.s1density's own
%   header. If demo_play.m's version ever changes, this one does not follow
%   it automatically; that is a disclosed cost of the duplication, not an
%   oversight.
%
%   spec is the {ClassID, s0, lateral0, Extent[L W H], along-route speed
%   (- = oncoming), extra yaw rad, [lateral target], [t1 t2]} cell array
%   sc.s1density (and its future S3/S4/S5 siblings) build.
%
%   A = struct array: .Row .ClassID .XY .YawRad .Vel .Extent - the exact
%   shape sc.plannerView's 'step' expects for one track (plus TrackID,
%   added by the caller).

A = struct('Row',{},'ClassID',{},'XY',{},'YawRad',{},'Vel',{},'Extent',{});
for k = 1:size(spec,1)
    if ~isfinite(spec{k,3}), continue; end
    u = spec{k,2} + spec{k,5}*t;
    if u < 2 || u > P.Len - 2, continue; end
    lat = spec{k,3};  latRate = 0;
    if size(spec,2) >= 8 && ~isempty(spec{k,7}) && ~isempty(spec{k,8})
        tw = spec{k,8};  dLat = spec{k,7} - spec{k,3};
        frac = max(0, min(1, (t - tw(1)) / (tw(2) - tw(1))));
        lat = spec{k,3} + dLat*frac;
        if t > tw(1) && t < tw(2), latRate = dLat / (tw(2) - tw(1)); end
    end
    [xy, hdg] = P.at(u, lat);
    yaw = hdg + spec{k,6};  vel = [0 0 0];
    if spec{k,5} < 0
        yaw = hdg + pi;
        vel = spec{k,5}*[cos(hdg) sin(hdg) 0];
    end
    if latRate ~= 0
        vel = vel + latRate*[-sin(hdg) cos(hdg) 0];
    end
    A(end+1) = struct('Row',k,'ClassID',spec{k,1},'XY',xy,'YawRad',yaw, ...
        'Vel',vel,'Extent',spec{k,4}); %#ok<AGROW>
end
end
