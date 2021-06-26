function [layers] = getVASTLayers()
%GETVASTLAYERS Gets names of layers open in VAST

[nroflayers, res] = vast.getnroflayers()

layers = [];

if res == 1
   for i = 1:nroflayers
       [linfo res] = vast.getlayerinfo(i);
       layers = [layers linfo.name];
   end
end

end

