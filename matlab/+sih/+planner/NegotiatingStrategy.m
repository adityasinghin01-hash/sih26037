classdef NegotiatingStrategy < DrivingStrategy
%NEGOTIATINGSTRATEGY  A vehicle that negotiates instead of waiting for permission.
%
%   Subclasses OpenTrafficLab's DrivingStrategy and removes the one thing an Indian
%   junction does not have: a central authority.
%
%   WHAT THE BASE CLASS DOES THAT WE REPLACE
%     DrivingStrategy calls getNextNodeState(); the Node answers from its TrafficController's
%     IsOpen flag; the vehicle obeys. That is a signal. We delete the query and decide from
%     geometry instead. See docs/OPENTRAFFICLAB.md.
%
%   OVERRIDDEN
%     determineDrivingMode    - mode from lane structure and role
%     determineDrivingInputs  - command from the COLREGs role and the velocity obstacle
%     initializeUDStates      - allocate role storage
%     updateUDStates          - log the barrier every step (our safety evidence)
%
%   NOT TOUCHED
%     move()          - the base class integration loop
%     carFollowing()  - Gipps/IDM is a perfectly good longitudinal model
%
%   See docs/INTERFACES.md S4 (Role, EgoCommand), S7 (role codes), S8 (planner mode).

    properties
        Roles       = struct('TrackID',{},'Role',{},'Beta',{},'Lambda',{},'TCPA',{})
        PlannerMode uint8  = 1      % 0 STRUCTURED, 1 UNSTRUCTURED, 2 EMERGENCY
        MinBarrier  double = Inf    % min h = lambda - beta this step. h < 0 is a violation
        DMin_m      double = 2.5    % minimum separation for the velocity obstacle
        YieldProb                   % from the ONNX predictor; empty until Stream C wires it
    end

    methods
        function obj = NegotiatingStrategy(egoActor, varargin)
            obj@DrivingStrategy(egoActor, varargin{:});
            obj.StaticLaneKeeping = false;   % an unmarked road has no lane to keep
        end

        function initializeUDStates(obj, t) %#ok<INUSD>
            obj.Roles       = struct('TrackID',{},'Role',{},'Beta',{},'Lambda',{},'TCPA',{});
            obj.PlannerMode = uint8(1);
            obj.MinBarrier  = Inf;
        end

        function updateUDStates(obj, t)
            % h = lambda - beta is already computed inside velocityObstacle. Do not recompute.
            if ~isempty(obj.Roles)
                obj.MinBarrier = min([obj.Roles.Lambda] - [obj.Roles.Beta]);
            else
                obj.MinBarrier = Inf;
            end
            if obj.StoreData
                obj.Data.Time(end+1)       = t;
                obj.Data.MinBarrier(end+1) = obj.MinBarrier;
            end
        end

        function mode = determineDrivingMode(obj, tNow)
            % TODO(stream-D): detect lane structure and return STRUCTURED where it exists.
            % "Our planner knows when it isn't needed." docs/INTERFACES.md S8.
            tracks          = obj.localTracks(tNow);
            [pos, vel, yaw] = obj.egoState();
            obj.Roles       = sih.planner.assignRoles(pos, vel, yaw, tracks, ...
                                                      'dMin_m', obj.DMin_m);

            if ~isempty(obj.Roles) && min([obj.Roles.Lambda] - [obj.Roles.Beta]) < 0
                obj.PlannerMode = uint8(2);      % EMERGENCY, barrier violated
            else
                obj.PlannerMode = uint8(1);      % UNSTRUCTURED, the normal case
            end
            mode = obj.PlannerMode;
        end

        function inputs = determineDrivingInputs(obj, tNow)
            % TODO(stream-D): map roles to a command.
            %   GIVE_WAY  -> one early, substantial manoeuvre. Not creeping (Rule 8).
            %   STAND_ON  -> hold course and speed. Do nothing. This is the safety argument.
            %   HEAD_ON   -> both alter to the same side.
            % Until then, defer to the base class so the simulation still runs end to end.
            inputs = determineDrivingInputs@DrivingStrategy(obj, tNow);
        end
    end

    methods (Access = protected)
        function [pos, vel, yaw] = egoState(obj)
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
            if isempty(others)
                tracks = proto([]);
                return
            end

            tracks = repmat(proto, numel(others), 1);
            for k = 1:numel(others)
                a = others(k);
                tracks(k).TrackID   = uint32(a.ActorID);
                tracks(k).ClassID   = uint8(a.ClassID);
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
