clear;
path = '/storage/dane/jgrzybowska/bazyaudio/RSR2015/passwdsBases';
% passwd_folder/speaker_folder/recordings_wav(9)
% example: .../passwdBases/002/f001/f001_01_002.wav
path_to_write = '/storage/dane/jgrzybowska/bazyaudio/RSR2015/merged';
addpath(genpath(path));

passwd_folders = dir(path);
passwd_folders = passwd_folders(3:end);
y_matrix = cell(30,300);          % 300 speakers

for i=1:size(passwd_folders,1)
  passwd_folder = [path '/' passwd_folders(i).name];
  speakers = dir(passwd_folder);
  speakers = speakers(3:end);
    for n=1:size(speakers,1)
      wav_folder_path_array = [passwd_folder '/' speakers(n).name];
      wav_path = dir(wav_folder_path_array);
      wav_path = wav_path(3);
      [y,fs] = audioread(wav_path.name);
      y_matrix{i,n} = y;
    end
  disp(['Passwords saved: ' num2str(i) '/30']); 
end
%%
for n=1:size(speakers,1)
 merged_y = 0;
  for i=1:size(passwd_folders,1)
    merged_y = [merged_y; y_matrix{i,n}];
  end
  audiowrite([path_to_write '/' speakers(n).name '.wav'],merged_y,fs);
  disp(['Audio files saved: ' num2str(n) '/300']); 
end
  
rmpath(path);