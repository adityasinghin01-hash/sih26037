%S1_LOOK  ONE shot, fast, so a colour can be iterated instead of guessed.
%
%   The five-shot verification run costs 5-8 minutes, which is too slow a loop to
%   converge a colour on. REF-13 measured Aditya's photographs in PIXELS, so ours have
%   to be judged in pixels too - and the only honest way to hit a pixel target is
%   change, render, MEASURE, repeat. This renders the single driver's-eye frame that
%   matters and nothing else.
%
%   Run:  matlab -batch "run('.../matlab/s1_look.m')"
%   Then: python3 tools/measure.py renders/s1_look.png

here = fileparts(mfilename('fullpath'));
addpath(here);
outDir = fullfile(here,'renders');
W = sc.s1world();
P = W.Path;  CS = W.CowStation;
S = sc.scene('Hud', false, 'Width', 1400, 'Height', 800);
t0 = tic;
s0 = CS - 22;
[e0, ~] = P.at(s0, 1.75);
tgt = P.at(s0 + 46, 1.10);
st = sc.s1render(S, W, 'Focus', P.at(s0 + 40, 0), 'Radius', 200, 'Probe', true);
S.look([e0 1.35], [tgt 1.05], 34);
S.save(fullfile(outDir,'s1_look.png'));
S.close();
fprintf('[look] %.1f s | %d far + %d authored trees, %d scrub\n', ...
        toc(t0), st.Trees, st.TreesDetailed, st.Scrub);
