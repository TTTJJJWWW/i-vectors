% chooses data from '__database_all.mat' file and save to a new file
%clear
%load('__database_all_5s.mat');

%% SETTINGS
max_secs = 6;                  % max seconds of a wav file
min_secs = 2;
no_kids = 0;
only_cpr = 0;

%%
rows1 = database.duration_sec < max_secs & database.duration_sec >= min_secs;

if only_cpr == 1
rows3 = zeros(size(database,1),1);
for i = 1:size(database,1)
  rows3(i) = isequal(database.corpus_id{i},'CPR');
end
rows1 = rows1 & rows3;
end
        
if no_kids == 1
rows2 = zeros(size(database,1),1);
for i = 1:size(database,1)
  rows2(i) = database.gender{i} ~= 'x';
end
rows = rows1 & rows2;
else
    rows = rows1;
end

new_database = database(rows,:);
disp(['New database size (# of speakers): ', num2str(size(new_database,1)) ...
    ' (', num2str(size(new_database,1)/size(database,1)*100), '%)' ]);

subplot(2,2,1); [y] = histogram(new_database.duration_sec); 
title('Histogram duration [sec]')
subplot(2,2,2); [y] = histogram(new_database.age_class); 
title('Histogram age class')

[newNamesGen,~,ng] = unique(new_database.gender);
[NamesGen,~,g] = unique(database.gender);
new_gen = zeros(max(ng),1);
gen = zeros(max(g),1);
for i = 1:max(ng)
  new_gen(i) = sum(ng==i);
end
for i = 1:max(g)
  gen(i) = sum(g==i);
end
if size(new_gen,1)<3; new_gen = [new_gen; 0]; end %if there are no kids, kids = 0
subplot(2,2,3); [y] = bar(new_gen); set(gca, 'XTickLabel', newNamesGen); 
title('Bar plot gender')
if no_kids == 1,  disp(['% of data left (gender): ', num2str((y.YData(1:2)./gen(1:2)')*100)]);
  else disp(['% of data left (gender): ', num2str((y.YData./gen')*100)]);
end

[NewNamesCorp,~,nc] = unique(new_database.corpus_id);
[NamesCorp,~,c] = unique(database.corpus_id);
new_corp = zeros(max(nc),1);
corp = zeros(max(c),1);
for i = 1:max(nc)
  new_corp(i) = sum(nc==i);
end
for i = 1:max(c)
  corp(i) = sum(c==i);
end
subplot(2,2,4); [y] = bar(new_corp); set(gca, 'XTickLabel', NewNamesCorp); 
title('Bar plot corpus')
if length(y.YData) == length(corp)
    disp(['% of data left (corpus): ', num2str((y.YData./corp')*100)]);
end

%save(['__database_all_min' num2str(min_secs) 'max' num2str(max_secs) 'secs.mat'], 'new_database');
