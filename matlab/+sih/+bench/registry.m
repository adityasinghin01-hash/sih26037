function reg = registry()
%REGISTRY  Every driver sharing sc.planSeat's own [cmd,st]=driver(st,ctx)
%   contract, registered by name. Phase 1 of the planner/ML side-build
%   ("Bring Your Own Planner" benchmark, 11 Sep 2026).
%
%   Three real drivers already exist against this exact socket - this file
%   invents none of them, it only names them so demo_play('demo1',
%   Driver=name) and sih.bench.score can select one without hardcoding which:
%
%     "planner"     sc.planSeat     - the real contingency planner
%                                     (sih.planner.planContingency underneath).
%                                     THE DEFAULT - byte-identical to every
%                                     demo_play call before this file existed.
%     "placeholder" sc.s1drive      - the scripted rule-based driver. Senses
%                                     nothing, deterministic, no planning at
%                                     all - the original "does it even work"
%                                     floor every planner result is measured
%                                     against (s1_planner_run.m's own
%                                     "placeholder 0.965" comparison).
%     "defensive"   sc.s1defensive  - stops for anything blocking and never
%                                     overtakes. This is the FROZEN-ROBOT
%                                     comparison: proves a purely defensive
%                                     rule cannot finish a road with a cow
%                                     standing on it, which is S1's whole
%                                     argument for needing a real planner.
%
%   OUTPUT  reg  1x1 struct, one field per driver name -> function handle.
%           fieldnames(reg) is the list of valid Driver= names.
reg = struct( ...
    'planner',     @sc.planSeat, ...
    'placeholder', @sc.s1drive, ...
    'defensive',   @sc.s1defensive);
end
