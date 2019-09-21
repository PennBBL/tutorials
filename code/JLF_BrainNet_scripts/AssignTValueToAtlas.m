function AssignTValueToAtlas(Atlas_Path, SigRegionIndex, TValue, ResultantFile)
%
% Atlas_Path:
%      The full path of the atlas. Should be .nii format
%
% SigRegionIndex:
%      A vector of index of signficant regions.
%      For example, if regions 2 and 5 in the altas are signficant, this 
%      should be vector [2, 5]
%
% TValue:
%      T value of significant regions. Should be with the same order as
%      variable 'SigRegionIndex'
%
% ResultantFile:
%      The path of the output file.
%      i.e., /data/jux/output.nii
%
% For example: AssignTValueToAtlas('/data/jux/aal.nii', [3,5], [0.2,0.1], '/data/jux/T_all.nii');
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Written by Zaixu Cui: zaixucui@gmail.com; Zaixu.Cui@PennMedicine.upenn.edu
%

hdr = spm_vol(Atlas_Path);
data = spm_read_vols(hdr);
AllIndex = unique(data);
AllIndex = AllIndex(2:end); % Remove 0
NonSigIndex = setdiff(AllIndex, SigRegionIndex);
for i = 1:length(NonSigIndex)
    data(find(data == NonSigIndex(i))) = 0;
end
for i = 1:length(SigRegionIndex)
    data(find(data == SigRegionIndex(i))) = TValue(i);
end

hdr.fname = ResultantFile; 
hdr.dt = [16 0];
spm_write_vol(hdr, data);
