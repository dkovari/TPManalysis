function TPMdata = TPManalysis(TPMdata)
% TPMdata Structure
%   .TimeSec = step time in seconds
%   .Bead(n)
%       .sigmaX
%       .sigmaY
%       .SymmetryRatio
%       .UseForDrift
%       .UseForMeasurement
%       .Xraw = raw bead position in nm
%       .Yraw = raw bead position in nm
%       .Xcorrected = drift corrected position in nm
%       .Ycorrected
%       .IncludeData
%   .driftX
%   .driftY

%% Add package
import TPManalysis.*

%% Select data with gui if needed
if nargin<1
    disp('Select TPM data variable');
    TPMdata = uigetvar('struct');
    if isempty(TPMdata)
        return;
    end
end

if nargout>=1
    outflag = true;
else
    outflag = false;
end
%% Validate & Initialize Data
if ~isfield(TPMdata,'TimeSec')
    error('TPMdata must include TimeSec field, specifying time point (in sec) for each xy location');
end

if ~isfield(TPMdata,'Bead')
    error('TPMdata must include Bead field');
end

if ~isfield(TPMdata.Bead,'Xraw')
    error('TPMdata.Bead must have Xraw field');
end

if ~isfield(TPMdata.Bead,'Yraw')
    error('TPMdata.Bead must have Yraw field');
end

if ~isfield(TPMdata.Bead,'Xcorrected')
    [TPMdata.Bead.Xcorrected] = deal(TPMdata.Bead.Xraw);
end

if ~isfield(TPMdata.Bead,'sigmaX')
    [TPMdata.Bead.sigmaX] = deal(NaN);
end

if ~isfield(TPMdata.Bead,'sigmaY')
    [TPMdata.Bead.sigmaY] = deal(NaN);
end

if ~isfield(TPMdata.Bead,'SymmetryRatio')
    [TPMdata.Bead.SymmetryRatio] = deal(NaN);
end

if ~isfield(TPMdata.Bead,'Ycorrected')
    [TPMdata.Bead.Ycorrected] = deal(TPMdata.Bead.Yraw);
end

if ~isfield(TPMdata.Bead,'UseForMeasurement')
    [TPMdata.Bead.UseForMeasurement] = deal(false);
end

if ~isfield(TPMdata.Bead,'UseForDrift')
    [TPMdata.Bead.UseForDrift] = deal(false);
end

if ~isfield(TPMdata.Bead,'IncludeData')
    [TPMdata.Bead.IncludeData] = deal(0);
    for b=1:numel(TPMdata.Bead)
        TPMdata.Bead(b).IncludeData = true(size(TPMdata.Bead(b).Xraw));
    end
end

%% create a shared handle class so each gui element can share common data
UIdata = SharedHandle;
addprop(UIdata,'data');
UIdata.data = TPMdata;

%% Setup Main GUI Elements

hFig = figure('Name','Cut Data',...
              'NumberTitle','off',...
              'ToolBar','none',...
              'MenuBar','none');

hPnlBtns = uipanel('Parent',hFig,...
                    'units','characters',...
                    'position',[0,0,97,5]);

%% create buttons
%ApplyDrift
uicontrol('Parent',hPnlBtns,...
                    'Style','pushbutton',...
                    'units','characters',...
                    'position',[1,2.5,30,2],...
                    'String','Apply Drift',...
                    'TooltipString','Use the selected beads to calculate drift',...
                    'Callback',@ApplyDrift);
%ShowHistogram
uicontrol('Parent',hPnlBtns,...
                    'Style','pushbutton',...
                    'units','characters',...
                    'position',[1,.25,30,2],...
                    'String','XY Histogram',...
                    'TooltipString','Display histogram of highlighted bead',...
                    'Callback',@ShowHistXY);
%Cut menu             
uicontrol('Parent',hPnlBtns,...
            'Style','pushbutton',...
            'units','characters',...
            'position',[32,2.5,30,2],...
            'String','Exclude Data',...
            'TooltipString','Open menu to choose exclusion windows for selected trace',...
            'Callback',@CutSelected);
                
uicontrol('Parent',hPnlBtns,...
            'Style','pushbutton',...
            'units','characters',...
            'position',[32,.25,30,2],...
            'String','Done',...
            'TooltipString','Save data and close',...
            'Callback',@Done);

uicontrol('Parent',hPnlBtns,...
            'style','pushbutton',...
            'units','characters',...
            'position',[63,2.5,30,2],...
            'String','<rho^2> Data',...
            'TooltipString','Show <rho^2>_4s histogram and time trace',...
            'Callback',@RhoData);
%% Create Table                
set(hPnlBtns,'units','normalized');
pos = get(hPnlBtns,'position');
hPnlTbl = uipanel('Parent',hFig,...
                    'units','normalized',...
                    'BorderType','none',...
                    'position',[0,pos(4),1,1-pos(4)]);

hTbl = uiextras.jTable.Table('Parent',hPnlTbl,...
    'ColumnName',{'Bead','Use Drift','Export Data','sigma_x','sigma_y','symmetry'},...
    'ColumnFormat',{'integer','boolean','boolean','float','float'},...
    'ColumnEditable',[false,true,true,false,false]);

set(hFig,'SizeChangedFcn',@ReSz,...
         'CloseRequestFcn',@Done);
%add hTbl to shared data so that cut menus can update sigma and sym ratio
addprop(UIdata,'hTbl');
UIdata.hTbl = hTbl;
%% Resize Fcn
    function ReSz(~,~)
        set(hPnlBtns,'units','characters');
        pos = get(hPnlBtns,'position');
        pos(4) = 5;
        set(hPnlBtns,'position',pos);        
        set(hPnlBtns,'units','normalized');
        pos = get(hPnlBtns,'position');
        pos = [0,0,1,pos(4)];
        set(hPnlBtns,'position',pos);
        set(hPnlTbl,'position',[0,pos(4),1,1-pos(4)]);
    end
%% Callback Functions
    function Done(~,~)
        TPManalysis.SetUseMeasureFromTable(UIdata);
        %close any cutmenus that are open
        hF = findobj('-regexp','Name','Cut Menu - Bead:');
        delete(hF);
        delete(hFig);
        if ~outflag
            TPMdata = UIdata.data;
            putvar(TPMdata);
        end
    end

    function CutSelected(~,~)
        if isempty(hTbl.SelectedRows)
            return;
        end
        BeadIndex = hTbl.SelectedRows(1);
        hF = findobj('Type','figure','Name',sprintf('Cut Menu - Bead: %d',BeadIndex));
        if ~isempty(hF)
            delete(hF(2:end)); %if there is more than one, delete others
            figure(hF);
        else
            TPManalysis.ShowCutGUI(UIdata,BeadIndex);
        end 
    end

    function ApplyDrift(~,~)
        DriftBeads = cell2mat(hTbl.Data(:,2)); 
        for n=1:numel(UIdata.data.Bead)
            UIdata.data.Bead(n).UseForDrift = DriftBeads(n);
        end
        TPManalysis.CorrectDrift(UIdata);
        TPManalysis.SetUseMeasureFromTable(UIdata);
        TPManalysis.UpdateGUItable(UIdata);
    end

    function ShowHistXY(~,~)
        if isempty(hTbl.SelectedRows)
            return;
        end
        TPManalysis.ShowXYhist(UIdata,hTbl.SelectedRows);
    end

    function RhoData(~,~)
        if isempty(hTbl.SelectedRows)
            return;
        end
        TPManalysis.ShowRhoData(UIdata,hTbl.SelectedRows);
    end

%% Wait here for user to finish
UpdateGUItable(UIdata);
if outflag
    waitfor(hFig);
    TPMdata = UIdata.TPMdata;
else
    clear TPMdata;
end

end