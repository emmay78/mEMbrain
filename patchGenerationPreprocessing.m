function [] = patchGenerationPreprocessing(inputImage, labelImage, inputName, labelName, inputPatchDirectory, labelPatchDirectory, patchDensity, patchSize, contrastCorrection, downsamplingFactor)
%PATCHGENERATIONPREPROCESSING Preprocesses input and label images before patch generation
%   Images are preprocessed, including resizing and coloring
%   per user specifications. They are then passed to the generatePatches 
%   function for patch generation.

% If requested by user, downsample the input image. If downsamplingFactor
% is not specified to 1 so imresize has no effect.

if isempty(downsamplingFactor)
    downsamplingFactor = 1;
end

if isempty(contrastCorrection)
    contrastCorrection = "none";
end

inputImage_resized = imresize(inputImage, 1/downsamplingFactor);
labelImage_resized = imresize(labelImage, 1/downsamplingFactor);

% If requested by user, the contrast of the input image is correct either
% by patch or for the entire image using CLAHE in the contrastCorrect
% function

if exist('contrastCorrection', 'var') && contrastCorrection ~= "none"
    if contrastCorrection == "patch"
        inputImage_resized = contrastCorrect(inputImage_resized, patchSize);
    else
        inputImage_resized = contrastCorrect(inputImage_resized);
    end
end

% Convert 3-dimensional labels into 1-dimensional labels

if (length(size(labelImage)) == 3)
    labelImage = unique_rgb(labelImage);
end

% Estimate the number of patches based on the given "patch density" (number
% of patches per megapixel) and the non-zero pixels in the given label image

numberOfPatches = round(sum(labelImage(:)>0)/((1024/downsamplingFactor)^2)*patchDensity);

% Pass preprocessed input image and related parameters to generatePatches,
% where the patches of the input-output pair will be saved to
% inputPatchDirectory and labelPatchDirectory

generatePatches(inputImage_resized, labelImage_resized, inputName, labelName, inputPatchDirectory, labelPatchDirectory, patchSize, numberOfPatches);

end


