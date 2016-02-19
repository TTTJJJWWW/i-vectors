% This function removes files with uncomplete age and gender data.
% Disable/modify this function for different analysis, e.g. gender recognition.

function T = cleanData(T)

NSpeakers = size(T,1);

toDelete = T.age_class == 0 | isnan(T.age_class) | T.age == 0 | ... 
    isnan(T.age) | ~(strcmp(T.gender, repmat({'f'},[NSpeakers 1])) | ...
    strcmp(T.gender, repmat({'m'},[NSpeakers 1])) | ...
    strcmp(T.gender, repmat({'x'},[NSpeakers 1])));

T(toDelete,:) = [];
summary(T);
if sum(toDelete) > 0
    warning('%d file(s) removed from database because of missing data.', sum(toDelete));
end


end