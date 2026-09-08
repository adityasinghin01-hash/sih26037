classdef scene < handle
%SCENE  The renderer. One lit 3-D axes plus a HUD strip, drawn fast and headless.
%
%   WHY THIS EXISTS RATHER THAN plot(scenario) OR plotSim3d
%     plotSim3d (Unreal) DOES NOT RUN ON macOS - verified, it throws
%     "Co-simulation with Unreal Engine is not supported on this operating system."
%     plot(scenario) gives a flat plan view, which is a diagram, not a demo.
%   So the scene is drawn from patches. MEASURED: 0.09-0.33 s per composite 1280x720
%   frame, i.e. a 62 s film in 2.5-8 minutes, which means the look can be ITERATED.
%   For contrast, one frame of the Blender sky alone took over 760 s.
%
%   THE TRAPS THIS CLASS ENCODES (REF-17 s4)
%     - daspect([1 1 1]) IS MANDATORY. Without it the Z axis stretches to fill the
%       axis box and every 4 m house renders as a tower. Highest-value line here.
%     - The figure background shows through as "sky" unless a sky is actually drawn.
%     - Two lights, never one: a warm sun on the scene's real solar vector plus a cool
%       sky fill. One light gives black shadow sides and reads as a diagram.
%     - Clipping off, or geometry at the axis limits gets sliced.
%
%   Usage:
%       S = sc.scene('Sun',[33.11 246.87]);      % S0 s2: 25 Sep 15:30 IST
%       S.ground(xlim,ylim); S.tarmac(poly); S.mesh(m,pose,colour);
%       S.chase(egoPose); S.hud(...); S.grab();

    properties
        Fig; Ax; HudAx = gobjects(0)
        SunVec  (1,3) double
        SunElAz (1,2) double = [33.11 246.87]
        Width   (1,1) double = 1280
        Height  (1,1) double = 720
        HudFrac (1,1) double = 0.26     % bottom fraction of the frame given to the HUD
        Writer                          % VideoWriter, when filming
        FrameSize                       % the size every frame must match
    end

    methods
        function o = scene(opts)
            arguments
                opts.Sun    (1,2) double = [33.11 246.87]
                opts.Width  (1,1) double = 1280
                opts.Height (1,1) double = 720
                opts.Hud    (1,1) logical = true
                opts.Visible(1,1) logical = false   % true = a real, on-screen,
                                                    % rotatable/zoomable window -
                                                    % for looking at the world
                                                    % interactively, not filming
                % REF-13 s1, MEASURED off Aditya's own 43 photographs, plains set:
                % zenith RGB 146.4/171.5/191.4 (sat 23.5 %), horizon 137.5/160.2/172.6
                % (sat 20.3 %), hue ~204 deg. My guessed sky was 44.7 % at the zenith and
                % 8.4 % at the horizon - twice as saturated above, half as much below.
                % "The gradient is the thing, not the average."
                opts.SkyTop    (1,3) double = [0.574 0.673 0.751]
                opts.SkyHorizon(1,3) double = [0.539 0.628 0.677]
            end
            o.SunElAz = opts.Sun; o.Width = opts.Width; o.Height = opts.Height;
            el = opts.Sun(1); az = opts.Sun(2);
            o.SunVec = [cosd(el)*sind(az), cosd(el)*cosd(az), sind(el)];
            if ~opts.Hud, o.HudFrac = 0; end

            vis = "off"; if opts.Visible, vis = "on"; end
            o.Fig = figure('Visible',vis,'Position',[0 0 o.Width o.Height], ...
                           'Color',[0.09 0.10 0.12],'GraphicsSmoothing','on');
            o.Ax = axes(o.Fig,'Position',[0 o.HudFrac 1 1-o.HudFrac]);
            hold(o.Ax,'on'); axis(o.Ax,'off');
            daspect(o.Ax,[1 1 1]);                      % THE MANDATORY LINE
            set(o.Ax,'Projection','perspective','CameraUpVector',[0 0 1],'Clipping','off');
            % mouse-drag to orbit, scroll to zoom - wrapped in try/catch because
            % `-batch` has no real display even with Visible=true, and rotate3d
            % throws there; a real interactive MATLAB session has one and works.
            if opts.Visible, try rotate3d(o.Ax,'on'); catch, end, end

            % two lights, warm sun + cool sky fill
            light(o.Ax,'Style','infinite','Position',o.SunVec,'Color',[1.00 0.96 0.87]);
            light(o.Ax,'Style','infinite','Position',[-0.3 0.4 0.85],'Color',[0.30 0.36 0.45]);
            % TRAP: `material dull` only touches objects that ALREADY EXIST. Called here
            % in the constructor there is no geometry yet, so it does nothing at all, and
            % every surface created later silently gets MATLAB's default
            % SpecularStrength of 0.9. The ground rendered as one enormous specular
            % highlight - a smooth blue-green gradient across the whole frame that looked
            % like broken haze and was not. REF-11 s3 states the physical rule directly:
            % "Roughness UP, Specular DOWN - grass should not reflect much."
            % Every lit surface below therefore sets SpecularStrength EXPLICITLY.
            material(o.Ax,'dull');
            o.SkyTopC = opts.SkyTop; o.SkyHorC = opts.SkyHorizon;
        end

        % ---------------------------------------------------------------- sky
        function sky(o, atX, yspan, zspan)
            %SKY  A banded backdrop at x = atX. The figure colour is NOT the sky.
            nb = 7;
            for b = 1:nb
                t0=(b-1)/nb; t1=b/nb;
                z0=zspan(1)+t0*(zspan(2)-zspan(1)); z1=zspan(1)+t1*(zspan(2)-zspan(1));
                c = o.SkyHorC*(1-t0) + o.SkyTopC*t0;
                patch(o.Ax,'XData',[atX atX atX atX],'YData',[yspan(1) yspan(2) yspan(2) yspan(1)], ...
                    'ZData',[z0 z0 z1 z1],'FaceColor',c,'EdgeColor','none','FaceLighting','none');
            end
        end

        % ---------------------------------------------------------------- sky dome
        function skydome(o, centre, R)
            %SKYDOME  A graded hemisphere. Use this, NOT sky().
            %
            %   TRAP: sky() paints a flat backdrop at constant x, so it only works when
            %   the camera looks along +-x. The S1 road runs at 133 deg and the camera
            %   turns with it, so a flat backdrop slides out of frame and the figure
            %   colour shows through as a black void. A dome is correct from any bearing.
            if nargin<3, R = 900; end
            [sx,sy,sz] = sphere(28);
            sz = max(sz, -0.02);                       % hemisphere, just below the horizon
            fv = surf2patch(sx,sy,sz,'triangles');
            V  = fv.vertices .* R + [centre(1) centre(2) 0];
            t  = max(0, min(1, (fv.vertices(:,3)*1.9)));      % 0 at horizon, 1 overhead
            C  = o.SkyHorC.*(1-t) + o.SkyTopC.*t;
            patch(o.Ax,'Vertices',V,'Faces',fv.faces,'FaceVertexCData',C, ...
                  'FaceColor','interp','EdgeColor','none','FaceLighting','none');
        end

        function horizon(o, centre, R, col, h)
            %HORIZON  A hazed band at distance R so the ground does not just stop.
            %   Without it the far ground meets the sky in a hard line and the scene
            %   reads as a tabletop. A distant treeline is one cylinder.
            if nargin<5, h = 14; end
            th = linspace(0,2*pi,73)';
            X = centre(1)+R*cos(th); Y = centre(2)+R*sin(th);
            patch(o.Ax,'XData',[X; flipud(X)],'YData',[Y; flipud(Y)], ...
                  'ZData',[zeros(size(X)); h*ones(size(X))], ...
                  'FaceColor',col,'EdgeColor','none','FaceLighting','none');
        end

        function farGround(o, centre, Rin, Rout, col)
            %FARGROUND  A hazed ANNULUS beyond the detailed ground, so there is no void.
            %
            %   TRAP, found by looking - and it is REF-17 trap 7 inverted. The first
            %   version was a DISC at z = -0.34 covering the whole scene, including the
            %   ground under the camera. ground() bases its relief at -0.25 with +-0.126
            %   of swing, so its dips reach -0.376 - BELOW the disc - and the pale far
            %   colour punched up through the forest floor as a bright plate ten metres
            %   from the camera. An annulus starting where the detailed ground ends
            %   cannot overlap it at all, which is the fix rather than a z-tweak.
            th = linspace(0,2*pi,97)';
            c = cos(th); sn = sin(th);
            X = [centre(1)+Rout*c; flipud(centre(1)+Rin*c)];
            Y = [centre(2)+Rout*sn; flipud(centre(2)+Rin*sn)];
            patch(o.Ax,'XData',X,'YData',Y,'ZData',-0.29*ones(size(X)), ...
                  'FaceColor',col,'EdgeColor','none', ...
                  'FaceLighting','gouraud','AmbientStrength',0.44,'DiffuseStrength',0.86, ...
                  'SpecularStrength',0.02,'VertexNormals',repmat([0 0 1],numel(X),1));
        end

        % ---------------------------------------------------------------- ground
        function ground(o, xs, ys, col, opts)
            arguments
                o; xs (1,2) double; ys (1,2) double; col (1,3) double = [0.40 0.44 0.26]
                opts.Step (1,1) double = 6
                opts.Relief (1,1) double = 0.06      % NEVER FLAT ANYWHERE (S0 s3)
                opts.Base (1,1) double = -0.25       % MUST sit below every road surface
                opts.Haze (1,3) double = [NaN NaN NaN]   % blend toward this with distance
                opts.HazeFrom  (1,2) double = [0 0]
                opts.HazeStart (1,1) double = 30
                opts.HazeFull  (1,1) double = 260
                opts.HazeMax   (1,1) double = 0.75
                opts.Hollow   (1,3) double = [NaN NaN NaN]  % colour in the dips
                opts.TextureFn = []      % @(GX,GY) -> multiplier, same size as GX; []
                                         % for none. A FUNCTION, not a precomputed
                                         % matrix, so the caller never has to guess
                                         % this method's own internal grid shape -
                                         % see sc.floorTexture, Phase 5's forest floor.
            end
            % REF-04 s10, the two-tone forest floor: "dark, near-black humus in hollows,
            % gullies and under closed canopy - light pebbly tan on ridges and sunlit
            % slopes. The boundary is a noise-masked gradient, never a line." One flat
            % colour for a whole forest floor is the thing that rule exists to forbid.
            % TRAP, found by looking: relief of +-0.11 m against tarmac at z = 0.03 makes
            % the GRASS RENDER OVER THE ROAD in patches. The ground is therefore based
            % well below zero and the road layers stack above it. Verified by A/B render.
            [GX,GY] = meshgrid(xs(1):opts.Step:xs(2), ys(1):opts.Step:ys(2));
            GZ = opts.Base + opts.Relief*sin(GX/17) + opts.Relief*0.8*cos(GY/13);
            base = repmat(reshape(col,1,1,3), size(GX,1), size(GX,2));
            if ~any(isnan(opts.Hollow))
                rel = (GZ - opts.Base) / max(opts.Relief*1.8, 1e-9);      % -1 dip .. +1 ridge
                n   = 0.35*sin(GX/5.3 + 1.7) .* cos(GY/4.1 - 0.6);        % masks the boundary
                w   = max(0, min(1, 0.5 - 0.75*(rel + n)));               % 1 in the hollows
                for k = 1:3
                    base(:,:,k) = col(k)*(1-w) + opts.Hollow(k)*w;
                end
            end
            % FINE TEXTURE, APPLIED TO THE LOCAL ALBEDO BEFORE HAZE - haze is a
            % DISTANCE effect on top of what a surface actually is, so the multiplier
            % has to land here, before the blend below, exactly as sc.roadTexture and
            % sc.groundTexture are both applied to a measured base colour before
            % anything else touches it.
            if ~isempty(opts.TextureFn)
                Mtx = opts.TextureFn(GX, GY);
                assert(isequal(size(Mtx), size(GX)), "sc:groundTextureFnSize", ...
                    "TextureFn returned %dx%d for a %dx%d grid", size(Mtx,1), size(Mtx,2), ...
                    size(GX,1), size(GX,2));
                for k = 1:3, base(:,:,k) = base(:,:,k) .* Mtx; end
            end
            if any(isnan(opts.Haze))
                surf(o.Ax,GX,GY,GZ,base,'FaceColor','interp','EdgeColor','none', ...
                     'FaceLighting','gouraud','AmbientStrength',0.44, ...
                     'DiffuseStrength',0.86,'SpecularStrength',0.02);
            else
                % Without this the detailed ground meets the hazed far disc in a hard
                % ring. Haze is a DISTANCE blend, so it has to live in the vertex colours.
                d = hypot(GX-opts.HazeFrom(1), GY-opts.HazeFrom(2));
                f = opts.HazeMax * min(1, max(0, (d-opts.HazeStart) / ...
                                              max(1e-6, opts.HazeFull-opts.HazeStart)));
                C = zeros([size(GX) 3]);
                for k = 1:3, C(:,:,k) = base(:,:,k).*(1-f) + opts.Haze(k)*f; end
                surf(o.Ax,GX,GY,GZ,C,'FaceColor','interp','EdgeColor','none', ...
                     'FaceLighting','gouraud','AmbientStrength',0.44, ...
                     'DiffuseStrength',0.86,'SpecularStrength',0.02);
            end
        end

        % ---------------------------------------------------------------- flat polys
        function h = carpet(o, X, Y, z, C)
            %CARPET  A texture-mapped horizontal surface - a road with a real surface.
            %
            %   `flat` is one patch in one colour, which is why the carriageway
            %   measured LOCAL CONTRAST 5.4 while it filled most of the frame. This
            %   draws the same band as a `surface` carrying an image, and the image
            %   resolution is independent of the grid: verified, a 2x2 grid with a
            %   512-wide texture renders at luminance std 65.4. So the grid can stay
            %   coarse enough to be free and the detail lives in the picture.
            %
            %   Unlit, exactly as `flat` is. The road's grey is measured off dashcam
            %   frames (REF-17 s19h) and lighting it would move a measured number.
            %
            %   z MAY NOW BE A MATRIX matching X,Y, not just a scalar height - added
            %   6 Sep for real pothole relief (sc.s1render), which needs actual Z
            %   depth at specific grid vertices, not a flat plane with a picture on
            %   it. A scalar still broadcasts exactly as before - every existing
            %   caller is unaffected.
            if isscalar(z), Z = z*ones(size(X)); else, Z = z; end
            h = surface(o.Ax, X, Y, Z, C, 'FaceColor','texturemap', ...
                'EdgeColor','none', 'FaceLighting','none');
        end

        function h = flat(o, X, Y, z, col, alpha)
            %FLAT  A horizontal polygon: tarmac, shoulder, marking, island top.
            if nargin<6, alpha=1; end
            h = patch(o.Ax,'XData',X,'YData',Y,'ZData',z*ones(size(X)), ...
                'FaceColor',col,'EdgeColor','none','FaceLighting','none','FaceAlpha',alpha);
        end

        function ribbon(o, centre, width, z, col)
            %RIBBON  A road surface from a centreline, offset both sides.
            n = size(centre,1);
            L = zeros(n,2); R = zeros(n,2);
            for i=1:n
                if i==1,        d = centre(2,:)-centre(1,:);
                elseif i==n,    d = centre(n,:)-centre(n-1,:);
                else,           d = centre(i+1,:)-centre(i-1,:);
                end
                d = d/max(norm(d),1e-9); nrm=[-d(2) d(1)];
                L(i,:) = centre(i,:)+nrm*width/2;  R(i,:) = centre(i,:)-nrm*width/2;
            end
            o.flat([L(:,1); flipud(R(:,1))], [L(:,2); flipud(R(:,2))], z, col);
        end

        % ---------------------------------------------------------------- meshes
        function h = mesh(o, m, pose, col, opts)
            %MESH  Place an extendedObjectMesh at [x y yaw] and light it.
            arguments
                o; m; pose (1,3) double; col double
                opts.Alpha (1,1) double = 1
                opts.Shadow (1,1) logical = true
                opts.Grain  (1,1) double = 0     % per-face tonal noise, see instances()
            end
            % col may be 1x3 (one colour) OR nFaces x 3. Per-face is what lets an actor
            % have dark hooves, a dark muzzle and pale horns - a single colour per actor
            % is the reason the cow had no eyes and read as an uncrafted mould.
            R = [cos(pose(3)) -sin(pose(3)); sin(pose(3)) cos(pose(3))];
            v = m.Vertices;  p = (R*v(:,1:2)')';
            V = [p(:,1)+pose(1), p(:,2)+pose(2), v(:,3)];
            % THE SHADOW HANDLE IS RETURNED, NOT DISCARDED. A caller that deletes the
            % mesh each frame - which every film loop does - was leaving the shadow
            % patch behind: measured at exactly +1 graphics object per frame, so a
            % 1,486-frame film ends with thousands of orphaned patches stacked on the
            % road. Found by counting findobj in a 400-frame instrumented run, not by
            % watching memory, which stayed flat.
            sh = gobjects(0);
            if opts.Shadow, sh = o.shadow(V); end
            if opts.Grain > 0
                % promote a single colour to per-face so the grain has somewhere to go
                if size(col,1) == 1, col = repmat(col, size(m.Faces,1), 1); end
                fc = (V(m.Faces(:,1),:) + V(m.Faces(:,2),:) + V(m.Faces(:,3),:))/3;
                g  = mod(sin(fc(:,1)*12.9898 + fc(:,2)*78.233 + fc(:,3)*37.719) ...
                         * 43758.5453, 1);
                col = min(1, max(0, col .* (1 + opts.Grain*(g - 0.5))));
            end
            if size(col,1) == 1
                % MATLAB's own message for this is "Invalid RGB triplet", which does
                % not say WHICH number or WHERE it came from. Colours here are often
                % computed - a pixel target divided by a lighting factor, say - so the
                % offending value is the whole diagnosis.
                assert(all(col >= 0 & col <= 1), "sc:badColour", ...
                    "colour [%.3f %.3f %.3f] is outside 0-1", col(1), col(2), col(3));
                h = patch(o.Ax,'Vertices',V,'Faces',m.Faces,'FaceColor',col, ...
                    'EdgeColor','none','FaceLighting','gouraud','FaceAlpha',opts.Alpha, ...
                    'DiffuseStrength',0.92,'AmbientStrength',0.36,'SpecularStrength',0.12);
                h = [h sh];
            else
                assert(size(col,1) == size(m.Faces,1), "sc:meshCols", ...
                    "per-face colour has %d rows for %d faces", size(col,1), size(m.Faces,1));
                h = patch(o.Ax,'Vertices',V,'Faces',m.Faces,'FaceVertexCData',col, ...
                    'FaceColor','flat','EdgeColor','none','FaceLighting','gouraud', ...
                    'FaceAlpha',opts.Alpha,'DiffuseStrength',0.92, ...
                    'AmbientStrength',0.36,'SpecularStrength',0.12);
                h = [h sh];
            end
        end

        function h = shadow(o, V)
            %SHADOW  MATLAB casts none, so project the footprint along the sun vector.
            h = max(V(:,3));
            off = -[o.SunVec(1) o.SunVec(2)]/max(o.SunVec(3),0.2) * h*0.55;
            k = convhull(V(:,1), V(:,2));
            h = patch(o.Ax,'XData',V(k,1)+off(1),'YData',V(k,2)+off(2), ...
                'ZData',0.035*ones(numel(k),1),'FaceColor',[0.05 0.06 0.05], ...
                'EdgeColor','none','FaceAlpha',0.28,'FaceLighting','none');
        end

        function h = instances(o, V0, F0, T, cols, opts)
            %INSTANCES  One patch holding MANY copies of one small mesh.
            %
            %   900 trees drawn as 900 patches is 1,800 graphics objects and the render
            %   crawls. Concatenated into two patches - trunks and crowns - it is two.
            %   T is Nx6 [x y z sx sy sz]; cols is Nx3, one colour per copy, which is
            %   what lets distance haze be baked in per instance for free.
            arguments
                o; V0 (:,3) double; F0 (:,3) double; T (:,6) double; cols (:,3) double
                opts.Lighting (1,:) char = 'gouraud'
                opts.Ambient  (1,1) double = 0.40
                opts.Alpha    (1,1) double = 1
                opts.Tip      (1,3) double = [NaN NaN NaN]   % colour at the top of the mesh
                opts.Yaw      (:,1) double = []   % per-instance rotation about z, rad
                opts.Grain    (1,1) double = 0    % per-FACE tonal noise, 0 = off
                opts.Smooth   (1,1) logical = true % interpolate colour across faces
            end
            % GRAIN IS THE ONLY TEXTURE THIS RENDERER CAN HAVE.
            % MATLAB patches take no image maps and no alpha, so every mass here is
            % one flat colour per face and a 12 m crown reads as a poster shape. Real
            % foliage is not one colour: REF-13 s7 measures FOUR greens plus a dead
            % layer inside a single square metre, and REF-06 s3 wants "dark and closed
            % at the base, lighter at the top". Tip does the second; Grain does the
            % first, by perturbing each face's own tone by a deterministic hash of its
            % own centroid. Deterministic in POSITION, so it never crawls between
            % frames of a film - a random() here would boil the whole canopy.
            % It costs nothing: the colour array is per-face already.
            % YAW EXISTS FOR REF-06 s1 CAUSE 4. A crowded tree "elongates along the row
            % and narrows across it" (REF-04 s7), and a row that follows a curving road
            % has a different bearing at every tree - so a non-uniform [sx sy] scale is
            % only correct if the instance can be turned to the local road bearing.
            % Without it every constraint form would be stretched along world x.
            % REF-06 s3: a canopy is "dark and closed at the base, lighter at the top",
            % and REF-11 s3 says the same of a grass blade root-to-tip. One flat colour
            % per instance cannot say that. Tip blends each FACE toward a second colour
            % by its own height within the unit mesh - still flat shading per face, so
            % it costs nothing, but the mass stops reading as a single poster colour.
            n = size(T,1);
            if n==0, h = gobjects(0); return; end
            nv = size(V0,1); nf = size(F0,1);
            useTip = ~any(isnan(opts.Tip));
            if useTip
                fz = mean(reshape(V0(F0,3), nf, 3), 2);      % each face's own height
                z0 = min(V0(:,3));  z1 = max(V0(:,3));
                w  = (fz - z0) / max(z1 - z0, 1e-9);         % 0 at the base, 1 at the top
            end
            useYaw = ~isempty(opts.Yaw);
            if useYaw
                assert(numel(opts.Yaw) == n, "sc:instYaw", ...
                    "Yaw has %d entries for %d instances", numel(opts.Yaw), n);
            end
            V = zeros(n*nv,3); F = zeros(n*nf,3); C = zeros(n*nf,3);
            for i = 1:n
                Vi = V0.*T(i,4:6);
                if useYaw
                    ca = cos(opts.Yaw(i)); sa = sin(opts.Yaw(i));
                    Vi(:,1:2) = [Vi(:,1)*ca - Vi(:,2)*sa, Vi(:,1)*sa + Vi(:,2)*ca];
                end
                V((i-1)*nv+1:i*nv,:) = Vi + T(i,1:3);
                %#ok<*AGROW>
                F((i-1)*nf+1:i*nf,:) = F0 + (i-1)*nv;
                if useTip
                    Ci = (1-w).*cols(i,:) + w.*opts.Tip;
                else
                    Ci = repmat(cols(i,:), nf, 1);
                end
                if opts.Grain > 0
                    % hash each face's own centroid in WORLD space
                    fc = (Vi(F0(:,1),:) + Vi(F0(:,2),:) + Vi(F0(:,3),:))/3 + T(i,1:3);
                    g  = mod(sin(fc(:,1)*12.9898 + fc(:,2)*78.233 + fc(:,3)*37.719) ...
                             * 43758.5453, 1);
                    Ci = Ci .* (1 + opts.Grain*(g - 0.5));
                end
                C((i-1)*nf+1:i*nf,:) = min(1, max(0, Ci));
            end
            % SMOOTH, NOT FACETED - and this one line is most of the "everything
            % looks like blocks" problem. FaceColor 'flat' paints each triangle a
            % single colour, so a 7-segment crown reads as seven visible plates and
            % the eye sees the mesh instead of the mass. VERIFIED by running it:
            % patches cannot take an image texture, but they CAN interpolate colour
            % across a face ('interp'), which costs nothing and dissolves the facets.
            % Per-vertex colours are derived from the per-face ones by scattering each
            % face's colour onto its three vertices and averaging - so Tip and Grain
            % still drive the result, they simply stop being piecewise-constant.
            if opts.Smooth && size(C,1) == size(F,1)
                acc = zeros(size(V,1),3);  cnt = zeros(size(V,1),1);
                for kk = 1:3
                    idx = F(:,kk);
                    acc(:,1) = acc(:,1) + accumarray(idx, C(:,1), [size(V,1) 1]);
                    acc(:,2) = acc(:,2) + accumarray(idx, C(:,2), [size(V,1) 1]);
                    acc(:,3) = acc(:,3) + accumarray(idx, C(:,3), [size(V,1) 1]);
                    cnt      = cnt      + accumarray(idx, 1,      [size(V,1) 1]);
                end
                Cv = acc ./ max(cnt,1);
                h = patch(o.Ax,'Vertices',V,'Faces',F,'FaceVertexCData',Cv, ...
                    'FaceColor','interp','EdgeColor','none','FaceLighting',opts.Lighting, ...
                    'AmbientStrength',opts.Ambient,'DiffuseStrength',0.90, ...
                    'FaceAlpha',opts.Alpha,'SpecularStrength',0.03, ...
                    'BackFaceLighting','unlit');
            else
                h = patch(o.Ax,'Vertices',V,'Faces',F,'FaceVertexCData',C, ...
                    'FaceColor','flat','EdgeColor','none','FaceLighting',opts.Lighting, ...
                    'AmbientStrength',opts.Ambient,'DiffuseStrength',0.90, ...
                    'FaceAlpha',opts.Alpha,'SpecularStrength',0.03, ...
                    'BackFaceLighting','unlit');
            end
        end

        function box(o, c, dims, yaw, col)
            %BOX  A cuboid standing on z = 0, for scenery.
            o.box3(c, dims, 0, yaw, col);
        end

        function box3(o, c, dims, z, yaw, col)
            %BOX3  A cuboid whose BASE sits at z. The version above could only stand
            %   on the ground, which is no use for a stepped plinth - every step after
            %   the first starts on top of the one below it.
            m = translate(scale(extendedObjectMesh('cuboid'), dims), [0 0 dims(3)/2 + z]);
            o.mesh(m, [c(1) c(2) yaw], col, 'Shadow', false);
        end

        function meshAt(o, m, pose, z, col)
            %MESHAT  Place a mesh at [x y yaw] with its own z lifted by z.
            %   For anything standing on something that is not the ground - a cow on a
            %   150 mm island, a figure on a plinth.
            m2 = m;  m2.Vertices(:,3) = m2.Vertices(:,3) + z;
            o.mesh(m2, pose, col);
        end

        function rail(o, p0, p1, z, r, col)
            %RAIL  A horizontal bar between two points - the "rail" of post-and-rail.
            d = [p1(1)-p0(1), p1(2)-p0(2)];
            L = hypot(d(1), d(2));
            if L < 1e-6, return; end
            yaw = atan2(d(2), d(1));
            c   = [(p0(1)+p1(1))/2, (p0(2)+p1(2))/2];
            m = translate(scale(extendedObjectMesh('cuboid'), [L r r]), [0 0 z]);
            o.mesh(m, [c(1) c(2) yaw], col, 'Shadow', false);
        end

        % ---------------------------------------------------------------- annotation
        function dimension(o, y0, y1, atX, z, txt, col, opts)
            %DIMENSION  A measured span drawn FLAT ON THE ROAD, in world coordinates.
            %   This is the single most valuable thing on screen: it shows the planner
            %   MEASURING rather than merely succeeding.
            %
            %   TRAP: centring the label on the span puts it ON TOP of its own line and
            %   both become unreadable. The label is therefore offset ACROSS the span
            %   (toward the camera) and given a dark halo so it survives any background.
            arguments
                o; y0 (1,1) double; y1 (1,1) double; atX (1,1) double
                z (1,1) double; txt (1,1) string; col (1,3) double
                opts.LabelOffset (1,1) double = 2.6      % m toward the camera
            end
            plot3(o.Ax,[atX atX],[y0 y1],[z z],'-','Color',col,'LineWidth',2.4);
            for yy=[y0 y1]
                plot3(o.Ax,[atX-0.7 atX+0.7],[yy yy],[z z],'-','Color',col,'LineWidth',2.4);
            end
            text(o.Ax, atX-opts.LabelOffset, (y0+y1)/2, z+0.05, txt, 'Color',col, ...
                'FontSize',13,'FontWeight','bold','HorizontalAlignment','center', ...
                'BackgroundColor',[0.09 0.10 0.12],'Margin',2);
        end

        function corridor(o, x0, x1, yc, w, col)
            %CORRIDOR  The ego's swept path, dashed, flat on the road.
            plot3(o.Ax,[x0 x1 x1 x0 x0],[yc-w/2 yc-w/2 yc+w/2 yc+w/2 yc-w/2], ...
                  0.06*ones(1,5),'--','Color',col,'LineWidth',1.8);
        end

        % ---------------------------------------------------------------- camera
        function chase(o, pose, opts)
            arguments
                o; pose (1,3) double
                opts.Back (1,1) double = 9.5
                opts.Up   (1,1) double = 5.2
                opts.Ahead(1,1) double = 22
                opts.Fov  (1,1) double = 31
            end
            d = [cos(pose(3)) sin(pose(3))];
            set(o.Ax,'CameraViewAngle',opts.Fov, ...
                'CameraPosition',[pose(1:2)-d*opts.Back, opts.Up], ...
                'CameraTarget',  [pose(1:2)+d*opts.Ahead, 0.6]);
        end

        function look(o, from, at, fov)
            if nargin<4, fov=34; end
            set(o.Ax,'CameraViewAngle',fov,'CameraPosition',from,'CameraTarget',at);
        end

        function limits(o, xs, ys, zs)
            xlim(o.Ax,xs); ylim(o.Ax,ys); zlim(o.Ax,zs);
        end

        % ---------------------------------------------------------------- output
        function startFilm(o, path, fps)
            %STARTFILM  Begin recording. Removes any stale file first.
            %   A run killed mid-write leaves a partial MP4 behind, and VideoWriter then
            %   fails on the very FIRST frame with "Could not write a video frame" -
            %   which reads like a disk or codec fault and is neither.
            if nargin<3, fps=24; end
            if isfile(path)
                try delete(path); catch
                    error("sc:filmLocked", ...
                        "cannot remove the previous %s - is a MATLAB process still holding it?", path);
                end
            end
            o.Writer = VideoWriter(path,'MPEG-4');
            o.Writer.FrameRate=fps; o.Writer.Quality=94; open(o.Writer);
            o.FrameSize = [];
        end
        function grab(o)
            %GRAB  Flush the figure and, if filming, write the frame.
            %
            %   TRAP: this used `drawnow limitrate` unconditionally. limitrate CAPS
            %   updates at about 20 a second and SKIPS the ones that arrive too fast,
            %   so getframe would capture a STALE figure and the film would carry
            %   duplicated frames while the trajectory underneath had moved on. It is
            %   the right call for a live preview and the wrong one for a recording.
            if isempty(o.Writer)
                drawnow limitrate;
            else
                drawnow;                        % every frame, no skipping
                F = getframe(o.Fig);
                % EVERY FRAME MUST BE THE SAME SIZE OR writeVideo REFUSES IT. getframe
                % can come back a pixel or two different on a hidden figure depending on
                % screen scaling, and one odd frame kills a 25-minute render outright.
                if isempty(o.FrameSize)
                    o.FrameSize = size(F.cdata);
                elseif ~isequal(size(F.cdata), o.FrameSize)
                    F.cdata = imresize(F.cdata, o.FrameSize(1:2));
                end
                writeVideo(o.Writer, F);
            end
        end
        function endFilm(o)
            if ~isempty(o.Writer), close(o.Writer); o.Writer=[]; end
        end
        function save(o, path)
            exportgraphics(o.Fig, path, 'Resolution', 110);
        end
        function clearScene(o)
            delete(findobj(o.Ax,'Type','patch')); delete(findobj(o.Ax,'Type','surface'));
            delete(findobj(o.Ax,'Type','line'));  delete(findobj(o.Ax,'Type','text'));
        end
        function close(o)
            o.endFilm(); if isvalid(o.Fig), close(o.Fig); end
        end
    end

    properties (Access=private)
        SkyTopC (1,3) double = [0.574 0.673 0.751]
        SkyHorC (1,3) double = [0.539 0.628 0.677]
    end
end
