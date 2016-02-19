function nowa_macierz_mfcc=cms(macierz_mfcc)

srednie=mean(macierz_mfcc,2);

[~, y]=size(macierz_mfcc);

for ii=1:y
    nowa_macierz_mfcc(:,ii)=macierz_mfcc(:,ii)-srednie;
end
    