function [b,TPMdata] = validateTPMdata(TPMdata)

%% Validate & Initialize Data
b = true;
try
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
catch
    b=false;
end
