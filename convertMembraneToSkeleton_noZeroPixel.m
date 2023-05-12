function [skeletonGT] = convertMembraneToSkeleton_noZeroPixel(I, filterSize)
%CONVERTMEMBRANETOSKELETON convert 2D membrane ground truth image to
%2D skeleton ground truth
%   Uses bwskel to convert a 2D image of membrane ground truth to a
%   skeleton ground truth given a specified membrane border value

    % Find the non-membrane label (the most prevalent known pixel value)
    nonMemLabel = mode(I, 'all');
    
    % Find the membrane label (if setdiff returns an array of size 0, then
    % the GT has only two classes (no "don't know" pixel), so we set the
    % memLabel to 
    memLabel = setdiff(I, nonMemLabel);
    
    InonMem = bwareaopen(I == nonMemLabel,15,8);
    InonMem_sm = imfilter(InonMem, fspecial('gaussian',...
        [filterSize filterSize], 2)) > 0.5;
    
    Imem = bwareaopen(I == memLabel, 15, 8);
    
    Imem_sm = imfilter(Imem, fspecial('gaussian',...
        [filterSize filterSize], 2)) > 0.5;
    
    I1 = zeros(size(I),class(I));
    I1(Imem_sm) = memLabel;
    I1(InonMem_sm) = nonMemLabel;
    I1_med =  medfilt2(I1, [9 9]);
    I1(I1==0) = I1_med(I1 == 0); 
    
    try 
        I_skel = bwskel(I1 == nonMemLabel);
    catch
        keyboard
    end
    
    skeletonGT = zeros(size(I),class(I));
    skeletonGT(bwdist(I_skel)<5) = 1;
    
    figure; imshow(labeloverlay(double(I1==1), skeletonGT));
end

