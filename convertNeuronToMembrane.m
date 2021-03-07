function [newBorderGT] = convertNeuronToMembrane(neuronGT, structuringElement, isECSFilled)
%CONVERTNEURONTOMEMBRANE convert 2D neuron ground truth image to membrane
%ground truth
%   Uses erosion and dilation to convert a 2D image of neuron ground truth
%   to a membrane ground truth with the specified structuring element, 
%   membrane pixel value, and ECS filling/no filling

    newBorderGT = uint8(imerode(neuronGT + 1, structuringElement) ~= imdilate(neuronGT + 1, structuringElement)); % Conversion to border GT

    
    % Fill in ECS if indicated
    if isECSFilled == "On"
        newBorderGT(neuronGT == 0) = 2;                    
    end
    
    newBorderGT(newBorderGT == 1) = 2;
    newBorderGT(newBorderGT == 0) = 1;
    
end

