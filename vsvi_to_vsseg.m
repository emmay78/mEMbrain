function [] = vsvi_to_vsseg(miplevel, layernr, seglayer, annlayer, srcannlayer, ...
    x_init, x_end, y_init, y_end, z_init, z_end,...
    locationMethod, tileSize, threshold)

immediateflag = 0;
requestloadflag = 1;

vast = evalin('base','vast');
vast.setapilayersenabled(1)

if strcmp(locationMethod,'RANDOM')
    vinfo = vast.getinfo();
    size_x = double(vinfo.datasizex);
    size_y = double(vinfo.datasizey);
    size_z = double(vinfo.datasizez);

    if ~exist('i_init', 'var') || isempty(x_init)
        x_init = 0;
    end
    
    if ~exist('i_final', 'var') || isempty(x_end)
        x_end = size_x-1;
    end
    
    if ~exist('j_init', 'var') || isempty(y_init)
        y_init = 0;
    end
    
    if ~exist('j_final', 'var') || isempty(y_end)
        y_end = size_y-1;
    end
    
    if ~exist('z_init', 'var') || isempty(z_init)
        z_init = 0;
    end
    
    if ~exist('z_final', 'var') || isempty(z_end)
        z_end = size_z-1;
    end


    P0 = [x_init, y_init, z_init]
    P1 = [x_end, y_end, z_end]
    
    N = 300; % Sample 300 coordinates
    xx=randi([P0(1)+tileSize+1 P1(1)-tileSize-1], N, 1);
    yy=randi([P0(2)+tileSize+1 P1(2)-tileSize-1], N, 1);
    zz=randi([P0(3) P1(3)], N, 1);

elseif strcmp(locationMethod,'FromVSSANOOFILE')
    annlayer_sourceCoordinates = srcannlayer;
    
    vast.setselectedapilayernr(annlayer_sourceCoordinates)
    [aonodedatac, ~] = vast.getaonodedata();
    xx=aonodedatac(:,6);
    yy=aonodedatac(:,7);
    zz=aonodedatac(:,8);
    
    N = numel(xx);
end

W = ceil(tileSize/2)/2^miplevel;

for icoord=1:N
    coords = [xx(icoord) yy(icoord) zz(icoord)];

    [~] = vast.setselectedapilayernr(seglayer);
    J = vast.getsegimageRLEdecoded(miplevel,coords(1)-tileSize,coords(1)+tileSize-1,coords(2)-tileSize,coords(2)+tileSize-1,coords(3),coords(3),immediateflag,requestloadflag);
    
    while (J(:) > 0)
        coords(1)=randi([P0(1)+tileSize+1 P1(1)-tileSize-1],N,1);
        coords(2)=randi([P0(2)+tileSize+1 P1(2)-tileSize-1],N,1);
        coords(3)=randi([P0(3) P1(3)],N,1);
       
        J = vast.getsegimageRLEdecoded(miplevel,coords(1)-tileSize,coords(1)+tileSize-1,coords(2)-tileSize,coords(2)+tileSize-1,coords(3),coords(3),immediateflag,requestloadflag);
    end

    xx(icoord) = coords(1);
    yy(icoord) = coords(2);
    zz(icoord) = coords(3);

    [emimage,~] = vast.getemimage(layernr,miplevel,coords(1)-tileSize,coords(1)+tileSize-1,coords(2)-tileSize, coords(2)+tileSize-1,coords(3),coords(3),immediateflag,requestloadflag);

    K = zeros(size(emimage),'uint8');
    K(emimage<threshold)=1;
    K(emimage>=threshold)=2;

    I = zeros(size(emimage),'uint8');
    I(emimage>=threshold)=2;
%     I(:,[1 2 y_end-1 y_end]) = K(:,[1 2 end-1 end]);
%     I([1 2 end-1 end],:) = K([1 2 end-1 end],:);

    [~] = vast.setselectedapilayernr(seglayer)
    [~] = vast.setsegimageRLE(miplevel,coords(1)-W,coords(1)+W-1,coords(2)-W,coords(2)+W-1,coords(3),coords(3),I);

    [~] = vast.setselectedapilayernr(annlayer)
    vast.addaonode(coords(1),coords(2),coords(3));
    
end

end
