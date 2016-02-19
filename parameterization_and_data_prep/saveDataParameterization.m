%%  This function performs parameterization of wav files from a folder and 
%  saves parameters and other additional data to a table.
%   Input:
%       path_to_wavs (string) - Path to a folder with wav files.
%       corpus_name (string)  - Name of the corpus (string).
%       add_data (table)      - Data to be saved in a database, in columns 
%                               e.g. gender, age, age_class.
%                               First column has to contain a cell array
%                               of files names (e.g. 'file.wav').
%       VAD                   - Perform removeFrames or not, logical 0 or
%                               1, default 0.
%   Output:
%       database - table with parameters and other data (table)

function database = saveDataParameterization(path_to_wavs, ...
    corpus_name, add_data, VAD)

if nargin<3, add_data = table(); VAD = 0; end
if nargin<4, VAD = 0; end

addpath(path_to_wavs)
files = dir([path_to_wavs '*.wav']);
N = size(files,1);
hamming = @(N)(0.54-0.46*cos(2*pi*[0:N-1].'/(N-1)));
p=0;

file_id = cell(N,1);
timeStamp = cell(N,1);
duration_sec = zeros(N,1);
MFCC_delta_cms = cell(N,1);

for i=1:N
    if i/N*100 >= p, 
        p = p+5; disp(['Parameterization ' num2str(round(i/N*100)) '%']); 
    end
  file_id{i,1} = files(i).name;
  timeStamp{i,1} = files(i).date;
  [y,Fs] = audioread(files(i).name);
    if size(y,2) > 1, 
        y = mean(y,2); 
    end
    if Fs ~= 8000
        y = resample(y, 8000, Fs);
        Fs = 8000;
    end
  y=(y-min(y))*(1-(-1))/(max(y)-min(y))+(-1);       % scale to [-1,1]  
  if VAD == 1; [~,y] = removeframes(y,Fs,0.5,0.1,0.02,0.01); end
  duration_sec(i,1) = length(y)/Fs;
  MFCC_delta_cms{i,1}=mfcc(y,Fs,20,10,0.97,hamming,1,1,[75 4000],28,13);
end

data = table(file_id, timeStamp, duration_sec, MFCC_delta_cms, ... 
    'VariableNames',{'file_id','timeStamp', 'duration_sec', 'MFCC_delta_cms'});

data = sortrows(data, 'file_id' ,'ascend');

if nargin>2, 
  add_data = sortrows(add_data, 1 ,'ascend');
  dataN = size(data,1);
  add_dataN = size(add_data,1);

  p = 0;
  database = table();
  for i=1:dataN
    if i/dataN*100 >= p, 
      p = p+5; disp(['Saving data ' num2str(round(i/dataN*100)) '%']); 
    end
      for ii=1:add_dataN
        if isequal(data.file_id(i), add_data{ii,1})
         database = [database; data(i,:) add_data(ii,2:end)];
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

save(['_database_' corpus_name, '.mat'], 'database')
summary(database)
rmpath(path_to_wavs)

end