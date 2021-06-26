function [] = vsvitovsseg(miplevel, layernr, seglayer, sourceannlayer, annlayer,...
    locationMethod, tileSize, threshold, UPDATESEG, immediateflag, requestloadflag)

% layernr=0;  % membrane image layer 
% seglayer=1; % segmentation layer for input/output
% annlayer=2; % annotation layer for skeletons 

info = vast.getinfo;
vast.setapilayersenabled(1)

%locationMethod = 'RADNOM'
% locationMethod = 'FromVSSANOOFILE'
 
% UPDATE_SEG = 1; % whether to update the segmentation layer. This should be done when mappign the final GT. It's not needed when search for potential errors (but useful to allow this temporarily just to see the extent of the frames before selection is made) 
ExportOutcometoPngs = 0;

if strcmp(locationMethod,'RANDOM')
 
    %%%% GT5
    P0 = [15000, 25000, 0] %   % start point of BOX for sampling XYZ
    P1 = [30000, 50000, 108] %  % endpoint
    
    N = 300;
    xx=randi([P0(1)+tileSize+1 P1(1)-tileSize-1],N,1);
    yy=randi([P0(2)+tileSize+1 P1(2)-tileSize-1],N,1);
    zz=randi([P0(3)     P1(3)],N,1);
elseif strcmp(locationMethod,'FromVSSANOOFILE')

    annlayer_sourceCoordinates=3 ; % should be the annotation layer with the inputs - should not be the annotation layer where the new nodes are written 
    
    vast.setselectedapilayernr(annlayer_sourceCoordinates)
    [aonodedatac, res] = vast.getaonodedata();
    xx=aonodedatac(:,6);
    yy=aonodedatac(:,7);
    zz=aonodedatac(:,8);
    
    N = numel(xx);
end

% th = 150 % for GT5
%[aonodedatac, res] = vast.getaonodedata();
for icoord=1:N %size(aonodedatac,1)
    %coords = aonodedatac(icoord, 6:8);
    coords = [xx(icoord) yy(icoord) zz(icoord)];
    
    %%% check if vsseg already has color in that location so we don't
    %%% overwright there
    res=vast.setselectedapilayernr(seglayer)
    J = vast.getsegimageRLEdecoded(miplevel,coords(1)-tileSize,coords(1)+tileSize-1,coords(2)-tileSize,coords(2)+tileSize-1,coords(3),coords(3),immediateflag,requestloadflag);
    
    while(J(:)) > 0
        
        coords(1)=randi([P0(1)+tileSize+1 P1(1)-tileSize-1],N,1);
        coords(2)=randi([P0(2)+tileSize+1 P1(2)-tileSize-1],N,1);
        coords(3)=randi([P0(3)     P1(3)],N,1);
        
        
        J = vast.getsegimageRLEdecoded(miplevel,coords(1)-tileSize,coords(1)+tileSize-1,coords(2)-tileSize,coords(2)+tileSize-1,coords(3),coords(3),immediateflag,requestloadflag);
        
    end
    xx(icoord) = coords(1);
    yy(icoord) = coords(2);
    zz(icoord) = coords(3);
    
    if UPDATE_SEG
        [emimage,res] = vast.getemimage(layernr,miplevel,coords(1)-tileSize,coords(1)+tileSize-1,coords(2)-tileSize, coords(2)+tileSize-1,coords(3),coords(3),immediateflag,requestloadflag);

        I = emimage;
        % keyboard

        K = zeros(size(emimage),'uint8');
        K(emimage<threshold)=1;
        K(emimage>=threshold)=2;

        I = zeros(size(emimage),'uint8');
        I(emimage>=threshold)=2;
        I(:,[1 2 end-1 end]) = K(:,[1 2 end-1 end]);
        I([1 2 end-1 end],:) = K([1 2 end-1 end],:);

        res=vast.setselectedapilayernr(seglayer)
        res = vast.setsegimageRLE(miplevel,coords(1)-W,coords(1)+W-1,coords(2)-W,coords(2)+W-1,coords(3),coords(3),I);
    end
    
    res=vast.setselectedapilayernr(annlayer)
    vast.addaonode(coords(1),coords(2),coords(3));
    
end

end
