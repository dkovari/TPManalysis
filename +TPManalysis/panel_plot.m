function [hFig, hAx, hPnl,hPnl_AxPar] = panel_plot(varargin)
%create figure containing a single axes and uipanel
% uipanel will always be on the right side and won't change in width unless
% the user sets the panel position.
% Note: axes is contained inside a panel with hidden borders.
% if you want to convert the axes to a subplot you can get its parent first
% so that you can create additional subplots
% 
% Optional Parameters:
%   'ParentFigure': figure to use
%   'PanelUnits', string : units to use for panel (default: 'characters')
%   'PanelWidth', ##:   width of the panel in specified units
%
%   'AxesProperties':{Name,Value, Name, Value,...}
%               User can pass name-value paramter options to the axes()
%               function. 'Units' and 'Position' are ignored

p = inputParser;
p.CaseSensitive = false;

addParameter(p,'PanelUnits','characters',@ischar)
addParameter(p,'PanelWidth',30,@(x) isnumeric(x)&&isscalar(x)&&x>0);
addParameter(p,'AxesProperties',{},@iscell);
addParameter(p,'ParentFigure',[])

parse(p,varargin{:});

if ~isempty(p.Results.ParentFigure) && ishghandle(p.Results.ParentFigure)
    hFig = p.Results.ParentFigure;
    clf(hFig);
    set(hFig,'units','characters');
else
    hFig = figure('units','characters');
end
fig_pos = get(hFig,'position');

aP = inputParser;
aP.CaseSensitive = false;
aP.KeepUnmatched = true;

addParameter(aP,'Position',[]);
addParameter(aP,'Units',[]);
parse(aP,p.Results.AxesProperties{:});
AxesProps = [ reshape( fieldnames(aP.Unmatched),1,[]);reshape(struct2cell(aP.Unmatched),1,[])];


hPnl_AxPar = uipanel('Parent',hFig,...
                'units',p.Results.PanelUnits,...
                'position',[0,0,fig_pos(3)-p.Results.PanelWidth,fig_pos(4)],...
                'BorderType','none');

hAx = axes('Parent',hPnl_AxPar, AxesProps{:});

hPnl = uipanel('Parent',hFig,...
                'units',p.Results.PanelUnits,...
                'position',[fig_pos(3)-p.Results.PanelWidth,0,p.Results.PanelWidth,fig_pos(4)],...
                'SizeChangedFcn',@(hPnl,~) fig_resize(hFig,hPnl_AxPar,hPnl));
            
set(hFig,'SizeChangedFcn',@(~,~) fig_resize(hFig,hPnl_AxPar,hPnl));
set(hFig,'CurrentAxes',hAx);

hMenu = uimenu(hFig,'Label','PanelPlot');
uimenu(hMenu,'Label','Copy Plot without panel','Callback',@(~,~) copyplot(hAx));

function fig_resize(hFig,hPnl_AxPar, hPnl)
orig_figunits = get(hFig,'units');
set(hFig,'units','characters');
fig_pos = get(hFig,'position');
orig_axunits = get(hPnl_AxPar,'units');
orig_pnlunits = get(hPnl,'units');

set(hPnl_AxPar,'units','characters');
set(hPnl,'units','characters');

pnl_pos = get(hPnl,'position');

set(hPnl,'position',[fig_pos(3)-pnl_pos(3),0,pnl_pos(3),fig_pos(4)]);
set(hPnl_AxPar,'position',[0,0,fig_pos(3)-pnl_pos(3),fig_pos(4)]);

set(hFig,'units',orig_figunits);
set(hPnl_AxPar,'units',orig_axunits);
set(hPnl,'units',orig_pnlunits);

function copyplot(hAx)
leg = findobj(hAx.Parent,'Type','legend');
hands = copyobj([leg,hAx],figure());
hAx2 = hands(numel(leg)+1);
set(hAx2,'units','normalized');
set(hAx2,'outerposition',[0,0,1,1]);