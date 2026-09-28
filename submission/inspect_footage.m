%INSPECT_FOOTAGE Build a visual contact sheet for the user-supplied clips.
repoRoot = fileparts(fileparts(mfilename('fullpath')));
sourceDir = 'C:\Users\admin\Downloads\sih - videos\fin';
files = dir(fullfile(sourceDir, 'drive_*.mp4'));
[~,order] = sort({files.name});
files = files(order);

fig = figure('Visible','off','Color','k','Position',[20 20 1500 900]);
layout = tiledlayout(fig,numel(files),3,'Padding','compact','TileSpacing','compact');
title(layout,'User-supplied camera footage inspection','Color','w','FontSize',16);
for i = 1:numel(files)
    video = VideoReader(fullfile(files(i).folder,files(i).name));
    fprintf('%s | %.3f s | %.3f fps | %dx%d\n',files(i).name,video.Duration, ...
        video.FrameRate,video.Width,video.Height);
    fractions = [0.05 0.50 0.95];
    for j = 1:3
        video.CurrentTime = min(video.Duration-1/video.FrameRate, ...
            max(0,fractions(j)*video.Duration));
        frame = readFrame(video);
        ax = nexttile(layout);
        image(ax,frame);
        axis(ax,'image','off');
        title(ax,sprintf('%s  ·  %.1f s',files(i).name,video.CurrentTime), ...
            'Color','w','Interpreter','none','FontSize',9);
    end
end
outputFile = fullfile(repoRoot,'submission','footage_contact_sheet.png');
exportgraphics(fig,outputFile,'Resolution',120,'BackgroundColor','black');
close(fig);
fprintf('wrote %s\n',outputFile);
