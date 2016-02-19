%% Merge data. To merge data, all databases must have the same variable names.

clear

database1 = load('_database_aGender_5s.mat'); %15661 wiek
database1 = database1.database;
database1(:,size(database1,2)+1) = {'aGender'};
disp(1)

database2 = load('_database_CPR_5s.mat'); %14013 nie ma wieku
database2 = database2.database;
database2(:,size(database2,2)+1) = {'CPR'};
disp(2)

database3 = load('_database_LUNA_5s.mat'); %495 nie ma wieku
database3 = database3.database;
database3(:,size(database3,2)+1) = {'LUNA'};
disp(3)

database4 = load('_database_RSR2015_5s.mat'); %6169 wiek
database4 = database4.database;
database4(:,size(database4,2)+1) = {'RSR2015'};
disp(4)

database5 = load('_database_TIMIT_5s.mat'); %4758 wiek
database5 = database5.database;
database5(:,size(database5,2)+1) = {'TIMIT'};
disp(5)

database6 = load('_database_uzywam_5s.mat'); %870 wiek
database6 = database6.database;
database6(:,size(database6,2)+1) = {'uzywam'};
disp(6)

database7 = load('_database_WWW_5s.mat'); %129 wiek
database7 = database7.database;
database7(:,size(database7,2)+1) = {'WWW'};
disp(7)

database = [database1; database2; database3; database4; database5; database6; database7];
database.Properties.VariableNames{8} = 'corpus_id';
summary(database)

%database_age = [database1; database4; database5; database6; database7];
%database_age.Properties.VariableNames{8} = 'corpus_id';

save('__database_all_5s.mat', 'database')