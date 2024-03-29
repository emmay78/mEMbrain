function inputImage = contrastCorrect(inputImage, patchSize)
%CONTRASTCORRECTION correct contrast with CLAHE
%   corrects contrast of input image (EM) using CLAHE either by patch or
%   for the entire image

dimensions = size(inputImage);

if ~exist('patchSize', 'var')
    patchSize = dimensions;
elseif numel(patchSize) == 1
    patchSize = [patchSize patchSize];
end

for i = 1:patchSize(1):dimensions(1)-1
    for j = 1:patchSize(2):dimensions(2)-1
        
        end_i = min(dimensions(1), i + patchSize(i) - 1);
        end_j = min(dimensions(2), j + patchSize(j) - 1);
        
        try
            inputImage(i:end_i, j:end_j) = adapthisteq(inputImage(i:end_i, j:end_j));
        catch
            keyboard
        end
    end
end

