function hrect = imrect2(varargin)
%Create Dynamic rectangle on image (similar to imrect() included with
%image processing toolbox but built with the standard rectangle object)
% Input:
%   'Parent',hax - handle to parent axes (default = gca)
%   'Position',[x,y,w,h] - position of rectangle in axes units
%                          if not specified rbbox is called for user to
%                          select one graphically
%   'Color',ColorSpec - Color of rectangle edge and corner markers
%   'LineWidth',w - rectangle line width (default=0.5)
%   'LineStyle',LineSpec - rectangle line style (default='-')
%
%   'DragColor',ColorSpec - Color of selection/drag rectangle
%                           default='auto', which uses color set with
%                           'Color' parameter
%   'DragLineWidth',w - drag rectangle line width (default=0.5)
%                       set to 'auto' to use value set with 'LineWidth'
%   'DragLineStyle',LineSpec - drag rectangle line style (default =':')
%                              set to 'auto' to use value set with
%                              'LineStyle' parameter.
%
%   'MarkerSize',w - size of corner markers (default = 12*LineWidth)
%   'ResizeFcn',fcn or 'fcn' or {fcn,arg1...} - Function to call when
%               rectangle size is changed
%               The first argument of fcn will be hrect (the handle to the
%               rectange) use get(hrect,'position') to get position after
%               resize.
%   'LimMode','auto' or 'manual' - if 'manual' axis lims are fixed at
%               limits before imrect2 was called.
%   'HandleVisibility','on'(default)|'off'|'callback'
%               Visibility of object handle (see Rectangle properties)
%               This is useful if you want to have the rectangle persist
%               after something like plot(...) is called.
%               If the parent axes is set to 'NextPlot'='replacechildren'
%               then setting 'handlevisibility'='callback' will prevent
%               plot(...) from deleting the rectangle even if hold on is
%               not set.
%   'LockPosition',true|false(default) - specify if the position is locked
%               after the rectangle has been created. prevent user from
%               modifying position. 
%               LockPosition can be change after the rectangle is created
%               by changing the userdata.
%                   Example:
%                       ud = get(hrect,'userdata'); %get userdata
%                       ud.LockPosition = true; %change value
%                       set(hrect,'userdata',ud); %save userdata
% Output:
%   hrect - handle to the rectangle
%       Note: the hrect will contain userdata with the following elements
%           userdata.hCorners - handle to resize markers at the rect corner
%           userdata.ResizeFcn - the resize function set above
%           userdata.LockPosition - (true/false) flag specifying if 
%                                   rectangle location is locked 
%        Also be aware that the ButtonDownFcn has been set for hrect and
%        the corner points (hPt...)
%==========================================================================
% Copyright 2015, Daniel Kovari. All rights reserved.

%import uiextras.*;

%% input parser
p = inputParser;
p.CaseSensitive = false;
addParameter(p,'Parent',[]);
addParameter(p,'Position',[]);
addParameter(p,'Color','k');
addParameter(p,'HandleVisibility','on', @(x) any(strcmpi(x,{'on','off','callback'})));
addParameter(p,'LineWidth',0.5);
addParameter(p,'LineStyle','-');

addParameter(p,'MarkerSize',[]);
addParameter(p,'ResizeFcn',[],@verify_fcn);
addParameter(p,'LimMode','manual',@(x) any(strcmpi(x,{'auto','manual'})));
addParameter(p,'LockPosition',false, @islogical);

addParameter(p,'DragLineStyle',':');
addParameter(p,'DragLineWidth','auto');
addParameter(p,'DragColor','auto');

parse(p,varargin{:});

%% check drag line styles
if strcmpi(p.Results.DragLineStyle,'auto')
    userdata.DragLineStyle = p.Results.LineStyle;
else
    userdata.DragLineStyle = p.Results.DragLineStyle;
end

if ischar(p.Results.DragColor)&&strcmpi(p.Results.DragColor,'auto')
    userdata.DragColor = p.Results.Color;
else
    userdata.DragColor = p.Results.DragColor;
end

if ischar(p.Results.DragLineWidth)&&strcmpi(p.Results.DragLineWidth,'auto')
    userdata.DragLineWidth = p.Results.LineWidth;
else
    userdata.DragLineWidth = p.Results.DragLineWidth;
end

%% check parent axes & default position
hparent = p.Results.Parent;
position = p.Results.Position;
if ~isempty(hparent)
    if ~ishandle(hparent)||~strcmpi(get(hparent,'type'),'axes')
        error('hparent was not a valid axes handle');
    end
else
    hparent = gca;
end
if ~isempty(position)
    if ~isnumeric(position)||numel(position)~=4
        error('position must be [x,y,w,h]');
    end
end

%% use UIextras.getrect2 to get initial position
if isempty(position) 
    position = uiextras.getrect2(hparent,...
                        'LineStyle',userdata.DragLineStyle,...
                        'Color',userdata.DragColor,...
                        'LineWidth',userdata.DragLineWidth);
    if isempty(position)
        hrect = [];
        return;
    end
end

%% Create rectangle
if strcmpi(p.Results.LimMode,'manual')
    xl = get(hparent,'xlim');
    yl = get(hparent,'ylim');
end
hrect = rectangle('parent',hparent,...
    'position',position,...
    'HandleVisibility',p.Results.HandleVisibility,...
    'LineWidth',p.Results.LineWidth,...
    'LineStyle',p.Results.LineStyle,...
    'EdgeColor',p.Results.Color);
if strcmpi(p.Results.LimMode,'manual')
    set(hparent,'xlim',xl);
    set(hparent,'ylim',yl);
end

MarkerSize = p.Results.MarkerSize;
if isempty(MarkerSize)
    MarkerSize = 12*p.Results.LineWidth;
end

%setup resize handle points on corners
userdata.hCorners = line([position(1),...
                        position(1)+position(3),...
                        position(1)+position(3),...
                        position(1)],...
                        [position(2),...
                        position(2),...
                        position(2)+position(4),...
                        position(2)+position(4)],...
    'parent',hparent,...
    'HandleVisibility',p.Results.HandleVisibility,...
    'LineStyle','none',...
    'marker','s',...
    'MarkerSize',MarkerSize,...
    'MarkerEdgeColor','none',...
    'MarkerFaceColor',p.Results.Color,...
    'ButtonDownFcn',{@corner_click,hrect});

userdata.ResizeFcn = p.Results.ResizeFcn;
userdata.LockPosition = p.Results.LockPosition;

%% create listener for position change
userdata.PosListener = addlistener(hrect,'Position','PostSet',@ResizeListener);

%% Set rect userdata and callbacks
set(hrect,'userdata',userdata);
set(hrect,'ButtonDownFcn',@drag_rect);
set(hrect,'DeleteFcn',@delete_rect); %this should be changed to a listener


end

%% More Callback Definitions

function corner_click(~,~,hrect)
    ud = get(hrect,'userdata');
    if ud.LockPosition %check if lock position
        return;
    end
    %ud.PosListener.Enabled = false;
    hax = get(hrect,'parent');
    pos = get(hrect,'position');
    pos = uiextras.getrect2(hax,pos,...
                            'LineStyle',ud.DragLineStyle,...
                            'Color',ud.DragColor,...
                            'LineWidth',ud.DragLineWidth);
    %set positions
    set(hrect,'position',pos);
    ExecResizeFcn(hrect);
end

function drag_rect(hrect,~)
    ud = get(hrect,'userdata');
    if ud.LockPosition
        return;
    end
    hax = get(hrect,'parent');
    pos = get(hrect,'position');
    pos = uiextras.dragrect2(pos,'Parent',hax,...
        'LineStyle',ud.DragLineStyle,...
        'Color',ud.DragColor,...
        'LineWidth',ud.DragLineWidth,...
        'Marker','none');
    set(hrect,'position',pos);
    ExecResizeFcn(hrect);
end

function ResizeListener(~,evt)
hrect = evt.AffectedObject;
userdata = get(hrect,'userdata');
position = get(hrect,'Position');
set(userdata.hCorners,'xdata',[position(1),...
                        position(1)+position(3),...
                        position(1)+position(3),...
                        position(1)],...
                        'ydata',[position(2),...
                        position(2),...
                        position(2)+position(4),...
                        position(2)+position(4)]);
end


function ExecResizeFcn(hrect)
ud = get(hrect,'userdata');
if isempty(ud.ResizeFcn)
    return;
end

if ischar(ud.ResizeFcn)
    f = str2func(ud.ResizeFcn);
elseif iscell(ud.ResizeFcn)
    if ischar(ud.ResizeFcn{1})
        f = str2func(ud.ResizeFcn{1});
        f = @(x) f(x,ud.ResizeFcn{2:end});
    else
        f = @(x) ud.ResizeFcn{1}(x,ud.ResizeFcn{2:end});
    end
elseif isa(ud.ResizeFcn,'function_handle')
    f = ud.ResizeFcn;
else
    error('Something is wrong with ud.ResizeFcn');
end
f(hrect);
end

function stat = verify_fcn(f)
if isa(f,'function_handle')
    stat=true;
elseif ischar(f)
    stat = true;
elseif iscell(f)&&(isa(f{1},'function_handle')||ischar(f{1}))
    stat = true;
elseif isempty(f)
    stat = true;
else
    stat = false;
end
end

function delete_rect(hrect,~)
%disp('indelete')
ud = get(hrect,'userdata');
%delete corner points
try
    delete(ud.hCorners);
    
catch
end
%delete the rectangle;
delete(hrect);
end