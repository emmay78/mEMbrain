function out = unique_rgb(in)

out = permute(double(in(:,:,3,:)) +...
    double(in(:,:,2,:))*256 + double(in(:,:,1,:))*256^2,[1 2 4 3]);


