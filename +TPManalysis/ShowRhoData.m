function ShowRhoData(UIdata,BeadIndex)
import TPManalysis.*

%calculate Moving average window duration
dT = nanmean(diff(UIdata.data.TimeSec));
maWIND = round(30/dT);
Tavg = 4; %4 sec avg
rmsWIND = round(Tavg/dT);

padT = UIdata.data.TimeSec;
padT(end+1:end+rmsWIND-mod(numel(padT),rmsWIND)) = NaN;
mean_T = nanmean(reshape(padT,rmsWIND,[]),1)';

for n = reshape(BeadIndex,1,[])
    %find the bead's histogram figure if it is open
    hFHist = findobj('Type','Figure','Name',sprintf('Rho-RMS Histogram: Bead %d',n));
    if isempty(hFHist)
        hFHist = figure('Name',sprintf('Rho-RMS Histogram: Bead %d',n),'NumberTitle','off');
    else
        hFHist = figure(hFHist(1));
    end
    clf(hFHist);
    %find the bead's trace figure if it is open
    hFTrace = findobj('Type','Figure','Name',sprintf('Rho-RMS Trace: Bead %d',n));
    if isempty(hFTrace)
        hFTrace = figure('Name',sprintf('Rho-RMS Trace: Bead %d',n),'NumberTitle','off');
    else
        hFTrace = figure(hFTrace(1));
    end
    clf(hFTrace);
    
    %% Data to include
    excl = find(~UIdata.data.Bead(n).IncludeData);
    
    %% subtract moving average
    mX = UIdata.data.Bead(n).Xcorrected-TPManalysis.movingavg(UIdata.data.Bead(n).Xcorrected,maWIND);
    mY = UIdata.data.Bead(n).Ycorrected-TPManalysis.movingavg(UIdata.data.Bead(n).Ycorrected,maWIND);
    
    mX(excl) = NaN;
    mY(excl) = NaN;
    %% rho
    %mR = sqrt(mX.^2 + mY.^2);
    rho2 = mX.^2 + mY.^2;
    %pad with nan
    %mod(numel(rho2),rmsWIND)
    rho2(end+1:end+rmsWIND-mod(numel(rho2),rmsWIND)) = NaN;
    rho2(end-rmsWIND-1:end)=NaN;
    mean_rho2 = nanmean(reshape(rho2,rmsWIND,[]),1)';
    low_rho2 = (rmsWIND-1)*mean_rho2/chi2inv(.975,rmsWIND-1);
    up_rho2 = (rmsWIND-1)*mean_rho2/chi2inv(.025,rmsWIND-1);
    
    %% Limits
	RhoLim = [0,max(up_rho2(:))];
    
    %% Plot Trace
    figure(hFTrace);
    plot(padT,rho2,'.','color',[199,217,252]/255,'markersize',2);
    
    hold on;
    hdat = plot(mean_T,mean_rho2,'color','k','linewidth',1.5);

    heb = plot(mean_T,low_rho2,'-','color',[0.45,0.45,0.45],'linewidth',0.5);
    plot(mean_T,up_rho2,'-','color',[0.45,0.45,0.45],'linewidth',0.5);

    ylabel('Excursion \rho^2 [nm^2]','FontSize',14);
    xlabel('Time [sec]','FontSize',14);
    axis tight;

    legend([hdat,heb],{'<\rho^2>_{4s}','95% Confidence'});
    ylim(2*RhoLim);
    
    %% histogram
    figure(hFHist)
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
end