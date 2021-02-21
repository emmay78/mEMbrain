function [skeletonGT] = convertMembraneToSkeleton_withZeroPixel(I, filterSize)
%CONVERTMEMBRANETOSKELETON convert 2D membrane ground truth image to
%2D skeleton ground truth
%   Uses bwskel to convert a 2D image of membrane ground truth to a
%   skeleton ground truth given a specified membrane border value

    % Find the non-membrane label (the most prevalent known pixel value)
    nonMemLabel = mode(I(I~=0));
    
    % Find the membrane label (if setdiff returns an array of size 0, then
    % the GT has only two classes (no "don't know" pixel), so we set the
    % memLabel to 
    memLabel = setdiff(I, [0 nonMemLabel]);
    
    InonMem = bwareaopen(I == nonMemLabel,15,8);
    InonMem_sm = imfilter(InonMem, fspecial('gaussian',...
        [filterSize filterSize], 2)) > 0.5;
    
%     try
        Imem = bwareaopen(I == memLabel, 15, 8);
%     catch
%         keyboard
%     end
    
    Imem_sm = imfilter(Imem, fspecial('gaussian',...
        [filterSize filterSize], 2)) > 0.5;
    
    I1 = zeros(size(I),class(I));
    I1(Imem_sm) = 1;
    I1(InonMem_sm) = nonMemLabel;
    I1_med =  medfilt2(I1, [9 9]);
    I1(I1==0) = I1_med(I1 == 0); 
    
    try 
        I_skel = bwskel(I1 == nonMemLabel);
    catch
        keyboard
    end
    
    skeletonGT = zeros(size(I),class(I));
    skeletonGT(I1 ~= 0) = 1;
    skeletonGT(bwdist(I_skel)<5) = 2;
    
    figure; imshow(labeloverlay(double(I1==1), skeletonGT));
end

