function suite = sensorSuite()
%SENSORSUITE  The ego's sensor loadout for Phase 5's realistic-sensing pass.
%
%   AGENTS.md section 2 (settled - do not reopen): "Lidar and radar in the
%   loop; camera offline." So this suite is lidar + radar + the near-field
%   ring (S1 SensorMask bit3) and NOTHING ELSE. No camera row exists here on
%   purpose - sih.perception.simulateSensors has no camera special-case to
%   remove later because there is nothing to remove.
%
%   The numbers below are a first, DISCLOSED pass, not measured off a real
%   sensor datasheet - no such sensor exists on this project, there is no
%   physical vehicle to instrument. They are chosen to be ORDERED correctly
%   relative to each other, which is the part that actually matters for a
%   realistic-sensing claim:
%     - lidar: shorter range, tighter beam, much better precision than radar
%     - radar: longer range, wider beam, worse precision (real radars trade
%       angular resolution for range and see through rain/dust lidar cannot -
%       the "sees further, sees fuzzier" tradeoff is the point being modelled)
%     - the near-field ring: short range, 360 degrees, near-perfect detection -
%       it exists to cover the OTHER two's BEARING blind spot, not just a
%       minimum-range one. Found while validating Phase 8, not assumed: as
%       the ego draws level with a roadside hazard during a real pass, the
%       bearing to it swings toward +-90 deg and leaves BOTH forward cones
%       (lidar +-70, radar +-60) while still 7-12 m away - well past a
%       genuinely "minimum-range" gap. 6 m (was 4) is chosen to cover that
%       measured range, not a round number
%   TUNE HERE, NOWHERE ELSE - every consumer reads this one function.
%
%   suite(k) fields:
%     .Name string   .Bit uint8  (S1 SensorMask: bit0=1 lidar, bit1=2 radar,
%        bit3=8 near-field ring - bit2=4 camera is never assigned)
%     .Range_m .FOV_rad     (full FOV; +-FOV_rad/2 either side of dead ahead)
%     .PdNear .PdFar        (detection probability at range 0 and at Range_m,
%        linear ramp between - a stand-in for occlusion/RCS falloff, since
%        this simulator does not ray-cast; a real occluded-by-another-vehicle
%        miss is NOT modelled, only a range-dependent one - disclosed limit)
%     .RangeNoiseStd_m .BearingNoiseStd_rad

lidar = struct('Name',"lidar", 'Bit',uint8(1), ...
    'Range_m',80, 'FOV_rad',deg2rad(140), ...   % 140 deg - the same forward FOV
    'PdNear',0.98, 'PdFar',0.85, ...            % this project already measured
    'RangeNoiseStd_m',0.05, 'BearingNoiseStd_rad',deg2rad(0.3));   % off a real dashcam

radar = struct('Name',"radar", 'Bit',uint8(2), ...
    'Range_m',150, 'FOV_rad',deg2rad(120), ...
    'PdNear',0.95, 'PdFar',0.80, ...
    'RangeNoiseStd_m',0.30, 'BearingNoiseStd_rad',deg2rad(1.0));

ring = struct('Name',"near_field_ring", 'Bit',uint8(8), ...
    'Range_m',6, 'FOV_rad',deg2rad(360), ...
    'PdNear',0.99, 'PdFar',0.97, ...
    'RangeNoiseStd_m',0.02, 'BearingNoiseStd_rad',deg2rad(2.0));

suite = [lidar radar ring];
end
