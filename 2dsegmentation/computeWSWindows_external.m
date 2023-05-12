function vol_ws_cc=computeWSWindows_external(vol, window, overlap, removeMask)
% compatability 
% vloc_min_sup
% window = 2048;
% overlap = 256;
stopOnCoordinate = [];

% default, can be edit for different datasets 
alpha = 0.95; %  

debug = 0;
if debug == 1
    % example:
    stopOnCoordinate = [41500, 41000] % y/x
end

vol_ws1 = zeros(size(vol),'uint32');
mxID = uint32(0);

% compatability
%checker = false(size(vol));

t1=tic;
yi=0;
for ystart=1:window:size(vol,1)
    yi = yi + 1;
    
    if mod(yi,2)==0
        x0 = 1;
    else
        x0 = 1+window;
    end
    
    
    xi = mod(yi,2);
    
    ystart;
    for xstart=x0:2*window:size(vol,2)
        xi = xi + 1;
        
        xstartp = max(xstart-overlap,1);
        ystartp = max(ystart-overlap,1);
        xendp = min(xstart+window-1+overlap, size(vol,2));
        yendp = min(ystart+window-1+overlap, size(vol,1));
        
        % compatability
        %xend = min(xstart+window-1, size(vol,2));
        %yend = min(ystart+window-1, size(vol,1));
        
        patch = vol(ystartp:yendp,xstartp:xendp);
        
        patchedMask = removeMask(ystartp:yendp,xstartp:xendp);
        
        
        if debug==1 && ystartp <= stopOnCoordinate(1) && yendp >= stopOnCoordinate(1) && ...
                xstartp <= stopOnCoordinate(2) && xendp >= stopOnCoordinate(2)
            keyboard
        end
        
        
        if all(patchedMask,'all')
            % compatability
            %ws_patch = zeros(size(patch));
            continue
        else
            ws_patch=watershed(patch,8);
        end
        
        % compatability
        %ws_patch=ws_patch((ystart-ystartp)+1:end,(xstart-xstartp)+1:end);
        %box = true(size(patch,1)-(ystart-ystartp)-(yendp-yend), ...
        %    size(patch,2)-(xstart-xstartp)-(xendp-xend));
        %checker(ystart:ystart+size(box,1)-1,xstart:xstart+size(box,2)-1) = box;
        
        ws_patch_gl = uint32(ws_patch) + mxID;
        ws_patch_gl(ws_patch==0) = 0;
        
        
        %%%% for interior part remove boundaries that may have artifcats 
        xend=min(xstart+window-1,size(vol,2));
        yend=min(ystart+window-1,size(vol,1));
        left=floor(alpha*(xstart-xstartp));
        right=floor(alpha*(xendp-xend));
        up=floor(alpha*(ystart-ystartp));
        bottom=floor(alpha*(yendp-yend));
        ws_patch_gl(:,[1:1+left-1 end-right+1:end]) = 0;
        ws_patch_gl([1:1+up-1 end-bottom+1:end],:) = 0;
        
        if yi>1 && xi>1 && debug == 2
          
            keyboard
            
        end
        
        % compatability
        %assert(max(ws_patch_gl(:)) == 0 || ...
        %  max(vol_ws1(:)) <  min(ws_patch_gl(ws_patch_gl>0)) );
        
        %vol_ws1(ystartp:ystartp+size(ws_patch,1)-1,xstartp:xstartp+size(ws_patch,2)-1) ...
        %    = ws_patch_gl;
        %mxID = mxID + max(uint32(ws_patch(:)));
        
        wAdapt = vol_ws1(ystartp:ystartp+size(ws_patch,1)-1,xstartp:xstartp+size(ws_patch,2)-1);
        wAdapt(wAdapt==0) = ws_patch_gl(wAdapt==0);
        vol_ws1(ystartp:ystartp+size(ws_patch,1)-1,xstartp:xstartp+size(ws_patch,2)-1) = wAdapt;
        mxID = mxID + max(uint32(ws_patch(:)));
        
        
    end
end
toc(t1)

vol_ws2 = zeros(size(vol),'uint32');

t1=tic;
yi=0;
for ystart=1:window:size(vol,1)
    yi = yi + 1;
    
    if mod(yi,2)==0
        x0 = 1+window;
        
    else
        x0 = 1;
    end
    
    xi = mod(yi,2);
    
    ystart;
    for xstart=x0:2*window:size(vol,2)
        xi = xi + 1;
        
        xstartp = max(xstart-overlap,1);
        ystartp = max(ystart-overlap,1);
        xendp = min(xstart+window-1+overlap, size(vol,2));
        yendp = min(ystart+window-1+overlap, size(vol,1));
        
        patch = vol(ystartp:yendp,xstartp:xendp);
        
        
        if debug==1 && ystartp <= stopOnCoordinate(1) && yendp >= stopOnCoordinate(1) && ...
                xstartp <= stopOnCoordinate(2) && xendp >= stopOnCoordinate(2)
            keyboard
         end
        
        
        if isinf(min(patch(:)))
            % compatability
            %ws_patch = zeros(size(patch));
            continue
        else
            ws_patch=watershed(patch,8);
        end
        % compatability
        %ws_patch=ws_patch((ystart-ystartp)+1:end,(xstart-xstartp)+1:end);
        
        ws_patch_gl = uint32(ws_patch) + mxID;
        ws_patch_gl(ws_patch==0) = 0;
        
        %%%% for interior part remove boundaries that may have artifcats 
        xend=min(xstart+window-1,size(vol,2));
        yend=min(ystart+window-1,size(vol,1));
        left=floor(alpha*(xstart-xstartp));
        right=floor(alpha*(xendp-xend));
        up=floor(alpha*(ystart-ystartp));
        bottom=floor(alpha*(yendp-yend));
        ws_patch_gl(:,[1:1+left-1 end-right+1:end]) = 0;
        ws_patch_gl([1:1+up-1 end-bottom+1:end],:) = 0;
        
        % compatability
        %assert(max(ws_patch_gl(:)) == 0 || ...
        %  max(vol_ws1(:)) <  min(ws_patch_gl(ws_patch_gl>0)) );
        
        wAdapt = vol_ws2(ystartp:ystartp+size(ws_patch,1)-1,xstartp:xstartp+size(ws_patch,2)-1);
        wAdapt(wAdapt==0) = ws_patch_gl(wAdapt==0);
        vol_ws2(ystartp:ystartp+size(ws_patch,1)-1,xstartp:xstartp+size(ws_patch,2)-1) = wAdapt;
        mxID = mxID + max(uint32(ws_patch(:)));
        
        
        
    end
end
toc(t1)

t1=tic;
Q = imerode(vol_ws1>0 & vol_ws2,ones(3));
pairs = unique([vol_ws1(Q) vol_ws2(Q)],'rows');
G=graph(pairs(:,1),pairs(:,2),1,max(vol_ws2(:)));
cc = conncomp(G);
cc = [0, cc];
toc(t1)

 
t1=tic;
vol_ws_cc=zeros(size(vol_ws1),'uint32');

yi=0;
for ystart=1:window:size(vol,1)
    yi = yi + 1;
    
    xi = mod(yi,2);
    
    ystart;
    for xstart=1:window:size(vol,2)
        xi = xi + 1;
        
        % compatability
        %xstartp = max(xstart-overlap,1);
        %ystartp = max(ystart-overlap,1);
        %xendp = min(xstart+window-1+overlap, size(vol,2));
        %yendp = min(ystart+window-1+overlap, size(vol,1));
        xend = min(xstart+window-1, size(vol,2));
        yend = min(ystart+window-1, size(vol,1));
        
         if debug==1 && ystart <= stopOnCoordinate(1) && yend >= stopOnCoordinate(1) && ...
                xstart <= stopOnCoordinate(2) && xend >= stopOnCoordinate(2)
            keyboard
         end
        
        
        
        if mod(xi,2)~=0
            patch = vol_ws1(ystart:yend,xstart:xend);
            
        else
            patch = vol_ws2(ystart:yend,xstart:xend);
            
        end
        
        if max(patch(:)) > 0
            patch_cc = cc(patch+1);
        else
            continue
        end
        
        vol_ws_cc(ystart:yend,xstart:xend) = patch_cc;
        
        
    end
end
toc(t1)
 

if (0) %%% debug example
    rng(7)
    colorsuint32 = uint32([0, randperm(2^24-1)]);
    colorsuint = reshape(typecast(colorsuint32,'uint8'),4,[]);
    colors = permute(colorsuint(1:3,:), [2 1]);
    colors(1,:) = 0;
 
    %vol_ws=vol_ws2;
    %vol_ws(checker) = vol_ws1(checker);
    %vol_ws_cc = cc(vol_ws+1);
    % vol_ws1
    v=vol_ws_cc(40000:44000,40000:end);
    rgb = uint8(reshape(colors(v+1,:),[size(v) 3]));
    imwrite(rgb,'vol_ws_cc.png')
    
    v1=vol_ws1(32000:46000,36000:end);
    rgb = uint8(reshape(colors(v1+1,:),[size(v1) 3]));
    imwrite(rgb,'rgb_vol_ws1_v2.png')
    
    v2=vol_ws2(32000:46000,36000:end);
    rgb = uint8(reshape(colors(v2+1,:),[size(v2) 3]));
    imwrite(rgb,'rgb_vol_ws2_v2.png')
    
    v1_v2=vol_ws2(32000:46000,36000:end)==0 & vol_ws1(32000:46000,36000:end)==0 ;
    imwrite(v1_v2,'w1_w2_v2.png')
    
    
    rgb = uint8(reshape(colors(ws_patch_gl+1,:),[size(ws_patch_gl) 3]));
    imwrite(rgb,'ws_patch_gl.png')
    
    v1r = imresize(vol_ws1,1/4,'nearest');
    rgb = uint8(reshape(colors(v1r+1,:),[size(v1r) 3]));
    imwrite(rgb,'vol_ws1_rs.png')
end


