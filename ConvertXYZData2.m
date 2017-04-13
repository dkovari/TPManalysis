function ConvertXYZData2(File)
% Convert binary XYZ data from MultiMT based TPM software to the original
% CSV style format output by the LabView based software.


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




%% Convert to text file for TPM code
%File Format
% Time(ms) Label1 X1(px) Y1(px) ...

[~,fname,~] = fileparts(filename);
[TPMname,TPMpath] = uiputfile('*.txt','Save TPM formated data',fullfile(Dir,[fname,'_TPMformat.txt']));
if TPMname==0
    return;
end

%write file header
fout = fopen(fullfile(TPMpath,TPMname),'w');
fprintf(fout,'Time');
for trk=1:num_tracks
    fprintf(fout,'\tID\tX%d\tY%d',trk,trk,trk);
end
fprintf(fout,'\n');

idx = 1;
Time1 = 0;


hWait = waitbar(0,'Converting data, please wait...');

while ~feof(fid)
     t = fread(fid,1,'double');
     if isempty(t)
         break;
     end
    if idx ==1
        Time1 = t;
    end
    
    x = fread(fid,num_tracks,'double'); %x data for all tracks
    y = fread(fid,num_tracks,'double'); %y data for all tracks
    fread(fid,num_tracks,'double'); %z data for all tracks
    
    fprintf(fout,'%0.08e',(t-Time1)*24*60*60*1000); %write time to file in ms
    for trk=1:num_tracks %write: trk num, x, y...
        fprintf(fout,'\t%d\t%0.06e\t%0.06e',trk,x(trk),y(trk));
    end
    fprintf(fout,'\n'); %advance to next line
    
    waitbar(ftell(fid)/fsize,hWait);

    idx=idx+1;
end
close(hWait);
fclose(fid);
fclose(fout);

