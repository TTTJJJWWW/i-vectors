clear;
path = '/storage/dane/jgrzybowska/bazyaudio/uzywammojegoglosujakoklucza';
addpath(path);

data = load('mowcy_plec_wiek.mat');
data = data.mowcy_plec_wiek;

N = size(data,1);
file_id = cell(N,1);
gender = cell(N,1);
age = zeros(N,1);

for i = 1:N
  file_id{i,1} = [data{i,1} '.wav'];
  if data{i,2} == 'K', gender{i,1} = 'f';
  else if data{i,2} == 'M', gender{i,1} = 'm';
      end
  end
  if isa(data{i,3},'double'), age(i,1) = data{i,3};
  else age(i,1) = 0;
  end
end


age_class = createAgeClasses(gender, age);

T = table(file_id, gender, age, age_class, ... 
    'VariableNames',{'file_id','gender', 'age', 'age_class'});

T = cleanData(T);

save('_addData_uzywam.mat','T');
rmpath(path);
