% This m-file gets additional data about speakers to be saved in a database.
% Saves database in a table in a .mat file ('_addData_corpusName.mat). First 
% column contains a cell array of files names (full names, e.g. 'file_id.wav'). 
% Next columns are gender (cell array of strings: 'x', 'f' or 'm'), age (vector 
% of doubles), age_class (vector of doubles).

clear;
path = '/storage/dane/jgrzybowska/bazyaudio/WWW/';
addpath(path);
files = dir([path '*.wav']);
N = size(files,1);

file_id = cell(N,1);
gender = cell(N,1);
age = zeros(N,1);

for i = 1:N
  file_id{i,1} = files(i).name;
  if files(i).name(5) == 'K', gender{i,1} = 'f';
  else if files(i).name(5) == 'M', gender{i,1} = 'm';
      end
  end
  age(i,1) = str2double(files(i).name(8:9));
end

age_class = createAgeClasses(gender, age);

T = table(file_id, gender, age, age_class, ... 
    'VariableNames',{'file_id','gender', 'age', 'age_class'});

save('_addData_WWW.mat','T');
rmpath(path);