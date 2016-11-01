function [TPMdata_odd, TPMdata_even] = LoadTPMdata_CSV(File,PxScale)

persistent last_dir;

if nargin<1
    %select file
    [File,Dir] = uigetfile(fullfile(last_dir,'*.txt'),'Select CSV Data File');
    if File==0
        return
    end
    if ~isempty(Dir)
        last_dir = Dir;
    end
    [~,name,ext] = fileparts(File);
else
    [Dir,name,ext] = fileparts(File);
    File = [name,ext];
end

%PxScaleDefault = 66000/1364.6; %66um/1364.6px %nm/px updated 6/16/2016 for use with Jai GigE c140ge w 100x lens
if nargin<2
    PxScale(1) = 6500/100;%PxScaleDefault; %original pxscale from analog camera
    PxScale(2) = 6250/100;%PxScaleDefault; %original pxscale from analog camera
    while true
        answer = inputdlg({'X Scale (nm/px)','Y Scale (nm/px)'},'Pixel Scale',1,{num2str(PxScale(1)),num2str(PxScale(2))});
        if isempty(answer)
            return;
        end
        PxScale(1) = str2double(answer{1});
        PxScale(2) = str2double(answer{2});
        if all(~isnan(PxScale))
            break;
        end
    end
end
if isscalar(PxScale)
    PxScale = [PxScale,PxScale];
end

%% Load data
a.data=dlmread(fullfile(Dir,File),'',1,0);%reads the text file into structure a
%skips the first line because it should be a header

%odd and even lines are separated and the data is stored in b. the
%separation is required because of the difference in the odd and even
%sensors in the camera
b.time_odd=(a.data(1:2:length(a.data(:,1)),1)-a.data(1,1))/1000;
b.data_odd=(a.data(1:2:length(a.data(:,1)),2:size(a.data,2)));
b.time_even=(a.data(2:2:length(a.data(:,1)),1)-a.data(1,1))/1000;
b.data_even=(a.data(2:2:length(a.data(:,1)),2:size(a.data,2)));
b.beadsnumber=size(b.data_odd,2)/3;
clear a;
%coordinates are converted to nm or length scale
for i=1:b.beadsnumber
    b.beadslabel(i)=b.data_odd(1,i*3-2);
    b.beadsx_odd(:,i)=b.data_odd(:,i*3-1)*PxScale(1);
    b.beadsy_odd(:,i)=b.data_odd(:,i*3)*PxScale(2);    
    b.beadsx_even(:,i)=b.data_even(:,i*3-1)*PxScale(1);
    b.beadsy_even(:,i)=b.data_even(:,i*3)*PxScale(2);
end

TPMdata_odd.TimeSec = b.time_odd;
TPMdata_even.TimeSec = b.time_even;

num_tracks = b.beadsnumber;%size(b.data_odd,2);

TPMdata_odd.Bead(num_tracks) = struct('Xraw',[],'Yraw',[]); 
TPMdata_even.Bead(num_tracks) = struct('Xraw',[],'Yraw',[]);

for n=1:num_tracks
    TPMdata_odd.Bead(n).Xraw = b.beadsx_odd(:,n);
    TPMdata_odd.Bead(n).Yraw = b.beadsy_odd(:,n);
    TPMdata_even.Bead(n).Xraw = b.beadsx_even(:,n);
    TPMdata_even.Bead(n).Yraw = b.beadsy_even(:,n);
end

if nargout <1
    putvar(TPMdata_odd,TPMdata_even);
    clear TPMdata_odd;
    clear TPMdata_even;
end