function [] = patchGenerationPreprocessing(inputImage, labelImage, inputPatchDirectory, labelPatchDirectory, numberOfClasses, patchDensity, patchSize, contrastCorrect, downsamplingFactor)
%PATCHGENERATIONPREPROCESSING Preprocesses input and label images before patch generation
%   Images are preprocessed, including resizing and coloring
%   per user specifications. They are then passed to the generatePatches 
%   function for patch generation.

% If requested by user, downsample the input image. If downsamplingFactor
% is not specified to 1 so imresize has no effect.

if ~exist('downsamplingFactor', 'var')
    downsamplingFactor = 1;
end

inputImage_resized = imresize(inputImage, 1/downsamplingFactor);

% If requested by user, the contrast of the input image is correct either
% by patch or for the entire image using CLAHE in the contrastCorrect
% function

if exist('contrastCorrect', 'var')
    if contrastCorrect == "patch"
        inputImage_corrected = contrastCorrect(inputImage_resized, patchSize);
    else
        inputImage_corrected = contrastCorrect(inputImage_resized);
    end
end

% Estimate the number of patches based on the given "patch density" (number
% of patches per megapixel) and the non-zero pixels in the given label image

numberOfPatches = round(sum(labelImage(:)>0)/((1024/downsamplingFactor)^2)*patchDensity);

generatePatches(inputImage_corrected, labelImage, inputPatchDirectory, labelPatchDirectory, patchSize, numberOfPatches);

end


