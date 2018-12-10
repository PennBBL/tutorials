function SetColormap(TValue, ColorMap_Matrix, ResultantFile)
%
% TValue: 
%        Vector of T values to be visualized
%
% Colormap_Matrix:
%        Colormap to be used. For example: autumn, winter, jet, etc. 
%
  % ResultantFile:
%        .txt file with color information
  %        For example: /data/jux/colormap.txt
%
  % For example: SetColormap([0.2, 0.1], autumn, '/data/jux/color.txt'); 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
  % Written by Zaixu Cui: zaixucui@gmail.com; Zaixu.Cui@PennMedicine.upenn.edu
%

  MaxValue = max(TValue);
MinValue = min(TValue);
WholeRange = MaxValue - MinValue;
ColorMap_Final = zeros(length(TValue), 3);
[ColorQuantity, ~] = size(ColorMap_Matrix);
for i = 1:length(TValue)
    %i
	  Range_I = TValue(i) - MinValue;
    if Range_I ~= 0
      Ratio = Range_I / WholeRange;
ColorIndex = round(ColorQuantity * Ratio);
      if ColorIndex == 0
	ColorIndex = 1;
      end
      else
	ColorIndex = 1;
    end
    disp(ColorQuantity * Ratio);
disp(ColorIndex);
ColorMap_Final(i, :) = ColorMap_Matrix(ColorIndex, :);   
end
save(ResultantFile, 'ColorMap_Final', '-ascii');
