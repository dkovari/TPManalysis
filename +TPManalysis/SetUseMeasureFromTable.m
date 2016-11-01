function SetUseMeasureFromTable(UIdata)

UseMeas = cell2mat(UIdata.hTbl.Data(:,3));
for n=1:numel(UIdata.data.Bead)
    UIdata.data.Bead(n).UseForMeasurement = UseMeas(n);
end
