% This m-file gets additional data about speakers to be saved in a database.
% Saves database in a table in a .mat file ('_addData_corpusName.mat). First 
% column contains a cell array of files names (full names, e.g. 'file_id.wav'). 
% Next columns are gender (cell array of strings: 'x', 'f' or 'm'), age (vector 
% of doubles), age_class (vector of doubles).

clear;
path = '/storage/dane/jgrzybowska/bazyaudio/RSR2015/infos';
addpath(path);
id=fopen('spkrinfo.lst');
str=textscan(id, '%s');

data = str{1,1}(14:end);
NSpeakers = size(data,1)/13;
file_id = cell(NSpeakers,1);
gender = cell(NSpeakers,1);
age = zeros(NSpeakers,1);
n=1;

for i = 1:NSpeakers
  file_id{i,1} = [data{n,1}(1:4) '.wav'];
  gender{i,1} = data{n+1,1}(1);
  age(i,1) = str2double(data{n+2,1});
  n=n+13;
end

age_class = createAgeClasses(gender, age);

T = table(file_id, gender, age, age_class, ... 
    'VariableNames',{'file_id','gender', 'age', 'age_class'});

T = cleanData(T);

save('_addData_RSR2015.mat','T');
fclose(id);
rmpath(path);