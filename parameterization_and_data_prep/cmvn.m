function nowa_macierz_mfcc=cmvn(macierz_mfcc)

srednie=mean(macierz_mfcc,2);
odch = std(macierz_mfcc,0,2);

[~, y]=size(macierz_mfcc);

for ii=1:y
    nowa_macierz_mfcc(:,ii)=(macierz_mfcc(:,ii)-srednie)./odch;
end
    