% This m-file gets additional data about speakers to be saved in a database.
% Saves database in a table in a .mat file ('_addData_corpusName.mat). First 
% column contains a cell array of files names (full names, e.g. 'file_id.wav'). 
% Next columns are gender (cell array of strings: 'x', 'f' or 'm'), age (vector 
% of doubles), age_class (vector of doubles).

clear;
path = '/storage/dane/jgrzybowska/bazyaudio/Timit/TIMIT/DOC';
addpath(path);
id=fopen('SPKRINFO.TXT');
str=textscan(id, '%s', 'delimiter', 'whitespace');

data = str{1,1}(422:end);
NSpeakers = size(data,1);
file_id = cell(NSpeakers,1);
gender = cell(NSpeakers,1);
age = zeros(NSpeakers,1);

for i = 1:NSpeakers
  file_id{i,1} = [data{i,1}(1:4) '.wav'];
  gender{i,1} = lower(data{i,1}(7));
  age(i,1) = str2double(data{i,1}(24:25))-str2double(data{i,1}(34:35));
end

age_class = createAgeClasses(gender, age);

T = table(file_id, gender, age, age_class, ... 
    'VariableNames',{'file_id','gender', 'age', 'age_class'});

T = cleanData(T);

save('_addData_TIMIT.mat','T');
fclose(id);
rmpath(path);