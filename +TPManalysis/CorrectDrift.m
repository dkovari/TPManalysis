function CorrectDrift(UIdata)
% UIData = SharedHandle containing TPMdata
%   UIData.data
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
import TPManalysis.*

DriftBeads = [UIdata.data.Bead.UseForDrift];
if ~any(DriftBeads)
     for n=1:numel(UIdata.data.Bead)
        UIdata.data.Bead(n).Xcorrected = UIdata.data.Bead(n).Xraw;
        UIdata.data.Bead(n).Ycorrected = UIdata.data.Bead(n).Yraw;
     end
     UIdata.data.driftX= zeros(size(UIdata.data.TimeSec));
     UIdata.data.driftY= zeros(size(UIdata.data.TimeSec));
     return;
end
DriftBeads = find(DriftBeads);
%% Calculate Drift using only IncludeData points
driftX = [UIdata.data.Bead(DriftBeads).Xraw];
driftY = [UIdata.data.Bead(DriftBeads).Yraw];

exc = find(~[UIdata.data.Bead(DriftBeads).IncludeData]);
driftX(exc) = NaN;
driftY(exc) = NaN;

% Apply moving avg to smooth data
dT = nanmean(diff(UIdata.data.TimeSec));
wind = max(3,1/dT);

driftX = movingavg(driftX,wind,1);
driftY = movingavg(driftY,wind,1);

%subtract first to find frame-by-frame shift
delCols = []; %columns that are all nan
for n=1:size(driftX,2)
    first_ind = find(~isnan(driftX(:,n))&~isnan(driftY(:,n)),1,'first');
    if isempty(first_ind)
        delCols = [delCols,n];
        continue;
    end
    driftX(:,n) = driftX(:,n) - driftX(first_ind,n);
    driftY(:,n) = driftY(:,n) - driftY(first_ind,n);
end
driftX(:,delCols) = []; %delete all NaN columns
driftY(:,delCols) = [];
 
%average all the drift beads
driftX = nanmean(driftX,2);
driftY = nanmean(driftY,2);

%if we still have some nans in the data, set them to zero so that we don't
%apply drift correction during those frames.
driftX(isnan(driftX)) = 0;
driftY(isnan(driftY)) = 0;

for n=1:numel(UIdata.data.Bead)
    UIdata.data.Bead(n).Xcorrected = UIdata.data.Bead(n).Xraw - driftX;
    UIdata.data.Bead(n).Ycorrected = UIdata.data.Bead(n).Yraw - driftY;
    
    inc = find(UIdata.data.Bead(n).IncludeData);
    
    [sigx, sigy, SymRatio] = CalcSymStats(...
            UIdata.data.Bead(n).Xcorrected(inc),...
            UIdata.data.Bead(n).Ycorrected(inc));
        UIdata.data.Bead(n).sigmaX = sigx;
        UIdata.data.Bead(n).sigmaY = sigy;
        UIdata.data.Bead(n).SymmetryRatio = SymRatio;
end

UIdata.data.driftX = driftX;
UIdata.data.driftY = driftY;

