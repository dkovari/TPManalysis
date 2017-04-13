function PlotRhoHistograms(TPMdata,varargin)
% Plot Histogram of TPM particle excursion
% Input:
%	 TPMdata: analyzed TPM data, created by TPManalysis.m
%           if TPMdata is empty, user is prompted to select a variable
%           from the workspace
%
% Parameters:
%   UseFlag, true/false: specify if resulting plots should be filtered to
%   only show data from bead with "UseForMeasurement=1". (default=true)

%% Add package
import TPManalysis.*

%% Parse parameters
p = inputParser();
p.CaseSensitive = false;
addParameter(p,'UseFlag',true,@(x) isscalar(x));

parse(p,varargin{:});

%% import data if needed



%% Select data with gui if needed
if nargin<1 || isempty(TPMdata)
    disp('Select TPM data variable');
    [TPMdata,varname] = uigetvar('struct');
    if isempty(TPMdata)
        return;
    end

end
[b,TPMdata] =validateTPMdata(TPMdata);
assert(b,'Invalid TPMdata variable');

%% Select output location
answer = questdlg('Do you want to save the plots and data?','Save?','Yes','No','Yes');

savedata = false;
if strcmp(answer,'Yes')
    savedata = true;
    [FileBase,PathName] = uiputfile('*.fig','Select output location and base name');
    if FileBase == 0
        savedata = false;
    else
        [~,FileBase,~] = fileparts(FileBase);
    end
end


%% Loop over data and plot rho and rho^2

if p.Results.UseFlag
    BeadID = find([TPMdata.Bead.UseForMeasurement]);
else
    BeadID = 1:numel(TPMdata.Bead);
end

%calculate Moving average window duration
dT = nanmean(diff(TPMdata.TimeSec));
maWIND = round(30/dT);
Tavg = 4; %4 sec avg
rmsWIND = round(Tavg/dT);

padT = TPMdata.TimeSec;
padT(end+1:end+rmsWIND-mod(numel(padT),rmsWIND)) = NaN;
mean_T = nanmean(reshape(padT,rmsWIND,[]),1)';


for n = BeadID
    %% Data to include
    excl = find(~TPMdata.Bead(n).IncludeData);
    
    %% subtract moving average
    movavgX = TPMdata.Bead(n).Xcorrected-TPManalysis.movingavg(TPMdata.Bead(n).Xcorrected,maWIND);
    movavgY = TPMdata.Bead(n).Ycorrected-TPManalysis.movingavg(TPMdata.Bead(n).Ycorrected,maWIND);
    
    movavgX(excl) = NaN;
    movavgY(excl) = NaN;
    %% rho
    rho = sqrt(movavgX.^2 + movavgY.^2);
    rho2 = movavgX.^2 + movavgY.^2;
    %pad with nan
    %mod(numel(rho2),rmsWIND)
    rho2(end+1:end+rmsWIND-mod(numel(rho2),rmsWIND)) = NaN;
    rho2(end-rmsWIND-1:end)=NaN;
    mean_rho2 = nanmean(reshape(rho2,rmsWIND,[]),1)';
    low_rho2 = (rmsWIND-1)*mean_rho2/chi2inv(.975,rmsWIND-1);
    up_rho2 = (rmsWIND-1)*mean_rho2/chi2inv(.025,rmsWIND-1);
    
    %% Limits
	RhoLim = [0,max(up_rho2(:))];
    
    %% histogram for rho^2
    hRho2 = figure('Name',sprintf('Bead %d: Rho^2<4s>',n),'NumberTitle','off');
    
    histogram(mean_rho2,linspace(RhoLim(1),RhoLim(2),100),'EdgeColor','none');
    ylabel('Count');
    xlabel('<\rho^2>_{4s} [nm^2]');
    %xlabel('Effective Length (w/ L_p=50nm) [basepair]');

    set(gca,'fontsize',12,...
        'XMinorTick','on',...
        'box','off');

    ax1 = gca;
    ax2=axes('position',ax1.Position,...
        'XaxisLocation','top',...
        'Yaxislocation','right',...
        'color','none',...
        'Ycolor','none');
    xlim(ax2,RhoLim/2/50/.34);
    xlabel(ax2,'Effective Length (w/ L_p=50nm) [bp]');
    
    %% histogram for rho
    hRho = figure('Name',sprintf('Bead %d: Rho',n),'NumberTitle','off');
    histogram(rho,'EdgeColor','none');
    xlabel('Projected Radius \rho [nm]');
    ylabel('Counts');
    title(sprintf('Bead %d: Rho',n));
    
    
    %% save data
    if savedata
        
        RhoFigName = sprintf('%s_Rho_bead%03d.fig',FileBase,n);
        Rho2FigName = sprintf('%s_Rho2_bead%03d.fig',FileBase,n);
        DataName = sprintf('%s_RhoData_bead%03d.mat',FileBase,n);
        
        saveas(hRho,fullfile(PathName,RhoFigName));
        saveas(hRho2,fullfile(PathName,Rho2FigName));
        save(fullfile(PathName,DataName),'rho','rho2','mean_rho2','movavgX','movavgY');
        
    end
    
    
end






