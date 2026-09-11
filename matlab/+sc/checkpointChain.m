function C = checkpointChain(opts)
%CHECKPOINTCHAIN  The real, connected 5-checkpoint route: S5 -> S1 -> S3
%   -> S2 -> S4, built and verified 11 Sep 2026 (see
%   sih26037-density-world-actors-done / this session's own build log).
%
%   SCOPED, NOT GENERAL: this hardcodes the one order that has actually
%   been measured (real connectors, real circuity, real join gaps < 5 cm)
%   - S5 and S4 reversed, S1/S3/S2 forward, exactly as that verification
%   found. A general "chain any order of checkpoints" router is future
%   work, not built here - over-building it now, unverified, would be
%   worse than not having it.
%
%   opts.Upto (default "S4"): build only as far as the named checkpoint,
%   in chain order - useful for a faster test render that doesn't need
%   the whole 4.8 km.
%
%   OUTPUT C:
%     .Path          the one merged sc.path for everything built
%     .Checkpoints   struct array, in chain order, each with:
%        .Name        "S1" etc
%        .W           that scenario's own world struct (sc.s1world() etc)
%        .LocalPath   the sc.path/EgoRoute driven for it (BEFORE any flip)
%        .Reversed    logical - true if driven back-to-front in this chain
%        .SpanStart / .SpanEnd   this checkpoint's own station range on
%                     C.Path (its own content only, not the connectors)
%        .DensitySpec the {ClassID,...} cell array from sc.<x>density(),
%                     or {} for S2 (no density layer built for it - out
%                     of scope for the 5-scenario density initiative)
%        .Kind        "linear" or "gyratory" - which drawer to use

arguments
    opts.Upto string = "S4"
end

order = ["S5" "S1" "S3" "S2" "S4"];
stop = find(order == opts.Upto, 1);
assert(~isempty(stop), "sc:badCheckpoint", "unknown checkpoint %s", opts.Upto);
order = order(1:stop);

fprintf('[checkpointChain] building %s...\n', strjoin(order, " -> "));
W1 = sc.s1world();  [spec1,~] = sc.s1density();
W3 = sc.s3world();  [spec3,~] = sc.s3density();
W4 = sc.s4world();  [spec4,~] = sc.s4density();
W5 = sc.s5world();  [spec5,~] = sc.s5density();
W2 = sc.s2world();

centre = [-265 -35]; radius = 1300;
R = sc.localRoads(centre, radius);

A5=[-603.6 711.6];
A1=[-496.1 654.1]; B1=[-12.8 300.2];
A3=[8.3 -362.9];   B3=[-144.9 -709.0];
B4=[42.0 -699.7];
entryD = W2.EgoRoute.P(1,:);
exitA  = W2.EgoRoute.P(end,:);

all5 = struct( ...
    'S5', struct('W',W5,'Local',W5.Path,'Reversed',true, 'Spec',{spec5}, 'Kind',"linear"), ...
    'S1', struct('W',W1,'Local',W1.Path,'Reversed',false,'Spec',{spec1}, 'Kind',"linear"), ...
    'S3', struct('W',W3,'Local',W3.Path,'Reversed',false,'Spec',{spec3}, 'Kind',"linear"), ...
    'S2', struct('W',W2,'Local',W2.EgoRoute,'Reversed',false,'Spec',{{}},'Kind',"gyratory"), ...
    'S4', struct('W',W4,'Local',W4.Path,'Reversed',true, 'Spec',{spec4}, 'Kind',"linear"));

connFn = { ...
    @() sc.shortestRoute(R, A5, A1), ...
    @() sc.shortestRoute(R, B1, A3), ...
    @() sc.shortestRoute(R, B3, entryD, 'nodeTol_m', 5.0), ...
    @() sc.shortestRoute(R, exitA, B4, 'nodeTol_m', 5.0)};

raw = zeros(0,2);
C.Checkpoints = struct('Name',{},'W',{},'LocalPath',{},'Reversed',{},'SpanStart',{},'SpanEnd',{},'DensitySpec',{},'Kind',{});
offset = 0;
for i = 1:numel(order)
    nm = order(i);
    cp = all5.(nm);
    localP = cp.Local.P;
    if cp.Reversed, localP = flipud(localP); end
    if isempty(raw)
        raw = localP;
    else
        raw = [raw; localP(2:end,:)]; %#ok<AGROW>
    end
    spanStart = offset; spanEnd = offset + cp.Local.Len;
    C.Checkpoints(end+1) = struct('Name',nm,'W',cp.W,'LocalPath',cp.Local, ...
        'Reversed',cp.Reversed,'SpanStart',spanStart,'SpanEnd',spanEnd, ...
        'DensitySpec',{cp.Spec},'Kind',cp.Kind);
    offset = spanEnd;
    if i < numel(order)
        conn = connFn{i}();
        raw = [raw; conn(2:end,:)]; %#ok<AGROW>
        offset = offset + sum(vecnorm(diff(conn),2,2));
    end
end

C.Path = sc.path(raw, 1.0);
fprintf('[checkpointChain] built: %.1f m total, %d checkpoints\n', C.Path.Len, numel(C.Checkpoints));
end
