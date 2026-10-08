function t = tCrit95(df)
%TCRIT95  Two-sided 95% critical value of Student's t, from a table.
%
%   MATLAB's tinv() lives in the Statistics and Machine Learning Toolbox, which
%   is NOT in this licence - verified 17 Sep 2026:
%       tinv FAILED: Undefined function 'tinv' for input arguments of type 'double'
%       ver('stats') -> empty
%   The campus TAH licence carries Automated Driving, Navigation, Stateflow, Deep
%   Learning, Sensor Fusion, Lidar, Radar, Vehicle Dynamics, Powertrain, Parallel
%   Computing and GPU Coder. It does not carry Statistics. benchRuns would have
%   died on its confidence-interval line on every machine this project runs on.
%
%   These are the standard published two-sided 0.05 critical values. They are a
%   TABLE, not a computation - stated plainly so nobody mistakes this for an
%   implementation of the inverse t distribution.
%
%   Above df = 30 the value is clamped to the df=30 entry (2.042) rather than
%   dropping to the normal 1.960. That is deliberate and conservative: it keeps
%   the interval slightly WIDER than the asymptotic answer, and on a safety
%   metric the wrong direction to err is narrow.

arguments
    df (1,1) double
end
T = [12.706 4.303 3.182 2.776 2.571 2.447 2.365 2.306 2.262 2.228 ...
      2.201 2.179 2.160 2.145 2.131 2.120 2.110 2.101 2.093 2.086 ...
      2.080 2.074 2.069 2.064 2.060 2.056 2.052 2.048 2.045 2.042];
if df < 1
    t = NaN;                       % n = 1: there is no interval, and none is reported
elseif df <= 30
    t = T(round(df));
else
    t = T(30);
end
end
