function [density_mat, density_peak_location_mat] = ...
    predict(net, path_predictions, path_probabilities, layernum, ...
    i_init, i_final, j_init, j_final, z_init, z_final, num_classes, mask, mipPrediction, vsvi_save)

if ~exist('mask','var')
    mask = [];
end

if ~exist('mipPrediction','var')
    mipPrediction = [];
end

overwrite = 0;

vast = evalin('base','vast');

vinfo = vast.getinfo();
size_x = double(vinfo.datasizex);
size_y = double(vinfo.datasizey);
size_z = double(vinfo.datasizez);

if isempty(mipPrediction)
    inStr = inputdlg('mip','mip');
    miplevel = str2double(inStr{1});
else
    miplevel = mipPrediction;
end

[x, y, z, res] = vast.getviewcoordinates()

askvastLoad = 1; %%% for vast to load/cache the image
layernr = layernum; %%% from which layer toread
getimmediatFlag = 0; %%% force fast to provide immedate answer

predPath = fullfile(path_predictions,sprintf('mip%d',miplevel))
probPath =  fullfile(path_probabilities,sprintf('mip%d',miplevel));
mkdir(predPath);
mkdir(probPath);

step = 1024;
patch_size = 1024;

if ~exist('i_init', 'var') || isempty(i_init)
    i_init = 0;
end

if ~exist('i_final', 'var') || isempty(i_final)
    i_final = size_x-1;
end

if ~exist('j_init', 'var') || isempty(j_init)
    j_init = 0;
end

if ~exist('j_final', 'var') || isempty(j_final)
    j_final = size_y-1;
end

if ~exist('z_init', 'var') || isempty(z_init)
    z_init = 0;
end

if ~exist('z_final', 'var') || isempty(z_final)
    z_final = size_z-1;
end

i_init = round(i_init./2.^miplevel);
j_init = round(j_init./2.^miplevel);
i_final = round(i_final./2.^miplevel);
j_final = round(j_final./2.^miplevel);
size_x_mip = floor(size_x./2.^miplevel);
size_y_mip = floor(size_y./2.^miplevel);

% initialize matrix for density maps
density_mat = zeros(ceil(size_x/patch_size), ceil(size_y/patch_size), size_z-1);
density_peak_location_mat = zeros(ceil(size_x/patch_size), ceil(size_y/patch_size), size_z-1, 2);

i_init = i_init - mod(i_init, 1024);
j_init = j_init - mod(j_init, 1024);

col_idx = i_init/1024-1;
pad_size = 64;
zstep = vinfo.cubesizez;

for i = i_init:step:i_final
    col_idx = col_idx+1;
    
    row_idx = j_init/1024-1;
    for j = j_init:step:j_final
        row_idx = row_idx+1;
            
        xstart = uint32(max(i-pad_size,0));
        ystart = uint32(max(j-pad_size,0));
        xend = uint32(min(i+patch_size-1+pad_size, size_x_mip-1));
        yend = uint32(min(j+patch_size-1+pad_size, size_y_mip-1));
        
        k = z_init;
        while k <= z_final
            
            ystartMask = max(floor((ystart-j_init)./(j_final-j_init)*(size(mask,1)-1)+1),1);
            xstartMask = max(floor((xstart-i_init)./(i_final-i_init)*(size(mask,2)-1)+1),1);
            yendMask = min(ceil((yend-j_init)./(j_final-j_init)*(size(mask,1)-1)+1),size(mask,1));
            xendMask = min(ceil((xend-i_init)./(i_final-i_init)*(size(mask,2)-1)+1),size(mask,2));
            
            subMask = mask(ystartMask:yendMask,xstartMask:xendMask,:);
            
            if ~isempty(mask) && ~any(subMask(:))
                k = k + zstep;
                continue
            end
            
            kend = min(k+zstep-1,z_final);
            
            if overwrite == 0
                sect_prob_dir = fullfile(probPath, sprintfc('Sect_%.6d', k:kend));
                prob_fname = fullfile(sect_prob_dir, sprintfc(['sect_%.6d_r' sprintf('%d',row_idx)  '_c' sprintf('%d',col_idx) '.png'],k:kend));
                if all(cellfun(@(x) exist(x,'file'), prob_fname))
                    k = k + zstep;
                    continue
                end
            end
            
            try
                [emimage, res]= vast.getemimage(layernr,miplevel,xstart,xend,ystart,yend,k,kend,getimmediatFlag,askvastLoad);
            catch
                keyboard
            end
            
            if isempty(emimage)
                continue;
            else 
                try 
                    entrp = entropy(emimage)
                catch
                    keyboard
                end
            end
            
            if entrp < 1
                k = k + zstep;
                continue
            end
            
            for ik=1:size(emimage,3)
                
                sect_pred_dir = fullfile(predPath, sprintf('Sect_%.6d', k+ik-1));
                sect_prob_dir = fullfile(probPath, sprintf('Sect_%.6d', k+ik-1));
                
                if ~exist(sect_pred_dir, 'dir')
                    mkdir(sect_pred_dir);
                    mkdir(sect_prob_dir);
                end
                
                emimage_ik = emimage(:,:,ik);
                
                if sum(emimage_ik(:)) == 0
                    continue
                end
                
                if entropy(emimage_ik) < 1
                    continue
                end
                
                prob_fname = fullfile(sect_prob_dir, sprintf('sect_%.6d_r%d_c%d.png',k+ik-1, row_idx, col_idx));
                
                if exist(prob_fname,'file') && overwrite == 0
                    continue
                end
                
                try
                    emimage_ik = padarray(emimage_ik,[double(ystart-(j-pad_size)), double(xstart-(i-pad_size))],0,'pre');
                    emimage_ik = padarray(emimage_ik,[double((j+patch_size-1+pad_size)-yend), double((i+patch_size-1+pad_size)-xend)],0,'post');
                    emimage_ik = adapthisteq(emimage_ik); % em_correction(emimage_ik, size(emimage_ik, 1));
                catch
                    keyboard
                end
                
                if isempty(emimage_ik)
                    keyboard
                end
                
                try
                    tic
                    [predictions,~,probabilities] = semanticseg(emimage_ik, net.net, 'ExecutionEnvironment','auto');
                    predictions = predictions(pad_size+1:end-pad_size,pad_size+1:end-pad_size);
                    probabilities = probabilities(pad_size+1:end-pad_size,pad_size+1:end-pad_size,:);
                    toc
                   
                    switch num_classes
                        case 2
                            prob_uint8 = uint8(probabilities(:, :, 1)*255);
                            prob_uint8 = prob_uint8 + 1;
                            imwrite(prob_uint8, prob_fname,'png')
                        case 3
                            prob_3channels = zeros(size(probabilities, 1), size(probabilities, 2), num_classes,'uint8');
                            prob_3channels(:, :, 1) = uint8(probabilities(:, :, 1)*255);
                            prob_3channels(:, :, 2) = uint8(probabilities(:, :, 2)*255);
                            prob_3channels(:, :, 3) = uint8(probabilities(:, :, 3)*255);
                            imwrite(prob_3channels,prob_fname,'png')
                            
                    end

                    imwrite((double(predictions)-1)*255/max(double(predictions(:))-1), fullfile(sect_pred_dir, sprintf('sect_%.6d_r%d_c%d.png',k+ik-1, row_idx, col_idx)),'png');
                catch
                    keyboard;
                end
            end
            
            k = k + zstep;
        end
    end
end

if vsvi_save
    new_file = fopen(fullfile(path_probabilities, "mEMbrain_autogenerated.vsvi"), "w")
    vsvi_lines = readlines("vsvi_template.txt")
    for line_idx = 1:length(vsvi_lines)
        line = vsvi_lines(line_idx)
        new_line = strrep(line, "PATH", path_probabilities);
        new_line = strrep(new_line, "TRGDATAX", num2str(size_x));
        new_line = strrep(new_line, "TRGDATAY", num2str(size_y));
        new_line = strrep(new_line, "TRGDATAZ", num2str(size_z));
        new_line = strrep(new_line, "VXSIZEX", num2str(vinfo.voxelsizex));
        new_line = strrep(new_line, "VXSIZEY", num2str(vinfo.voxelsizey));
        new_line = strrep(new_line, "VXSIZEZ", num2str(vinfo.voxelsizez));
        fprintf(new_file, "%s\n", new_line);
    end
    fclose(new_file);
end