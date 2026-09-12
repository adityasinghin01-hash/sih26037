function m = metrics(out, egoWidth, egoLen)
%METRICS  M1-M10 for one run. AGENTS.md section 3: results/<run>/metrics.json.
%   Every number here is measured off the logged trace. None is assumed.
arguments
    out struct
    egoWidth (1,1) double = 1.70
    egoLen   (1,1) double = 3.99
end
dt = out.SampleTime;
d  = [0; cumsum(vecnorm(diff([out.EgoX out.EgoY]),2,2))];

m.M1_distance_m   = d(end);
m.M2_duration_s   = out.T(end) - out.T(1) + dt;
m.M3_meanSpeed_kmh= 3.6*mean(out.EgoV);
m.M4_maxSpeed_kmh = 3.6*max(out.EgoV);
% M5: the safety barrier h = lambda - beta. NaN means no agent was in range, which is
% NOT "safe" - it is undefined, and NaN<0 is false so it cannot fake an EMERGENCY.
m.M5_minBarrier_rad = min(out.MinH, [], 'omitnan');
if isempty(m.M5_minBarrier_rad), m.M5_minBarrier_rad = NaN; end
m.M6_minClearance_m = out.MinClearance;
m.M7_stoppedTime_s  = dt*sum(out.EgoV < 0.2);
m.M8_maxDecel_mps2  = min(out.Accel);
% M9: did the ego actually get where it was going?
routeLen = sum(vecnorm(diff(out.Route),2,2));
m.M9_completed = d(end) >= 0.92*routeLen;
% M10: steering/offset wobble - COLREGs Rule 8 forbids a series of small alterations
m.M10_latWobble_m = sum(abs(diff(out.Lat)));

m.RouteLength_m   = routeLen;
m.EgoWidth_m      = egoWidth;
m.EgoLength_m     = egoLen;
m.BarrierViolations = sum(out.MinH < 0);
end
