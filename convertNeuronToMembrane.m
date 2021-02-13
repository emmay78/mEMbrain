function [newBorderGT,outputArg2] = convertNeuronToMembrane(neuronGT, structuringElement, borderValue, isECSFilled)
%CONVERTNEURONTOMEMBRANE convert 2D neuron ground truth image to membrane
%ground truth
%   Uses erosion and dilation to convert a 2D image of neuron ground truth
%   to a membrane ground truth with the specified structuring element, 
%   membrane pixel value, and ECS filling/no filling

    newBorderGT = imerode(neuronGT, structuringElement) ~= imdilate(neuronGT, structuringElement); % Conversion to border GT

    % Fill in ECS if indicated
    if isECSFilled == "On"
        newBorderGT(grayNeuronGT == 0) = 1;                    
    end

    switch borderValue
        case 0
            newBorderGT = ~newBorderGT;
        otherwise
            % Do nothing; border value is already 1.
    end
end

