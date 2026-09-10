function cid = classIDByName(tag)
%CLASSIDBYNAME  A +sc scenario actor TAG -> AGENTS.md section 3 S5 ClassID.
%
%   The +sc scenario builders (s1actors.m, s2actors.m, matlab/+sc/ in this
%   repo) key their `who` map by a short role tag, not by the S5 class name
%   (sih.util.classNames) - and S1 and S2 do not even agree with each other:
%   S1 uses 'moto_wrong'/'moto_over' for its two motorbike roles, S2 uses
%   plain 'wrong' for the same role, and S2 alone adds 'bus' and 'ace'. This
%   is the one place every tag either scenario has ever used is mapped, so
%   sih.scenario/+perception and +sc can never silently disagree about what
%   a tag means.
%
%   cid = sih.scenario.classIDByName("ace")   % -> uint8(7)
%
%   ClassID choices and why (S5, AGENTS.md section 3):
%     cow            -> 10 cow
%     car            -> 1  car                  (demo_play.m's oncoming vehicle)
%     auto           -> 4  auto-rickshaw
%     moto_wrong,
%     moto_over,
%     wrong          -> 5  motorbike            (three tags, one class)
%     tractor        -> 14 tractor
%     trolley        -> 13 animal-drawn cart
%     bus            -> 3  bus
%     ace            -> 7  van   (S5 has no light-commercial-vehicle class; a
%                                 Tata Ace mini-truck sits closer to "van" than
%                                 to "truck", which better fits S1's own
%                                 full-size tractor-trailer-adjacent traffic)
%     dog            -> 11 dog                  (demo3Route.m's dog in the squeeze)
%
%   Returns NaN (not an error) for an unrecognised tag, so a caller can drop
%   the actor rather than crash - matching the S1 guarantee that perception
%   degrades gracefully on unexpected input, never errors.

arguments
    tag (1,1) string
end

MAP = containers.Map( ...
    {'cow', 'car', 'auto', 'moto_wrong', 'moto_over', 'wrong', 'tractor', 'trolley', 'bus', 'ace', 'dog'}, ...
    {10,     1,     4,       5,            5,           5,       14,        13,       3,     7,    11});

t = char(tag);
if isKey(MAP, t)
    cid = uint8(MAP(t));
else
    cid = NaN;
end
end
