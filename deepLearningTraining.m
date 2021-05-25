function [trainedNet] = deepLearningTraining(inputDirectory, labelDirectory, preTrainedNetDirectory, trainedNetDirectory, numEpochs, numClasses, networkName, saveFormat, advancedSettings)
%DEEPLEARNINGTRAINING Trains deep learning model in Train a Network feature
%   Based on training data in inputDirectory and labelDirectory, trains a
%   neural network that is either a UNET with specified UNET depth or a
%   imported network, with advanced settings as specified in
%   advancedSettings struct

if ~exist('preTrainedNetDirectory', 'var')
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
    advancedSettings.trainingPercent/100, 1 - advancedSettings.trainingPercent/100, 0);

trainingData = partitionByIndex(trainingDatastore, train);
validationData = partitionByIndex(trainingDatastore, validation);

% Setup network training options

checkpointPath = trainedNetDirectory;

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
trainedNet = layerGraph(net);
save(fullfile(trainedNetDirectory, strcat(networkName, '.', saveFormat)), 'net', 'info');
 
% Save mEMbrain_training.log file

headString = '===================================================';
titleString = 'mEMBRAIN Deep Learning Neural Network Training Log';
trainedPathString = strcat('Trained Network Path:', {' '}, fullfile(trainedNetDirectory, strcat(networkName, '.', saveFormat)));
inputDirString = strcat('Ground Truth Input Directory:', {' '}, inputDirectory);
labelDirString = strcat('Ground Truth Label Directory:', {' '}, labelDirectory);
baseNetworkString = strcat('Base Network (if any):', {' '}, preTrainedNetDirectory);
numEpochsString = strcat('# of Epochs:', {' '}, num2str(numEpochs));
numClassesString = strcat('# of Classes:', {' '}, num2str(numClasses));
netDepthString = strcat('UNET Network Depth:', {' '}, num2str(advancedSettings.netDepth));
shuffleString = strcat('Shuffle training data?:', {' '}, advancedSettings.shuffle);
initialLRString = strcat('Initial Learning Rate:', {' '}, num2str(advancedSettings.learningRate));
learnRateSchedString = strcat('Learning Rate Schedule?:', {' '}, num2str(advancedSettings.learnRateSchedule));
learnRateDropString = strcat('Learning Rate Drop (if any):', {' '}, num2str(advancedSettings.learnRateDropFactor));
solverString = strcat('Training optimizer/solver:', {' '}, advancedSettings.optimizer);

fileID = fopen(fullfile(trainedNetDirectory, strcat(networkName, '.log')), 'wt');
fprintf(fileID, '%s \r\n', headString, titleString, headString, trainedPathString{1},...
    inputDirString{1}, labelDirString{1}, baseNetworkString{1}, numEpochsString{1},...
    numClassesString{1}, netDepthString{1}, shuffleString{1}, initialLRString{1},...
    learnRateSchedString{1}, learnRateDropString{1}, solverString{1});
fclose(fileID);

end

