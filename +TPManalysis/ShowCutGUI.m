function hFig = ShowCutGUI(UIdata,BeadIndex)
% shows cut menu for specified bead index
% UIdata = SharedHandle containing TPMdata and other gui handles
%   UIdata.hTbl = handle to table on main figure
%   UIdata.data
%        .TimeSec = step time in seconds
%        .Bead(n)
%            .sigmaX
%            .sigmaY
%            .SymmetryRatio
%            .UseForDrift
%            .UseForMeasurement
%            .Xraw = raw bead position in nm
%            .Yraw = raw bead position in nm
%            .Xcorrected = drift corrected position in nm
%            .Ycorrected
%            .IncludeData
%        .driftX
%        .driftY

%% Import package
import TPManalysis.*

%% Create panel menu
[hFig, hAx, hPnl,hPnl_AxPar] = panel_plot('PanelWidth',32);
set(hFig,'Name',sprintf('Cut Menu - Bead: %d',BeadIndex));
set(hFig,'NumberTitle','off');

%% Create Plots
hAx_x = subplot(4,1,1,hAx); %convert axes to subplot
hAx_y = subplot(4,1,2,'Parent',hPnl_AxPar);
hAx_hist = subplot(4,1,3:4,'Parent',hPnl_AxPar);

%% create buttons
uicontrol('Parent',hPnl,...
            'Style','pushbutton',...
            'units','characters',...
            'position',[1,4.75,30,2],...
            'String','Add Exclusion on X',...
            'TooltipString','Use cursor to select region to exclude on the X-position plot',...
            'Callback',@(~,~)AddExclusion('x'));
uicontrol('Parent',hPnl,...
            'Style','pushbutton',...
            'units','characters',...
            'position',[1,2.5,30,2],...
            'String','Add Exclusion on Y',...
            'TooltipString','Use cursor to select region to exclude on the Y-position plot',...
            'Callback',@(~,~)AddExclusion('y'));
                
uicontrol('Parent',hPnl,...
            'Style','pushbutton',...
            'units','characters',...
            'position',[1,.25,30,2],...
            'String','Reset Exclusions',...
            'TooltipString','Reset to include all data in trace',...
            'Callback',@ResetExclusion);
%% Callbacks
    function UpdatePlots()
        inc = find(UIdata.data.Bead(BeadIndex).IncludeData);
        exc = find(~(UIdata.data.Bead(BeadIndex).IncludeData));
        
        cla(hAx_x);
        hold(hAx_x,'on');
        meanX = nanmean(UIdata.data.Bead(BeadIndex).Xcorrected(inc));
        mX = UIdata.data.Bead(BeadIndex).Xcorrected - meanX;
        plot(hAx_x,UIdata.data.TimeSec(inc),...
            mX(inc),'-k');
        plot(hAx_x,UIdata.data.TimeSec(exc),...
            mX(exc),'.r');
        xlabel(hAx_x,'Time [sec]');
        ylabel(hAx_x,'X Position [nm]');
        
        cla(hAx_y);
        hold(hAx_y,'on');
        meanY = nanmean(UIdata.data.Bead(BeadIndex).Ycorrected(inc));
        mY = UIdata.data.Bead(BeadIndex).Ycorrected - meanY;
        plot(hAx_y,UIdata.data.TimeSec(inc),...
            mY(inc),'-k');
        plot(hAx_y,UIdata.data.TimeSec(exc),...
            mY(exc),'.r');
        xlabel(hAx_y,'Time [sec]');
        ylabel(hAx_y,'Y Position [nm]');
        
        cla(hAx_hist);
        histogram(sqrt(mX(inc).^2+mY(inc).^2),'EdgeColor','none','parent',hAx_hist);
        xlabel(hAx_hist,'Projected Radius \rho [nm]');
        ylabel(hAx_hist,'Counts');
        
        % update sym stats
        [sigx, sigy, SymRatio] = TPManalysis.CalcSymStats(...
            UIdata.data.Bead(BeadIndex).Xcorrected(inc),...
            UIdata.data.Bead(BeadIndex).Ycorrected(inc));
        UIdata.data.Bead(BeadIndex).sigmaX = sigx;
        UIdata.data.Bead(BeadIndex).sigmaY = sigy;
        UIdata.data.Bead(BeadIndex).SymmetryRatio = SymRatio;
        
        TPManalysis.SetUseMeasureFromTable(UIdata);
        TPManalysis.UpdateGUItable(UIdata);
    end

    function AddExclusion(ax)
        persistent infunction; %lock out other instances from calling add exclusionX
        if isempty(infunction) || ~infunction
            infunction = true;
        else
            return;
        end
        %'here'
        if ax == 'x'
            hAx = hAx_x;
            otherAx = hAx_y;
        else
            hAx = hAx_y;
            otherAx = hAx_x;
        end
        
        set(otherAx,'visible','off');
        set(hAx_hist,'visible','off');
        
        title(hAx,'Draw rectangle, press return to accept, Esc. to cancel');
        
        hRect = uiextras.imrect2('Parent',hAx,'Color',[1,0,0],'LimMode','manual');
        
        if isempty(hRect)
            range = [];
        else
            range = [hRect.Position(1),hRect.Position(1)+hRect.Position(3)];
        end
        
        function FigKey(~,evt)
            switch evt.Key
                case 'return'
                    %disp(hRect.Position)
                    range = [hRect.Position(1),hRect.Position(1)+hRect.Position(3)];
                    delete(hRect);
                case 'escape'
                    %disp(hRect.Position)
                    range = [];
                    delete(hRect);
            end
        end
        
        set(hFig,'KeyPressFcn',@FigKey);
        
        waitfor(hRect);
        set(hFig,'KeyPressFcn',[]);
        
        if ~isempty(range)
            exclude = UIdata.data.TimeSec>range(1)&...
                        UIdata.data.TimeSec<range(2);
            
            UIdata.data.Bead(BeadIndex).IncludeData(exclude) = false;
        end
        
        %turn other axes back on
        set(otherAx,'visible','on');
        set(hAx_hist,'visible','on');
        title(hAx,[]);
        
        UpdatePlots();
                
        %all done release lock
        infunction = false;
    end

    function ResetExclusion(~,~)
        UIdata.data.Bead(BeadIndex).IncludeData = true(size(UIdata.data.Bead(BeadIndex).Xcorrected));
        UpdatePlots();
    end

UpdatePlots();
    

end