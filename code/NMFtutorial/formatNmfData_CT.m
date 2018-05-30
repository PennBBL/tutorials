clear all

numBases = 18;

%% read in NMF decomposition
cd(sprintf('/cbica/projects/pncNmf/NMFtutorial/results/NumBases%d/OPNMF',numBases))

load('ResultsExtractBases.mat')

% transpose so format is Nsub X NumComponents
C_t = C';

% assigning variable names
pre = sprintf('Ct_Nmf%dC',numBases);

varNames = {};
for k = 1:numBases
    varNames = [varNames; strcat([pre,num2str(k,'%d')])];
end

% convert to table so we can assign variable names
T = array2table(C_t,'VariableNames',varNames)

% writing table to .csv file 
writetable(T,sprintf('NmfResults%dBases_CT.csv',numBases),'Delimiter',',')


