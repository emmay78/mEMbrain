function [predictions] = deepLearningPredict(inputImage,network)
%DEEPLEARNINGPREDICT based on a trained network, make predictions for
%inputImage
%   Uses semanticseg to make predictions based on a given trained network
%   and input image

[prediction, ~, probabilityMap] = semanticseg(inputImage, network, ...
    'OutputType', 'uint8');

prediction = 255 - (double(prediction)-1)*255;
probabilityMap = probabilityMap(:,:,1);

predictionWithInput = labeloverlay(inputImage, prediction);
probabilityWithInput = imfuse(inputImage, probabilityMap);

predictions.prediction = prediction;
predictions.probability = probabilityMap;
predictions.predictionWithInput = predictionWithInput;
predictions.probabilityWithInput = probabilityWithInput;

end

