classdef NegotiatingStrategy < DrivingStrategy
%NEGOTIATINGSTRATEGY  A vehicle that negotiates instead of waiting for permission.
%
%   Subclasses OpenTrafficLab's DrivingStrategy and removes the one thing an Indian
%   junction does not have: a central authority.
%
%   WHAT THE BASE CLASS DOES THAT WE REPLACE
%     DrivingStrategy calls getNextNodeState(); the Node answers from its TrafficController's
%     IsOpen flag; the vehicle obeys. That is a signal. We delete the query and decide from
%     geometry instead. See AGENTS.md section 2.
%
%   OVERRIDDEN
%     determineDrivingMode    - sets our S8 PlannerMode, returns the BASE class's mode string
%     determineDrivingInputs  - command from the COLREGs role and the velocity obstacle
%     initializeUDStates      - allocate role storage      (protected, to match the superclass)
%     updateUDStates          - log the barrier every step (protected, to match the superclass)
%
%   NOT TOUCHED
%     move()          - the base class integration loop
%     carFollowing()  - Gipps/IDM is a perfectly good longitudinal model
%
%   TWO KINDS OF "MODE", AND THEY ARE NOT THE SAME AXIS
%   The base class's `Mode` is a CHAR naming a car-following regime - 'CarFollowing',
%   'ApproachingRedLight', 'ApproachingGreenLight' - and its determineDrivingInputs switches
%   on exactly those three strings with no otherwise branch. Our S8 PlannerMode is a uint8
%   (0 STRUCTURED, 1 UNSTRUCTURED, 2 EMERGENCY). Returning the uint8 from
%   determineDrivingMode leaves the base switch matching nothing, so leaderSpacing and delVel
%   are never assigned and carFollowing() errors on the first step. So we keep the two
%   separate: PlannerMode is a property, and determineDrivingMode returns the base string.
%
%   FRAME - READ THIS BEFORE WIRING STREAM B'S TRACKS IN
%   localTracks() emits positions in the SCENARIO (world) frame, and egoState() returns the
%   ego pose in the same frame, because assignRoles subtracts one from the other. AGENTS.md
%   S1 defines TrackList Position in the EGO frame. The two are only interchangeable when
%   the caller is consistent: an ego-frame TrackList must be passed with egoPos = [0 0] and
%   egoYaw = 0. See the header of sih.planner.assignRoles and the two frame tests in
%   matlab/tests/testPlannerGeometry.m.
%
%   See AGENTS.md section 3 S1 (TrackList), S4 (Role, EgoCommand), S7 (role codes),
%   S8 (planner mode).

    properties
        Roles       = struct('TrackID',{},'Role',{},'Beta',{},'Lambda',{},'TCPA',{})
        PlannerMode uint8  = 1      % 0 STRUCTURED, 1 UNSTRUCTURED, 2 EMERGENCY  (S8)
        MinBarrier  double = NaN    % min h = lambda - beta this step. h < 0 is a violation.
                                    % NaN means no agent was in range, so h is undefined -
                                    % NOT "safe". It plots as a gap instead of a spike, and
                                    % NaN < 0 is false, so it cannot trigger EMERGENCY.
        DMin_m      double = 2.5    % minimum separation for the velocity obstacle
        YieldProb                   % from the ONNX predictor; empty until Stream C wires it
        LastTracks                  % the S1 TrackList this strategy last saw, for inspection.
                                    % Person B's chart is fed exactly this; it is also what
                                    % makes the "ego in its own track list" and "wrong ClassID
                                    % numbering" defects testable from outside the class.

        % REQUIRED BY R2026a - DO NOT DELETE. OpenTrafficLab was written for R2020b and its
        % DrivingStrategy does not declare this. Since then driving.scenario.Vehicle reads
        % `obj.MotionStrategy.ReferencePoint` unconditionally (Vehicle.m line 63), and
        % MathWorks added the property to their own concrete strategies (Path, SmoothTrajectory)
        % but NOT to the abstract base driving.scenario.MotionStrategy. So every third-party
        % MotionStrategy subclass predating that change now dies the moment advance() runs:
        %   MATLAB:noSuchMethodOrField - Unrecognized method, property, or field
        %   'ReferencePoint' for class 'sih.planner.NegotiatingStrategy'
        %     at actorPoses -> drivingScenario.setUpSensorSimulation -> advance
        % "" selects the rear-axle branch, which is the pre-R2026a behaviour, so this restores
        % the original semantics rather than changing them. Verified by running: check05.
        ReferencePoint = ""
    end

    methods
        function obj = NegotiatingStrategy(egoActor, varargin)
            obj@DrivingStrategy(egoActor, varargin{:});
            % TODO(stream-D): an unmarked road has no lane to keep, so this wants to be false.
            % It is left true until Person B's chart owns lateral control, because the base
            % class never updates ForwardVector ("to be implemented", DrivingStrategy.move)
            % and with StaticLaneKeeping false nothing else does either - the car would hold a
            % stale heading for the whole run and never turn. Flip it in D3/D4, not before.
            obj.StaticLaneKeeping = true;
        end

        function mode = determineDrivingMode(obj, tNow)
            % Sets our S8 PlannerMode as a side effect, then returns the BASE class's mode
            % string so determineDrivingInputs still works. See the class header.
            %
            % TODO(stream-D): detect lane structure and set PlannerMode to STRUCTURED where
            % it exists. "Our planner knows when it isn't needed." AGENTS.md section 3 S8.
            tracks          = obj.localTracks(tNow);
            obj.LastTracks  = tracks;
            [pos, vel, yaw] = obj.egoState();
            obj.Roles       = sih.planner.assignRoles(pos, vel, yaw, tracks, ...
                                                      'dMin_m', obj.DMin_m);

            obj.MinBarrier = obj.minBarrierFromRoles();

            if obj.MinBarrier < 0                % NaN < 0 is false, which is what we want
                obj.PlannerMode = uint8(2);      % EMERGENCY, barrier violated
            else
                obj.PlannerMode = uint8(1);      % UNSTRUCTURED, the normal case
            end

            mode = determineDrivingMode@DrivingStrategy(obj, tNow);
        end

        function inputs = determineDrivingInputs(obj, tNow)
            % TODO(stream-D): call sih.planner.chooseVelocity here once Person B's chart is
            % ready to own Signal, Gear, Committed and MirrorsFolded. Wiring it in now would
            % put the WHAT and the WHEN in the same place, which CONTRACT-AB.md splits on
            % purpose. Until then, defer to the base class so the simulation runs end to end.
            inputs = determineDrivingInputs@DrivingStrategy(obj, tNow);
        end
    end

    methods (Access = protected)
        % These two MUST stay protected. DrivingStrategy declares them inside a
        % methods (Access = protected) block, and MATLAB refuses to load a subclass that
        % changes the access of an override:
        %   MATLAB:class:methodOverrideAccess - "uses different access permissions than its
        %   superclass 'DrivingStrategy'. Set 'initializeUDStates' access to 'protected'."

        function initializeUDStates(obj, t) %#ok<INUSD>
            obj.Roles       = struct('TrackID',{},'Role',{},'Beta',{},'Lambda',{},'TCPA',{});
            obj.PlannerMode = uint8(1);
            obj.MinBarrier  = NaN;
            obj.LastTracks  = [];
            obj.UDStates    = NaN;    % width must stay constant - addData writes UDStates(end+1,:)
        end

        function updateUDStates(obj, t) %#ok<INUSD>
            % h = lambda - beta is already computed inside velocityObstacle. Do not recompute.
            %
            % Log it through the base class's UDStates mechanism, NOT by appending to
            % obj.Data directly. move() calls updateUDStates() and then addData(), and
            % addData already appends to Data.Time, Station, Speed, Position, Yaw and
            % UDStates. Writing Data.Time here too gave it two entries per step while every
            % other array got one, so h could not be plotted against time at all - and
            % addData's own guard still passed, so it failed silently.
            obj.MinBarrier = obj.minBarrierFromRoles();
            obj.UDStates   = obj.MinBarrier;
        end

        function h = minBarrierFromRoles(obj)
            % Smallest h across every agent this step. NaN when there are no agents.
            if isempty(obj.Roles)
                h = NaN;
            else
                h = min([obj.Roles.Lambda] - [obj.Roles.Beta]);
            end
        end

        function [pos, vel, yaw] = egoState(obj)
            % Scenario (world) frame - see the FRAME note in the class header.
            p = obj.Position; v = obj.Velocity; f = obj.ForwardVector;
            pos = [p(1) p(2)];
            vel = [v(1) v(2)];
            yaw = atan2(f(2), f(1));
        end

        function tracks = localTracks(obj, tNow) %#ok<INUSD>
            % Perception hook. getVehiclesInSegment() is how a DrivingStrategy sees others.
            % Stream B replaces this with a real TrackList from the lidar tracker (S1).
            proto = struct('TrackID',uint32(0),'ClassID',uint8(0),'Position',[0 0 0], ...
                           'Velocity',[0 0 0],'Extent',[0 0 0],'Yaw',0, ...
                           'Existence',0,'Age',uint32(0));

            others = obj.getVehiclesInSegment();

            % S1 guarantee 2: the list NEVER contains the ego. getVehiclesInSegment returns
            % Node.Vehicles, which includes us - the base class's own getLeader proves it
            % (selfIdx = find(drivers == obj)). Left in, the ego appears as a track at range
            % 0, velocityObstacle takes its d <= dMin branch, and h is pinned at -pi/2 on
            % EVERY step of EVERY run: permanent EMERGENCY and a safety log that is wrong
            % 100% of the time, in the direction that reads as a violation.
            if ~isempty(others)
                others(arrayfun(@(a) isequal(a.MotionStrategy, obj), others)) = [];
            end

            if isempty(others)
                tracks = proto([]);
                return
            end

            tracks = repmat(proto, numel(others), 1);
            for k = 1:numel(others)
                a = others(k);
                tracks(k).TrackID   = uint32(a.ActorID);
                % ClassID stays 0 (unknown) ON PURPOSE. a.ClassID is the drivingScenario
                % numbering (0-6), NOT our S5 numbering (0-15), and sih.util.toSimClassID is
                % lossy and one-way - sixteen of ours fold into seven of theirs, so it cannot
                % be inverted. Copying it straight across would silently turn a scenario
                % Bicycle (sim 3) into an S5 bus, and a Pedestrian (sim 4) into an
                % auto-rickshaw. Stream B supplies the real S5 ClassID keyed by ActorID.
                tracks(k).ClassID   = uint8(0);
                tracks(k).Position  = a.Position;
                tracks(k).Velocity  = a.Velocity;
                tracks(k).Extent    = [a.Length a.Width a.Height];
                tracks(k).Yaw       = deg2rad(a.Yaw);
                tracks(k).Existence = 1.0;
                tracks(k).Age       = uint32(1);
            end
            [~, i] = sort([tracks.TrackID]);     % S1 rule 1: sorted by TrackID
            tracks = tracks(i);
        end
    end
end
