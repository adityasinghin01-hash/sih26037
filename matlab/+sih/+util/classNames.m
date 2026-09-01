function [names, ids] = classNames(subset)
%CLASSNAMES  The S5 class list, in one place, so no two files disagree.
%
%   AGENTS.md section 3, S5 fixes ClassID 0-15 and says NEVER RENUMBER. Every model that
%   predicts a class must use this order, because Stream D reads S2 features 12-27 as a
%   one-hot in exactly this order. A detector trained with its own class ordering will
%   produce a feature vector the planner silently misreads.
%
%   [names, ids] = sih.util.classNames()            all 16
%   [names, ids] = sih.util.classNames("detector")  the ones a camera detector can see
%   [names, ids] = sih.util.classNames("lidar")     the ones a lidar detector can see
%
%   OUTPUT
%     names  string array  class names, matching the ClassID order
%     ids    uint8 vector  the ClassID of each entry
%
%   See also sih.models.trainSpotter, sih.models.trainLidarDetector

arguments
    subset (1,1) string {mustBeMember(subset, ["all", "detector", "lidar"])} = "all"
end

all_names = ["unknown", "car", "truck", "bus", "auto-rickshaw", "motorbike", "scooter", ...
             "van", "pedestrian", "bicycle", "cow", "dog", "pushcart", ...
             "animal-drawn cart", "tractor", "static obstacle"];
all_ids = uint8(0:15);

switch subset
    case "all"
        keep = true(1, 16);
    case "detector"
        % Drop 0 (unknown) - you cannot label a training box "unknown" and learn anything.
        % Everything else is visible in a dashcam frame.
        keep = all_ids > 0;
    case "lidar"
        % A lidar detector needs physical extent. Class 15 (static obstacle) is a catch-all
        % with no consistent shape, so it is excluded rather than taught as one object.
        keep = all_ids > 0 & all_ids < 15;
end

names = all_names(keep);
ids   = all_ids(keep);
end
