clear;
path = '/storage/dane/jgrzybowska/bazyaudio/Timit/TIMIT/TRAIN/all';
path_to_write = '/storage/dane/jgrzybowska/bazyaudio/Timit/TIMIT/TRAIN/merged';
addpath(path);

folders = dir(path);
folders = folders(3:end);
n=1;

for i=1:size(folders,1)
  if folders(i).isdir == 1
      folders_new{n,1} = folders(i).name;       % foldery z wavami
      n = n+1;
  end
end

for i=1:n-1
   newpath = [path '/' folders_new{i,1} '/'];
   files = dir([newpath '*.WAV']);
   signal = [];
   [~,fs] = audioread([newpath files(1).name]);
   
   for m = 1:size(files,1)
     signal = [signal; audioread([newpath files(m).name])];   % sklejony wav
   end
   
   audiowrite([path_to_write '/' folders_new{i,1}(2:end) '.wav'], signal, fs);
   disp(['Audio files saved: ' num2str(i) '/' num2str(n-1)]); 
end

rmpath(path)