function hw = s9Width(W, s)
%S9WIDTH  The corridor's half-width AT STATION s, m. Phase 6.
%
%   NOT constant on S2. Verified against scenarios/S2-THE-CHOWK.md: the ring
%   is IRC 65:2017 geometry - inscribed circle 40 m -> island 24 m ->
%   circulatory carriageway 8 m - one metre wider than the 7 m arms
%   (W.ArmW). The OLD sc.adapterS9 used W.ArmW everywhere, including on the
%   ring - a real, if safe-direction (understates room), inaccuracy this
%   replaces. S1 has no ring, so its width is a single constant throughout
%   the 783 m route - verified against scenarios/S1-CATTLE-CROSSING.md,
%   nothing in it describes the 7.0 m carriageway changing width.
%
%   INPUTS
%     W  the world struct (sc.s1world or sc.s2world). Dispatches on
%        isfield(W,'SRingIn') - only sc.s2world defines the ring stations.
%     s  current station, m
%
%   OUTPUT
%     hw  half-width, m

if isfield(W, 'SRingIn') && isfield(W, 'SRingOut')
    if s >= W.SRingIn && s < W.SRingOut
        hw = (W.Rout - W.Rin) / 2;      % the ring: 8 m / 2 = 4 m
    else
        hw = W.ArmW / 2;                % an arm: 7 m / 2 = 3.5 m
    end
else
    hw = W.Width / 2;                   % S1: one width, the whole route
end
end
