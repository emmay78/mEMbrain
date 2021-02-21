function [skeletonGT] = convertMembraneToSkeleton(I, memValue, filterSize)
%CONVERTMEMBRANETOSKELETON convert 2D membrane ground truth image to
%2D skeleton ground truth
%   Uses bwskel to convert a 2D image of membrane ground truth to a
%   skeleton ground truth given a specified membrane border value

    nonMem = mode(I(I~=memValue));
    
    InonMem = bwareaopen(I==nonMem,15,8);
    InonMem_sm = imfilter(InonMem,fspecial('gaussian',[5 5],2))>0.5;
    
    try
     Imem = bwareaopen(I==memValue,15,8);
    catch
        keyboard
    end
    Imem_sm = imfilter(Imem,fspecial('gaussian',[5 5],2))>0.5;
    
    I1 = zeros(size(I),class(I));
    I1(Imem_sm) = 1;
    I1(InonMem_sm) = nonMem;
    I1_med =  medfilt2(I1,[9 9]);
    I1(I1==0) = I1_med(I1==0); 
    try 
        Isk = bwskel(I1==nonMem);
    catch
        keyboard
    end
    skeletonGT = zeros(size(I),class(I));
    skeletonGT(I1~=nonMem) = 1;
    skeletonGT(bwdist(Isk)<5) = 2;
    
%     figure; imshow(labeloverlay(double(I1==1), J));
end

