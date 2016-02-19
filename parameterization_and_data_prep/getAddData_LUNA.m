% This m-file gets additional data about speakers to be saved in a database.
% Saves database in a table in a .mat file ('_addData_corpusName.mat). First 
% column contains a cell array of files names (full names, e.g. 'file_id.wav'). 
% Next columns are gender (cell array of strings: 'x', 'f' or 'm'), age (vector 
% of doubles), age_class (vector of doubles).

clear;
path = '/storage/dane/jgrzybowska/bazyaudio/Nagrania_Luna/';
addpath(path);
files = dir([path '*.wav']);
N = size(files,1);

file_id = cell(N,1);
gender = cell(N,1);
age = zeros(N,1);
age_class = zeros(N,1);

for i = 1:N
  file_id{i,1} = files(i).name;
  if files(i).name(3) == 'M', gender{i,1} = 'm'; 
      if files(i).name(1) == '2' || files(i).name(1) == '3' || files(i).name(1) == '4',
          age_class(i,1) = 5;
      else
          age_class(i,1) = 7;
      end
  else if files(i).name(3) == 'K', gender{i,1} = 'f'; 
      if files(i).name(1) == '2' || files(i).name(1) == '3' || files(i).name(1) == '4',
          age_class(i,1) = 4;
      else
          age_class(i,1) = 6;
      end
      end
  end
  age(i,1) = 0;
end

T = table(file_id, gender, age, age_class, ... 
    'VariableNames',{'file_id','gender', 'age', 'age_class'});

save('_addData_LUNA.mat','T');
rmpath(path);