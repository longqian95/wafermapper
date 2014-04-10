

TPN = 'D:\LGNs1\HighResVolumes\RawMontages\QualityWithingLGNs1_01\'
writeTPN = 'D:\LGNs1\HighResVolumes\GatheredTiles\QualityWithingLGNs1_01\'
TPN = 'D:\LGNs1\HighResVolumes\RawMontages\HiRestWithFindMontage\'
writeTPN = 'D:\LGNs1\HighResVolumes\GatheredTiles\highResWithFIndMontage\'
TPN = 'D:\LGNs1\HighResVolumes\RawMontages\highRes_SurfAlign_01\'
writeTPN = 'D:\LGNs1\HighResVolumes\GatheredTiles\highRes_SurfAlign_01\'
if ~exist(writeTPN,'dir')
    mkdir(writeTPN);
end
%%
pickw = 'w007';
pickr = 1;
pickc = 1;


dTPN = dir(TPN); dTPN = dTPN(3:end);

listDir = {};
for i = 1:length(dTPN)
   if dTPN(i).isdir
       if sum(regexp(dTPN(i).name,pickw))
       listDir{length(listDir)+1} = dTPN(i).name;
       end
   end
end


secSum = 0;
for i = 1:length(listDir)
    wafDir = listDir{i}
    picks = wafDir(9:11);
    dWaf = dir([TPN wafDir]); dWaf = dWaf(3:end);
    getTile = sprintf('Tile_r%d-c%d_%s_sec%s.tif',pickr,pickc,pickw,picks)
    if exist([TPN wafDir '\' getTile],'file')
        [success, message]= copyfile([TPN wafDir '\' getTile], [writeTPN getTile]);
        
    end
end












