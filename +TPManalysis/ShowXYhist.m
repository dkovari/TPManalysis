function ShowXYhist(UIdata,BeadIndex)
import TPManalysis.*
for n = reshape(BeadIndex,1,[])
    %find the bead's histogram figure if it is open
    hF = findobj('Type','Figure','Name',sprintf('2D Histogram: Bead %d',n));
    if isempty(hF)
        hF = figure('Name',sprintf('2D Histogram: Bead %d',n),'NumberTitle','off');
    else
        hF = figure(hF(1));
    end
    clf(hF);
    %compute bin locations
    inc = find(UIdata.data.Bead(n).IncludeData);
    binWidth = 2*(numel(UIdata.data.Bead(n).Xcorrected))^(-1/3)*max(iqr(UIdata.data.Bead(n).Xcorrected(inc)),iqr(UIdata.data.Bead(n).Ycorrected(inc)));
    xMed = median(UIdata.data.Bead(n).Xcorrected(inc));
    yMed = median(UIdata.data.Bead(n).Ycorrected(inc));
    %xmin = min(UIdata.data.Bead(n).Xcorrected)
    xCntrs = [ flip(xMed:-binWidth:min(UIdata.data.Bead(n).Xcorrected(inc))),...
                xMed+binWidth:binWidth:max(UIdata.data.Bead(n).Xcorrected(inc))];
    yCntrs = [ flip(yMed:-binWidth:min(UIdata.data.Bead(n).Ycorrected(inc))),...
                yMed+binWidth:binWidth:max(UIdata.data.Bead(n).Ycorrected(inc))];
    counts = hist3([UIdata.data.Bead(n).Xcorrected(inc),...
                    UIdata.data.Bead(n).Ycorrected(inc)],...
                    {xCntrs, yCntrs});
    %show histogram image
    hPC = pcolor(xCntrs,yCntrs,counts');
    set(hPC,'EdgeColor','none');
    xlabel('X position [nm]');
    ylabel('Y position [nm]');
    axis('equal');

    %show coutour plot
    hold on;
    blurCounts = gaussian_filter(counts',2,10,'same');
    [~,hCont] = contour(xCntrs,yCntrs,blurCounts);

    set(hCont,'LineColor','r','LineWidth',1);


    %show colorbar
    hCB = colorbar('eastoutside');
    ylabel(hCB,'Count');

    title(sprintf('\\sigma_x:%0.04f, \\sigma_y:%0.04f, Sym. sqrt(\\lambda_1/\\lambda_2):%0.04f',...
        UIdata.data.Bead(n).sigmaX,UIdata.data.Bead(n).sigmaY,UIdata.data.Bead(n).SymmetryRatio));

end