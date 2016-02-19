% This function creates a vector of double values indicating age class:
% 1 - children (age )
% 2 - young women
% 3 - young men
% 4 - adult women
% 5 - adult men
% 6 - old women
% 7 - old men
% Inputs are cell array of strings indicating gender ('x', 'f', 'm') and
% colun vector of doubles with age. Those inputs has to be the same size!

function age_class = createAgeClasses (gender, age)

if ~isequal(size(gender,1), size(age,1))
    warning('Gender and Age variables have to have the same size!')
else
    N = size(gender,1);
end

age_class = zeros(N,1);

for i=1:N
  if gender{i} == 'x' && age(i) <= 14 && age(i) ~= 0, age_class(i,1) = 1;
    else if gender{i} == 'f' && age(i) <= 24 && age(i) ~= 0, age_class(i,1) = 2;
      else if gender{i} == 'm' && age(i) <= 24 && age(i) ~= 0, age_class(i,1) = 3;
        else if gender{i} == 'f' && age(i) <= 54 && age(i) ~= 0, age_class(i,1) = 4;
          else if gender{i} == 'm' && age(i) <= 54 && age(i) ~= 0, age_class(i,1) = 5;
            else if gender{i} == 'f' && age(i) > 54 && age(i) ~= 0, age_class(i,1) = 6;
              else if gender{i} == 'm' && age(i) > 54 && age(i) ~= 0, age_class(i,1) = 7;
                  else age_class(i,1) = 0;
                  end
                end
              end
            end
          end
        end
  end

end

end