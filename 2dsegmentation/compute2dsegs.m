function compute2dsegs(membranePath,mip,sections,outFolder,reduceMin,crop,ds)
%%% mEMbrain 2D instance segmentation.
%%% membranePath, path to the VAST compatible membrane probability folder
%%% mip, mip level (0,1,....)
%%% sections, zero-indexed
%%% outFolder, path for the output instance segmentation 
%%% reduceMin, the parameter for the H transform in imhmin(vol,reduceMin).
%%% Larger values mean larger seeds by greater breakage of tunnels between local minima.
%%% Crop, how much to crop from the sides of the space in mip0 coordinates 

%%% Default is to run using overlapping windows to reduce memory usage.
sparse_prob = 1;


ds_membrane = 2;

DEBUG = 0;
sectionStopper = 0;

if (0)
  
       
    %%%% Example 
    sections = [0,1,2, 100, 1000]; % sections to run on
    sectionTime=tic;  
    reduce = 0.05;
    ds = 1;
    crop = 0;
    mip=1; %%% membranes wil be read at this mip level
    compute2dsegs( ...
        {'./../membrane/pathWithMembranes/'}, ...
        mip,   sections, '2dseg-Net_DesiredOutputName',reduce,crop,ds);
    sectionTime_elapsed=toc(sectionTime);
    
    
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


outFolder = sprintf('%s_%g_ds%d_cr%d',outFolder,reduceMin,ds,crop);

overSegmentation = 0; % for compatibility with earlier versions

out = fullfile('./../2dseg',outFolder);


fmt = 'png' %%% read

patternTiles_read = 'sect_%06d_r%d_c%d' %%%

%%% sections
patternSection_read = 'Sect_%06d';
 
%%% mip zero tiling: column and row Max values. Comptabile with the default
%%% in mEMbrain where each tiles is 1024x1024 pixels. In this example the
%%% space is tiled by an 102x82 grid of tiles.
colmin = 0;
colmax = 82-1;
rowmin = 0;
rowmax = 102-1;

tileSize = [1024 1024];

%%% mip tiling;
mipcolmin = floor(colmin/2^mip);
mipcolmax = ceil(colmax/2^mip);
miprowmin = floor(rowmin/2^mip);
miprowmax = ceil(rowmax/2^mip);

mipMemPath = fullfile(membranePath, sprintf('mip%d',mip));

rng(7) % for reproducibility

colorsuint32 = uint32([0, randperm(2^24-1)]);
colorsuint = reshape(typecast(colorsuint32,'uint8'),4,[]);
colors = permute(colorsuint(1:3,:), [2 1]);
colors(1,:) = 0;

%%% default seeting ('nosmooth') indicate that membranes are not smoothed
%%% prior to watershed
smooth='nosmooth'; %'smooth'

outMipPath = fullfile(out, sprintf('mip%d_%s_notiles',mip,smooth));
mkdir(outMipPath);

outMipTilePath =  fullfile(out, sprintf('mip%d',mip));
mkdir(outMipTilePath)

outNextMipTilePath =  fullfile(out, sprintf('mip%d',mip+1));
mkdir(outNextMipTilePath)

%%% In this example we let MATLAB manage the distribution with a usage of 12 workers. 
Nworkers = 12;
 
parfor (section_index = 1:numel(sections), Nworkers)   %(section_index = 1:numel(sections), opts)        
    for ipause=1:30 
        pause(0.05)
        sprintf('.................... %d:%d ------.........',Nworkers,section_index); 
    end
    
    sectionID = sections(section_index)
    sectionPath = fullfile(mipMemPath, sprintf(patternSection_read,sectionID));
    
    if DEBUG && sectionID >= sectionStopper
        keyboard
    end
    
    
    sectionProb_cell = cell(1,numel(sectionPath));
    for imembPath=1:numel(sectionPath)
        sectionProb_cell{imembPath} = readSection(sectionPath{imembPath},mipcolmin,mipcolmax,miprowmin,miprowmax,crop, ...
            tileSize,patternTiles_read,sectionID,fmt);
    end
    sectionProbMax = max(cat(3,sectionProb_cell{:}),[],3);
    sectionProbMin = min(cat(3,sectionProb_cell{:}),[],3);
    sectionProb = uint8(single(sectionProbMax)*0.7+single(sectionProbMin)*0.3);
    
    outSectionPath = fullfile(outMipPath, sprintf(patternSection_read,sectionID));
    mkdir(outSectionPath);
    
    
    'done tiling'
    
    %%% some datasets have different probability maps which will reqcuire
    %%% to flip the membranes. 
    % sectionProb = 255-sectionProb;
    

    
    if strcmp(smooth,'smooth')
        vloc_s = double(imfilter(sectionProb,fspecial('gaussian',[13 13],1)))/255;
        'done filtering'
    else
        vloc_s = double(sectionProb)/255;
    end
    
    
    if crop > 0
        'cropping'
        tic
        vloc_s_crop = vloc_s(crop+1:end-crop,crop+1:end-crop);
        toc
        'croped'
        
    else
        'copying'
        tic
        vloc_s_crop = vloc_s;
        toc
        'copied'
    end
    

    
    if overSegmentation
        
        % option is removed in current versions. 
   
    else
 
    
        'computing imhmin...'
        tic;
        if sparse_prob
            'computing imhmin...'
            window = 4096;
            overlap = 256;
            vloc_min_sup=computeMinWindows(vloc_s_crop, window, overlap,reduceMin);
            
        else
            
            vloc_min_sup= ...
                imhmin(vloc_s_crop,reduceMin,8);
            
        end
        toc
        'done imhmin'
        
     
        tic;
        removeMask = vloc_s_crop>0.95;
        toc
        'mask computed'
        
        
        %%% Defaults. Should be edited for different systems (memory, cpu divisions) 
        window = 4096;
        overlap = 512;
   
        'computing watershed'
        t1=tic;
        g=computeWSWindows_external(vloc_min_sup, window, overlap, removeMask);
        toc(t1);
        'watershed computed'
        
        
       
        %%% default parameters, Can be edited for different datasets
        t1=tic
        'removing high probabiliy border from watershed...'
        g(vloc_s_crop>0.71 | isinf(vloc_min_sup)) = 0; 
        'done'
        toc(t1)
        
        ug = setdiff(g,0);
        if ~isempty(ug)
            tic; H=histcounts(g,[ug; inf]); toc;
            'done histcounts'
            g(ismember(g,ug(H<70)))=0; % was 50 before jan5
        end
    end
   
    if crop == 0
        g_full = g;
    else
        % copying cropped part'
        tic
        g_full = zeros(size(vloc_s),class(g));
        g_full(crop+1:end-crop,crop+1:end-crop) = g;
        toc
        'cropped part copied'
    end
    
    tic
    if ds == 1
        g_ds = g_full;
    elseif ds == 2
        g_ds = g_full(1:2:end,1:2:end);
    elseif ds == 4
        g_ds = g_full(1:4:end,1:4:end);
    end
    toc
   
    
    % required if the composite membranes are needed for later computation
    t1=tic;
    imwrite(sectionProb(1:ds_membrane:end,1:ds_membrane:end),fullfile(outSectionPath,'./memb.png'));
    toc(t1)
    'saved membrane'

    
    %%% break into tiles for visualization in VAST as image layer.
    %%% this will map the IDs into unique random RGB colors, just for visualization
    %%% purposes when max ID is larger than 2^24, and for analysis if less
    %%% than 2^24 objects.
    
     
    sectionFolder = fullfile(outMipTilePath,sprintf('Sect_%06d',sectionID));
    mkdir(sectionFolder);
     
    
    t_tiling=tic;
    yi=0;
    for ystart=1:tileSize(1):size(g_full,1)
        yi
        xi = 0;
        for xstart=1:tileSize(2):size(g_full,2)
            xi;
            tile = zeros([tileSize 3],'uint8');
            yend = min(ystart+tileSize(1)-1,size(g_full,1));
            xend = min(xstart+tileSize(2)-1,size(g_full,2));
            
            
            
            objTile = uint8(reshape(colors(mod(g_full(ystart:yend,xstart:xend), ...
                size(colors,1))+1,:),[yend-ystart+1 ,xend-xstart+1 3]));
            
          
            
            
            tile(1:size(objTile,1),1:size(objTile,2),:)=objTile;
            
            if sum(tile(:)) == 0
                xi = xi + 1;
                continue
            end
            
            tilepath=fullfile(sectionFolder,sprintf('sect_%06d_r%d_c%d.png',sectionID,yi,xi));
            imwrite(tile,tilepath,'png');
            xi = xi + 1;
        end
        yi = yi + 1;
    end
    toc(t_tiling)
    
    %%%% tiling next mip level
    sectionFolder = fullfile(outNextMipTilePath,sprintf('Sect_%06d',sectionID));
    mkdir(sectionFolder);
    
    g_ds2=g_ds(1:2:end,1:2:end);
    
    % for compatability
    %g_ds2_color = uint8(reshape(colors(mod(g_ds2, ...
    %            size(colors,1))+1,:),[size(g_ds2) 3]));
      
    t_tiling=tic;
    yi=0;
    for ystart=1:tileSize(1):size(g_ds2,1)
        yi
        xi = 0;
        for xstart=1:tileSize(2):size(g_ds2,2)
            xi;
            tile = zeros([tileSize 3],'uint8');
            yend = min(ystart+tileSize(1)-1,size(g_ds2,1));
            xend = min(xstart+tileSize(2)-1,size(g_ds2,2));
            
            
            
            objTile = uint8(reshape(colors(mod(g_ds2(ystart:yend,xstart:xend), ...
                size(colors,1))+1,:),[yend-ystart+1 ,xend-xstart+1 3]));
            
 
            
            tile(1:size(objTile,1),1:size(objTile,2),:)=objTile;
            
            if sum(tile(:)) == 0
                xi = xi + 1;
                continue
            end
            
            tilepath=fullfile(sectionFolder,sprintf('sect_%06d_r%d_c%d.png',sectionID,yi,xi));
            imwrite(tile,tilepath,'png');
            xi = xi + 1;
        end
        yi = yi + 1;
    end
    toc(t_tiling)
    
    
    
end

function sectionProb = readSection(sectionPath,mipcolmin,mipcolmax,miprowmin,miprowmax,crop, ...
    tileSize,patternTiles_read,sectionID,fmt)

sectionProb = 255*ones((miprowmax+1)*tileSize(1),(mipcolmax+1)*tileSize(1),'uint8');

%%% read section
for col=mipcolmin:mipcolmax
    col;
    for row=miprowmin:miprowmax
        tilename = fullfile(sectionPath,sprintf([patternTiles_read '.' fmt],sectionID,row,col));
        
        if ~exist(tilename,'file')
            continue
        end
        
        if (row+1)*tileSize(1) < crop || (col+1)*tileSize(2) < crop ...
                || row*tileSize(1)+1 > size(sectionProb,1) - crop ...
                || col*tileSize(2)+1 > size(sectionProb,2) - crop
            continue
        end
        
        I=imread(tilename);
        
        sectionProb(row*tileSize(1)+1:(row+1)*tileSize(1), ...
            col*tileSize(2)+1:(col+1)*tileSize(2)) = I;
        
    end
end

function vol_hmin=computeMinWindows(vol, window, overlap,reduceMin)


vol_hmin = zeros(size(vol),class(vol));


for ystart=1:window:size(vol,1)
    
    
    for xstart=1:window:size(vol,2)
        
        xstartp = max(xstart-overlap,1);
        ystartp = max(ystart-overlap,1);
        xendp = min(xstart+window-1+overlap, size(vol,2));
        yendp = min(ystart+window-1+overlap, size(vol,1));
        
        patch = vol(ystartp:yendp,xstartp:xendp);
        
        mn = min(patch(:));
        if max(patch(:))==mn
            imhmin_patch = mn;
        else
            imhmin_patch=imhmin(patch,reduceMin,8);
        end
        imhmin_patch=imhmin_patch((ystart-ystartp)+1:end,(xstart-xstartp)+1:end);
        
        vol_hmin(ystart:ystart+size(imhmin_patch,1)-1,xstart:xstart+size(imhmin_patch,2)-1) ...
            = imhmin_patch;
        
    end
end





