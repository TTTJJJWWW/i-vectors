%% parametrization and data save to a database (_database_name.mat)

clear;

addData = load('_addData_aGender_5s.mat');
addData = addData.T;

path = '/storage/dane/jgrzybowska/bazyaudio/aGender/wavs2/5s/';

database = saveDataParameterization(path, 'aGender_5s', addData, 0);