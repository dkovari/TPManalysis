function TPMdata = LoadTPMData_oldMultiMT(File,PxScale)

%%
persistent last_dir;

if nargin<1
    %select file
    [File,Dir] = uigetfile(fullfile(last_dir,'*_LiveXYZData_*_TrackInfo.txt'),'Select XYZ Data File');
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

PxScaleDefault = 66000/1364.6; %66um/1364.6px %nm/px updated 6/16/2016 for use with Jai GigE c140ge w 100x lens
if nargin<2
    PxScale(1) = PxScaleDefault;
    PxScale(2) = PxScaleDefault;
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

TrkRef = dlmread(fullfile(Dir,File),',',1,0);

%% Load Data from file
vals = sscanf(File,'%4d-%2d-%2d_LiveXYZData_%3d_TrackInfo.txt');
filename = sprintf('%4d-%02d-%02d_LiveXYZData_%03d.bin',vals);

file = fullfile(Dir,filename);

finfo = dir(file);
fsize = finfo.bytes;
fid = fopen(file,'r');
if fid<0
    error('could not open binary data file: %s',filename);
end

num_tracks = size(TrkRef,1);

hWait = waitbar(0,'Loading data, please wait...');

TPMdata.TimeDateNum = [];
TPMdata.Bead(num_tracks) = struct('Xraw',[],'Yraw',[]);

%% preallocate data
N_BYTES = 3*8*num_tracks+8; %number of bytes per record 8 bytes per coord (x,y,z) + 8bytes for timestamp
N_RECORDS = fsize/N_BYTES;
for n=1:num_tracks
    TPMdata.Bead(num_tracks).Xraw = NaN(N_RECORDS,1);
    TPMdata.Bead(num_tracks).Yraw = NaN(N_RECORDS,1);
end
TPMdata.TimeDateNum = NaN(N_RECORDS,1);


%% load data from file
recID = 1;
while ~feof(fid)
     t = fread(fid,1,'double');
     if isempty(t)
         break;
     end
    
    [x,count_x] = fread(fid,num_tracks,'double'); %x data for all tracks
    [y,count_y] = fread(fid,num_tracks,'double'); %y data for all tracks
    fread(fid,num_tracks,'double'); %z data for all tracks
    
    if numel(x)~=num_tracks || numel(y)~=num_tracks
        fprintf('Number does not match. x: %d/%d, y: %d/%d\n',count_x, num_tracks, count_y, num_tracks);
        break;
    end
    
    %copy data into TPMdata struct
    TPMdata.TimeDateNum(recID,1) = t;
    for n=1:num_tracks
        TPMdata.Bead(n).Xraw(recID,1) = x(n)*PxScale(1);
        TPMdata.Bead(n).Yraw(recID,1) = y(n)*PxScale(2);
    end
    
    recID = recID+1;
    waitbar(ftell(fid)/fsize,hWait);
end
close(hWait);

%remove extras records
rmInd = find(isnan(TPMdata.TimeDateNum));
TPMdata.TimeDateNum(rmInd) = [];
for n=1:num_tracks
    TPMdata.Bead(n).Xraw(rmInd) = [];
    TPMdata.Bead(n).Yraw(rmInd) = [];
end

TPMdata.TimeSec = (TPMdata.TimeDateNum - TPMdata.TimeDateNum(1))*(24*3600);

if nargout <1
    uiextras.uiputvar(TPMdata);
    clear TPMdata;
end

