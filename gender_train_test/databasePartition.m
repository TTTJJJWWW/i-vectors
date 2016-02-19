function [ FOLDS ] = databasePartition(database,k)
%Creates random partition of data into K folds.
%Each fold contains same proportion of each database
%Each fold contains same proportion of each class (gender)

classes = unique(database.gender);
NClass =  size(unique(database.gender),1);
corpus_names = unique(database.corpus_id);
NCopr = size(unique(database.corpus_id),1);
FOLDS = [];

for i = 1:NCopr
  rows1 = zeros(size(database,1),1);
  rows2 = zeros(size(database,1),1);
  for n = 1:size(database,1)
    rows1(n) = strcmp(database.corpus_id{n}, corpus_names{i});
  end
  for ii = 1:NClass
    for n = 1:size(database,1)
    rows2(n) = strcmp(database.gender{n}, classes{ii});
    end
    rows = rows1 & rows2;
    strcmp(database.corpus_id{n}, corpus_names{i});
    currentDatabase = database(logical(rows),:);
    if ~isempty(currentDatabase)
      cv_idx = crossvalind('Kfold', size(currentDatabase,1), k);
      FOLDS = [FOLDS; cv_idx];
    end
  end
end
end

