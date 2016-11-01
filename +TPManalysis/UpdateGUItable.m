function UpdateGUItable(UIdata)

Data = [num2cell((1:numel(UIdata.data.Bead))'),...
        num2cell([UIdata.data.Bead.UseForDrift]'),...
        num2cell([UIdata.data.Bead.UseForMeasurement]'),...
        num2cell([UIdata.data.Bead.sigmaX]'),...
        num2cell([UIdata.data.Bead.sigmaY]'),...
        num2cell([UIdata.data.Bead.SymmetryRatio]')];

    UIdata.hTbl.Data = Data;
end