function rect = dragrect2(rect,varargin)

%% Parse Inputs

p=inputParser;
p.CaseSensitive = false;
p.KeepUnmatched = true;

addParameter(p,'Parent',[]);

parse(p,varargin{:});
if isempty(p.Results.Parent)
    GETRECT_AX = gca;
else
    GETRECT_AX = p.Results.Parent;
end
switch get(GETRECT_AX, 'Type')
    case 'figure' %first arg was figure handle
        GETRECT_FIG = GETRECT_AX;
        GETRECT_AX = get(GETRECT_FIG, 'CurrentAxes');
        if isempty(GETRECT_AX)
            GETRECT_AX = axes('Parent', GETRECT_FIG);
        end
    case 'axes'
       GETRECT_FIG = ancestor(GETRECT_AX, 'figure');
    otherwise
        error('parent handle must be an axes or a figure');
end

%%
orig_rect = rect;

state = uisuspend(GETRECT_FIG);

% Set axes limit modes to manual, so that the presence of lines used to
% draw the rectangles doesn't change the axes limits.
original_modes = get(GETRECT_AX, {'XLimMode', 'YLimMode', 'ZLimMode'});
set(GETRECT_AX,'XLimMode','manual', ...
               'YLimMode','manual', ...
               'ZLimMode','manual');


%% Create moving rectangle
GETRECT_H1 = line('Parent', GETRECT_AX, ...
                  'XData', [rect(1),rect(1),        rect(1)+rect(3),rect(1)+rect(3),rect(1)], ...
                  'YData', [rect(2),rect(2)+rect(4),rect(2)+rect(4),rect(2),        rect(2)], ...
                  'Visible', 'on', ...
                  'Clipping', 'off', ...
                  p.Unmatched);
              
% Set up initial callbacks for initial stage
set(GETRECT_FIG,...
    'WindowKeyPressFcn',@HitKey,...
    'WindowButtonMotionFcn',@MouseMotion,...
    'WindowButtonUpFcn',@MouseUp);

%% initial point
orig_pt = get(GETRECT_AX, 'CurrentPoint');

%% wait for completed
waitfor(GETRECT_H1, 'UserData', 'Completed');

%% Cleanup
% Delete the animation objects
try
    delete(GETRECT_H1);
catch
end
% Restore the figure state
try
   uirestore(state);
catch
end
%restore axes state
try
   set(GETRECT_AX, {'XLimMode','YLimMode','ZLimMode'}, original_modes);
catch
end

%% Callback Functions
    function HitKey(~,evt)
        if strcmpi(evt.Key,'escape')
            rect = orig_rect;
            set(GETRECT_H1, 'UserData', 'Completed');
        end
    end
    function MouseMotion(~,~)
        pt = get(GETRECT_AX, 'CurrentPoint');
        
        rect(1:2) = orig_rect(1:2)+[pt(1,1)-orig_pt(1,1),pt(1,2)-orig_pt(1,2)];
        
        set(GETRECT_H1,'XData',[rect(1),rect(1),        rect(1)+rect(3),rect(1)+rect(3),rect(1)],...
                       'YData',[rect(2),rect(2)+rect(4),rect(2)+rect(4),rect(2),        rect(2)]);
    end
    function MouseUp(~,~)
        set(GETRECT_H1, 'UserData', 'Completed');
    end
end
