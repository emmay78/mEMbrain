function [trainedNet] = deepLearningTraining(inputDirectory, labelDirectory, preTrainedNetDirectory, numEpochs, numClasses, networkName, advancedSettings)
%DEEPLEARNINGTRAINING Trains deep learning model in Train a Network feature
%   Based on training data in inputDirectory and labelDirectory, trains a
%   neural network that is either a UNET with specified UNET depth or a
%   imported network, with advanced settings as specified in
%   advancedSettings struct

if ~exist('preTrainedNet', 'var')
    preTrainedNetDirectory = [];
end

% Import training data and determine image size

inputDatastore = imageDatastore(inputDirectory);

inputSize = size(readimage(inputDatastore, 1));
netImageSize = [inputSize 1];

labelIDs = uint8(255*([1:numClasses]-1)/(numClasses-1));
classNames = strcat('label_', cellstr(num2str((1:numClasses)') ));

labelDatastore = pixelLabelDatastore(labelDirectory, classNames, labelIDs);

trainingDatastore = pixelLabelImageDatastore(inputDatastore, labelDatastore);

% Setup network for training, including hyperparameters

if ~isempty(preTrainedNetDirectory)
    netGraph = layerGraph(getfield(load(preTrainedNetDirectory), 'net')); % Assumes that preTrainedNetDirectory file points to .mat containing struct with field 'net'
else
    netGraph = unetLayers(netImageSize, numClasses, 'EncoderDepth', advancedSettings.netDepth);
end

% Split training and validation data

[train, validation, test] = dividerand(trainingDatastore.NumObservations, ...
    advancedSettings.trainingPercent, 1 - advancedSettings.trainingPercent, 0);

trainingData = partitionByIndex(trainingDatastore, train);
validationData = partitionByIndex(trainingDatastore, validation);

% Setup network training options

checkpointPath = pwd;

options = trainingOptions(advancedSettings.optimizer,...
    'InitialLearnRate', advancedSettings.learningRate,...
    'Shuffle', advancedSettings.shuffle,...
    'MaxEpochs', numEpochs,...
    'Verbose', advancedSettings.verbose,...
    'VerboseFrequency', 10,...
    'MiniBatchSize', 4,...
    'ValidationData', validationData,...
    'ValidationFrequency', 15000,...
    'CheckpointPath', checkpointPath,...
    'Plots', advancedSettings.plotTraining,...
    'LearnRateSchedule', advancedSettings.learnRateSchedule,...
    'LearnRateDropPeriod', 2,...
    'LearnRateDropFactor', advancedSettings.learnRateDropFactor);

[net, info] = trainNetwork(trainingData, netGraph, options);
trainedNet = layerGraph(net)    

end

