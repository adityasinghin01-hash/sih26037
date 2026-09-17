function tests = testSihDemo
%TESTSIHDEMO  PHASE 7 - the front door must refuse the broken scenarios LOUDLY.
%   A menu entry that stalls in front of a judge is worse than no entry at all.
tests = functiontests(localfunctions);
end

function testS2IsRefusedWithItsRealNumbers(tc)
% S2 must not be offerable, and the refusal must carry the measurement so the
% person asking learns the finding instead of just being blocked.
f = @() sihDemo("s2");
verifyError(tc, f, 'sihDemo:knownBroken');
try, sihDemo("chowk"); catch me, msg = me.message; end
verifySubstring(tc, msg, '-0.909');       % the sensed collision
verifySubstring(tc, msg, '116');          % where it stalls
verifySubstring(tc, msg, 'CLAIM-LEDGER'); % where to read the full account
end

function testUnknownNameIsRejected(tc)
verifyError(tc, @() sihDemo("s9"), 'sihDemo:unknown');
end

function testKnownAliasesResolve(tc)
% these must NOT throw an unknown-name error; they are the names a teammate
% or a judge would actually type
for nm = ["s1","cow","cattle","demo1","s3","galli","squeeze","demo3","all"]
    try
        sihDemo(nm);
    catch me
        verifyNotEqual(tc, string(me.identifier), "sihDemo:unknown", ...
            sprintf('"%s" should be a recognised name', nm));
    end
end
end
