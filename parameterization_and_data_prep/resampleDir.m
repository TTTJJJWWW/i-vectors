dirName = '/storage/dane/jgrzybowska/bazyaudio/T';
fsOut = 8000; % Hz
fLengthOut = 5; % seconds
justResample = 0;
folder_to_write = '/5s/';
mkdir([dirName folder_to_write]);

fList = ReadFileNames(dirName);
fN = length(fList);

for i = 1:fN
    fprintf('%d: ',i);
    [s, fs] = audioread(fList{i});
    sRes = resample(s, fsOut, fs);
      if justResample == 0
        [~,sResVAD] = removeframes(sRes,fsOut,0.5,0.1,0.02,0.01);
        nOut = fLengthOut*fsOut;
        f5s = vec2frames(sResVAD, nOut, 0.5*nOut);     % 0.5*nOut -> zakladkowanie 50%
        for j = 1:size(f5s,2)
          fprintf('%d ', j);
          audiowrite([dirName folder_to_write sprintf('%s%d.wav',strrep(fList{i}(length(dirName)+2:end),'.wav','-'),j)],f5s(:,j),fsOut);
       end
       fprintf('\n');
      else
          audiowrite([dirName folder_to_write fList{i}(length(dirName)+2:end)], sRes, fsOut);
      end
end