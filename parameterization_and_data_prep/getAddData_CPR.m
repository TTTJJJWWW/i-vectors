clear
load('_old_database_CPR.mat');

new_gen=cell(size(database,1),1);

for i = 1:size(database,1)
  name = database.file_id(i);
  letter = name{1,1}(26);
  if name{1,1}(27) == '1', letter = 'x';
  else if letter == 'k', letter = 'f';
      end
  end
  new_gen{i,1} = letter;
end

tabl=table(new_gen);
database.gender = new_gen;
database.gender{1871} = 'm';
database(832,:) = [];
database(1011,:) = [];
database(2731,:) = [];
database(2924,:) = [];
database(236,:) = [];
database = sortrows(database,'age_class','ascend');

save('_database_CPR.mat', 'database');