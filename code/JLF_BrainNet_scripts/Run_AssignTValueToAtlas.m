%Assigns the significant t-values to the JLF atlas for input into BrainNet Viewer.

%Specify the full path to the atlas. Should be .nii format.
Atlas_Path = '/data/joy/BBL/tutorials/code/BrainNetViewer/JLF_BrainNet/JLF_atlas/mniJLF_LabelsWithWM.nii';

%Load the .csv file with the significant t-values and index numbers.
SigRegions = csvread('/data/joy/BBL/tutorials/code/BrainNetViewer/JLF_BrainNet/subjectData/JLFvol_signifROIs_mood.csv');

%Define a vector of index numbers for the significant regions.
SigRegionIndex = SigRegions(:,end);

%Define a vector of t values for the significant regions.
TValue = SigRegions(:,1,:);

%Specify the path of the output file.
ResultantFile = '/data/joy/BBL/tutorials/code/BrainNetViewer/JLF_BrainNet/images/JLFvol_signifROIs_mood.nii';

%Run the AssignTValueToAtlas function.
AssignTValueToAtlas(Atlas_Path, SigRegionIndex, TValue, ResultantFile)
