function calculate_mfcc(path_to_wavs, corpusName, VAD, addData)

%path_to_wavs = '/storage/dane/jgrzybowska/bazyaudio/aGender/wavs2/';
%add_data = '_addData_aGender.mat';

addpath('/storage/dane/jgrzybowska/MATLAB/Voicebox')

if nargin>3,
    addData = load(addData);
    addData = addData.T;
else
    addData = table();
end

addpath(path_to_wavs)
files = dir([path_to_wavs '*.wav']);
N = size(files,1);
hamming = @(N)(0.54-0.46*cos(2*pi*[0:N-1].'/(N-1)));
p=0;

file_id = cell(N,1);
duration_sec = zeros(N,1);
MFCC_delta_cms = cell(N,1);

for i=1:N
    if i/N*100 >= p, 
        p = p+5; disp(['Parameterization ' num2str(round(i/N*100)) '%']); 
    end
  file_id{i,1} = files(i).name;
  try [y,Fs] = audioread(files(i).name);
  catch
      continue
  end
    if size(y,2) > 1, 
        y = mean(y,2); 
    end
    if Fs ~= 8000
        y = resample(y, 8000, Fs);
        Fs = 8000;
    end
  %y=(y-min(y))*(1-(-1))/(max(y)-min(y))+(-1);       % scale to [-1,1]  
  if VAD == 1; [~,y] = removeframes(y,Fs,0.5,0.1,0.02,0.01); end
  duration_sec(i,1) = length(y)/Fs;
  %MFCC_delta_cmvn1{i,1}=mfcc(y,Fs,20,10,0.97,hamming,1,1,[75 4000],28,20);
  % voicebox
  MFCC_delta_cms{i,1}=melcepst(y,Fs,'MtaEzdD', 19, 27, 0.02*Fs, 0.02*Fs/2, 0, 0.5); 
  MFCC_delta_cms{i,1} = MFCC_delta_cms{i,1}';
  MFCC_delta_cms{i,1} = cmvn(MFCC_delta_cms{i,1});
end

data = table(file_id, duration_sec, MFCC_delta_cms, ... 
    'VariableNames',{'file_id', 'duration_sec', 'MFCC_delta_cms'});

data = sortrows(data, 'file_id' ,'ascend');

if nargin>3, 
  addData = sortrows(addData, 1 ,'ascend');
  dataN = size(data,1);
  add_dataN = size(addData,1);

  p = 0;
  database = table();
  for i=1:dataN
    if i/dataN*100 >= p, 
      p = p+5; disp(['Saving data ' num2str(round(i/dataN*100)) '%']); 
    end
      for ii=1:add_dataN
        if isequal(data.file_id(i), addData{ii,1})
         database = [database; data(i,:) addData(ii,2:end)];
         break
        else if ii == add_dataN
         warning('No additional data saved for file %s', data.file_id{i})
            end
        end
      end
  end
  else
    database = data;
end

save(['_database_', corpusName, 'MFCC', num2str(size(MFCC_delta_cms{1,1},1)) , 'D.mat'], 'database')
summary(database)
rmpath(path_to_wavs)

rmpath('/storage/dane/jgrzybowska/MATLAB/Voicebox')

end