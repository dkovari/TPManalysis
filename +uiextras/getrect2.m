function rect = getrect2(varargin)
% GETRECT2 Select rectangle with the mouse
%   This is a modified version of the built-in GETRECT function included
%   with MATLAB.
%   
% Syntax:
%   getrect2()
%   getrect2(defaultRect)
%   getrect2(fixedPosition)
%   getrect2(defaultRect,fixedPosition)
%   getrect2(__,Name,Value)
%   getrect2(hAx,__) or getrect2(hFig,__)
%   RECT = getrect2(__)
%
%   Without any arguments, the function waits for the user to select 
%   a rectangle in the current axes using the mouse.  Use the mouse to 
%   click and drag the desired rectangle.
%   RECT is a four-element vector with the form [xmin ymin width height].


%% Parse inputs
GETRECT_AX = [];

%if not using name-pair syntax, first argument will by 
if nargin > 0 && isscalar(varargin{1}) && ishghandle(varargin{1})
    GETRECT_AX = varargin{1};
    varargin(1) = []; %remove first element and process rest of varargin normally
end

fixedPosition = [];
defaultRect = [];

if numel(varargin)>0 && isnumeric(varargin{1}) && numel(varargin{1}) == 4
    defaultRect = varargin{1};
    varargin(1) = [];
end
if numel(varargin)>0 && isnumeric(varargin{1})
    if numel(varargin{1}) ~= 2
        error('Specifying fixed position must have numel==2');
    end
    fixedPosition = varargin{1};
    varargin(1) = [];
end

%Use input parser to process name-value pairs
p = inputParser;
p.CaseSensitive = false;
addParameter(p,'defaultRect',[],@(x) isempty(x) || isnumeric(x)&&numel(x)==4);
addParameter(p,'FixedPosition',[],@(x) isempty(x) || isnumeric(x)&&numel(x)==2);
addParameter(p,'LineStyle',':',@(x) ischar(x)&&any(strcmpi(x,{'-','--',':','-.','none'})));
addParameter(p,'LineWidth',0.5,@(x) isnumeric(x)&&isscalar(x)&&x>=0);
addParameter(p,'Color','k',@(x) isnumeric(x)&&numel(x)==3&&all(x<=1 & x>=0) ||...
                                ischar(x)&&any(strcmpi(x,...
                                    {'y','yellow',...
                                    'm','magenta',...
                                    'c','cyan',...
                                    'r','red',...
                                    'g','green',...
                                    'b','blue',...
                                    'w','white',...
                                    'k','black'})));
addParameter(p,'Marker','none',@(x) ischar(x)&&any(strcmpi(x,{'+','o','*','.','x','s','square','d','diamond','^','v','>','<','p','pentagram','h','hexagram','none'})));
addParameter(p,'MarkerEdgeColor','auto',@(x) isnumeric(x)&&numel(x)==3&&all(x<=1 & x>=0) ||...
                                ischar(x)&&any(strcmpi(x,...
                                    {'y','yellow',...
                                    'm','magenta',...
                                    'c','cyan',...
                                    'r','red',...
                                    'g','green',...
                                    'b','blue',...
                                    'w','white',...
                                    'k','black',...
                                    'none','auto'})));
addParameter(p,'MarkerFaceColor','auto',@(x) isnumeric(x)&&numel(x)==3&&all(x<=1 & x>=0) ||...
                                ischar(x)&&any(strcmpi(x,...
                                    {'y','yellow',...
                                    'm','magenta',...
                                    'c','cyan',...
                                    'r','red',...
                                    'g','green',...
                                    'b','blue',...
                                    'w','white',...
                                    'k','black',...
                                    'none','auto'})));
addParameter(p,'MarkerSize',6,@(x) isnumeric(x)&&isscalar(x)&&x>=0);

parse(p,varargin{:});

if isempty(defaultRect)
    defaultRect = p.Results.defaultRect;
end
if isempty(fixedPosition)
    fixedPosition = p.Results.FixedPosition;
end


%make sure GETRECT is an axes handle, if figure then find the axes
if ~isempty(GETRECT_AX) && ishghandle(GETRECT_AX)
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
else %user has not set an axes yet, use GCA
    GETRECT_AX = gca;
    GETRECT_FIG = ancestor(GETRECT_AX, 'figure');
end


%% Handle defaultRect
%if user specified default rect but not a fixed corner use the corner
%furthest away from the cursor as the fixed corner
if ~isempty(defaultRect) && isempty(fixedPosition)
    XY = [defaultRect(1),defaultRect(2);...
          defaultRect(1),defaultRect(2)+defaultRect(4);...
          defaultRect(1)+defaultRect(3),defaultRect(2)+defaultRect(4);...
          defaultRect(1)+defaultRect(3),defaultRect(2)];
    cpt = get(GETRECT_AX, 'CurrentPoint');
    [~,r] = min( (XY(:,1)-cpt(1,1)).^2 + (XY(:,2)-cpt(1,2)).^2);
    %mod(r+1,4)+1
    fixedPosition = XY(mod(r+1,4)+1,:);
end

%% Setup for rectangle creation
% Remember initial figure state
state = uisuspend(GETRECT_FIG);

% Set up initial callbacks for initial stage
set(GETRECT_FIG, ...
    'Pointer', 'crosshair', ...
    'WindowKeyPressFcn',@HitKey);

% Set axes limit modes to manual, so that the presence of lines used to
% draw the rectangles doesn't change the axes limits.
original_modes = get(GETRECT_AX, {'XLimMode', 'YLimMode', 'ZLimMode'});
set(GETRECT_AX,'XLimMode','manual', ...
               'YLimMode','manual', ...
               'ZLimMode','manual');
           
% Initialize the lines to be used for the drag
GETRECT_H1 = line('Parent', GETRECT_AX, ...
                  'XData', [0 0 0 0 0], ...
                  'YData', [0 0 0 0 0], ...
                  'Visible', 'off', ...
                  'Clipping', 'off', ...
                  'Color', p.Results.Color, ...
                  'LineStyle', p.Results.LineStyle,...
                  'LineWidth',p.Results.LineWidth,...
                  'Marker',p.Results.Marker,...
                  'MarkerEdgeColor',p.Results.MarkerEdgeColor,...
                  'MarkerFaceColor',p.Results.MarkerFaceColor,...
                  'MarkerSize',p.Results.MarkerSize);
%% Callback Functions
    function HitKey(~,evt)
        if strcmpi(evt.Key,'escape')
            rect = defaultRect;
            set(GETRECT_H1, 'UserData', 'Completed');
        end
    end
    function MouseDown(~,~)
        pt = get(GETRECT_AX, 'CurrentPoint');
        fixedPosition = pt(1,1:2);
        set(GETRECT_FIG,'WindowButtonMotionFcn',@MouseMotion);
        set(GETRECT_FIG,'WindowButtonUpFcn',@MouseUp);
        set(GETRECT_FIG,'WindowButtonDownFcn',[]);
        set(GETRECT_H1,'Visible','on',...
                'XData',fixedPosition(1),...
                'YData',fixedPosition(2));
    end
    function MouseUp(~,~)
        pt = get(GETRECT_AX, 'CurrentPoint');
        rect = [min(fixedPosition(1),pt(1,1)), min(fixedPosition(2),pt(1,2)),abs(pt(1,1)-fixedPosition(1)),abs(pt(1,2)-fixedPosition(2))];
        if rect(3)~=0 && rect(4)~=0
            set(GETRECT_H1, 'UserData', 'Completed');
        end
    end
    function MouseMotion(~,~)
        pt = get(GETRECT_AX, 'CurrentPoint');
        set(GETRECT_H1,'XData',[fixedPosition(1),fixedPosition(1)  ,pt(1,1)    ,pt(1,1)            ,fixedPosition(1)],...
            'YData',[fixedPosition(2),pt(1,2)           ,pt(1,2)    ,fixedPosition(2)   ,fixedPosition(2)]);
    end

if isempty(fixedPosition)
    set(GETRECT_FIG,'WindowButtonDownFcn',@MouseDown);
else
    set(GETRECT_FIG,'WindowButtonMotionFcn',@MouseMotion);
    set(GETRECT_FIG,'WindowButtonUpFcn',@MouseUp);
    set(GETRECT_FIG,'WindowButtonDownFcn',[]);
    pt = get(GETRECT_AX, 'CurrentPoint');
    set(GETRECT_H1,'Visible','on','XData',[fixedPosition(1),fixedPosition(1)  ,pt(1,1)    ,pt(1,1)            ,fixedPosition(1)],...
            'YData',[fixedPosition(2),pt(1,2)           ,pt(1,2)    ,fixedPosition(2)   ,fixedPosition(2)]);
end

%% Wait for presses, and process
rect = defaultRect;
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

end