% Get addData (gender, age, age class) from database files. Saves addData
% to a table. M-file created for several utternaces for one speaker 
% (e.g. 5 seconds frames).

clear;

path = '/storage/dane/jgrzybowska/bazyaudio/CPR/5s/';
data = load('_database_CPR.mat');
data = data.database;

addpath(path);
files = dir([path '*.wav']);
N = size(files,1);

file_id = cell(N,1);
gender = cell(N,1);
age = zeros(N,1);
age_class = zeros(N,1);

for i = 1:N
file_id{i,1} = files(i).name;
    for j = 1:size(data,1)
        loName = files(i).name;
        shName = strsplit(data.file_id{j},'.');
        shName = shName{1};
          if strfind(loName, shName)
              gender{i,1} = data.gender{j};
              age(i,1) = data.age(j);
              age_class(i,1) = data.age_class(j);
              break
          end
    end
fprintf('%d%s%d',i ,'/', N);
fprintf('\n');
end

T = table(file_id, gender, age, age_class, ... 
    'VariableNames',{'file_id','gender', 'age', 'age_class'});

%T = cleanData(T);

save('_addData_CPR_5s.mat','T');
rmpath(path);