function [predictions] = deepLearningPredict(inputImage,network)
%DEEPLEARNINGPREDICT based on a trained network, make predictions for
%inputImage
%   Uses semanticseg to make predictions based on a given trained network
%   and input image

% NOTE: the training of network has to have happened on multiple of 32 px *
% 32 px. 
size_image = size(inputImage);
inputImage = padarray(inputImage,32*ceil(size_image/32)-size_image,'symmetric','post');

[prediction, ~, probabilityMap] = semanticseg(inputImage, network, ...
    'OutputType', 'uint8');

inputImage=inputImage(1:size_image(1),1:size_image(2));
prediction=prediction(1:size_image(1),1:size_image(2));
probabilityMap=probabilityMap(1:size_image(1),1:size_image(2),:);

prediction = 255 - (double(prediction)-1)*255;
probabilityMap = probabilityMap(:,:,1);

predictionWithInput = labeloverlay(inputImage, prediction);
probabilityWithInput = imfuse(inputImage, probabilityMap);

predictions.prediction = prediction;
predictions.probability = probabilityMap;
predictions.predictionWithInput = predictionWithInput;
predictions.probabilityWithInput = probabilityWithInput;
end

