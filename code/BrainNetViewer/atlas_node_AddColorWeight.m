
NodeFile = '/data/joy/BBL/tutorials/exampleData/BrainNetVeiwer/BrainNet_GenCoord/ROIv_scale125.node';
NodeInfo = load(NodeFile);
% Add color/modularity information
Yeo_atlas = load('/data/joy/BBL/tutorials/exampleData/BrainNetVeiwer/BrainNet_GenCoord/Yeo_7system_in_Lausanne234.txt');
% Add weight information
Weight = rand(234, 1); % Here, I just generate it using random function. 

NodeInfo(:, 4) = Yeo_atlas;
NodeInfo(:, 5) = Weight;
save('/data/joy/BBL/tutorials/exampleData/BrainNetVeiwer/BrainNet_GenCoord/ROIv_scale125_Final.node', 'NodeInfo', '-ascii');



