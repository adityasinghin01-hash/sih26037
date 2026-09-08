function vr = s9VisibleRange(W, s, e, opts)
%S9VISIBLERANGE  Furthest confidently-observed ground ahead, m. Phase 6.
%
%   AGENTS.md section 3 S9 defines this as "furthest confidently-observed
%   GROUND along the path" - the driving surface, not a specific hazard. That
%   distinction matters and was found by testing two wrong designs first, not
%   guessed:
%
%   1. sc.path.sightDistance was tried first and REJECTED: tested against a
%      synthetic occluder, it returned a near-binary maxLook/0 rather than a
%      real distance - its far-to-near scan order returns immediately on the
%      FARTHEST check, which is occluded by almost any intervening object
%      once maxLook is large. A real defect in an existing +sc utility, left
%      untouched here (fixing someone else's tested code is out of scope) -
%      this function does its own near-to-far scan with sc.path.visible
%      instead, which IS correct (verified: a fixed occluder gives a
%      monotonically shrinking clear distance as the eye approaches it).
%   2. Checking sight to the VERGE (halfWidth + shoulder, on the reasoning
%      that hazards emerge from the verge, not mid-lane) was tried second and
%      ALSO REJECTED: swept across the whole 610 m route, it read 2-40 m
%      almost everywhere, never near-clear except right at the very end.
%      S1's own vegetation design puts the tree mass close behind a narrow
%      verge basically continuously (REF-06: "no transition, no mulch ring,
%      no bed") - so a fixed verge-offset ray meets SOME nearby trunk within
%      a few metres almost anywhere, which is normal roadside vegetation, not
%      a safety-relevant sight limit. Feeding that into speedLimit's SIGHT
%      term would cap the ego near zero for nearly the whole road - wrong in
%      exactly the direction that breaks the scenario's own 52 km/h cruise.
%
%   What's actually asked for is sight to the ROAD ITSELF, which S1's own
%   corridor design (sc.s1world's CorridorHalf keeps every trunk >=6 m off
%   the centreline) keeps clear almost everywhere BY DESIGN - so a centreline
%   sight-line reading near-maximum for most of the route is the CORRECT
%   answer, not a sign the check is doing nothing. It degrades only where
%   the design says it should (verified: drops well short of maxLook near
%   the village end, s~180 short of the cow, where huts and denser village
%   trees sit closer to the road). The cow's own reveal-at-42m is a
%   SEPARATE, hazard-specific fact (sc.s1world's own W.RevealDistance,
%   already solved and asserted) - S9 is not the mechanism that anticipates
%   a specific hidden hazard; the tracker (Phase 5) is, once she is close
%   enough to actually be sensed.
%
%   S2 does NOT have an occluder map (sc.s2world never built one - the ring's
%   sight lines depend on 58 building frontages this project has not
%   authored as ray-cast occluders). Rather than invent a number silently,
%   this uses opts.FallbackVisible_m, which the CALLER must choose and
%   disclose - default is the one real, documented number the S2 spec itself
%   states: IRC's own "weaving length minimum 30 m at 30 km/h" (verified
%   against scenarios/S2-THE-CHOWK.md), i.e. the sight distance the gyratory
%   is DESIGNED to guarantee, not a made-up constant. Honestly a smaller-scope
%   treatment than S1's - disclosed, not hidden.
%
%   INPUTS
%     W    the world struct. Dispatches on isfield(W,'Occluders').
%     s    current station, m
%     e    current lateral offset, m (+ left) - the ray-cast's own eye
%          position uses this, because the eye is wherever the ego actually
%          is, not always lane-centre
%   opts.MaxLook_m         ray-cast search limit, m,       default 140
%   opts.Step_m            scan step, m,                  default 2
%   opts.FallbackVisible_m used only when W has no Occluders, default 30
%                          (IRC weaving-length minimum, S2's own number)
%
%   OUTPUT
%     vr  double, m

arguments
    W struct
    s (1,1) double
    e (1,1) double
    opts.MaxLook_m (1,1) double = 140
    opts.Step_m (1,1) double = 2
    opts.FallbackVisible_m (1,1) double = 30
end

if isfield(W, 'Occluders')
    vr = opts.MaxLook_m;
    for ds = 4:opts.Step_m:opts.MaxLook_m
        if ~W.Path.visible(s, e, s+ds, 0, W.Occluders)
            vr = max(0, ds - opts.Step_m);
            break
        end
    end
else
    vr = opts.FallbackVisible_m;
end
end
