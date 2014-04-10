function[focusPosition] = smartTileFocus(StartingMagForAF, IsPerformAutoStig, StartingMagForAS, focOptions)

%% focus position is returned as XY
%% Retrieve necessary info
global GuiGlobalsStruct;

ImageHeightInPixels = 100;
ImageWidthInPixels = 100;
DwellTimeInMicroseconds = 0.2;
FOV = GuiGlobalsStruct.MontageParameters.TileFOV_microns;

AFscanRate = GuiGlobalsStruct.MontageParameters.AutofunctionScanrate;

if exist(GuiGlobalsStruct.TempImagesDirectory,'dir')
    FileName = [GuiGlobalsStruct.TempImagesDirectory '\tempFoc.tif']
else
    FileName = 'C:\temp\temFoc.tif';
end

s = FOV/ImageHeightInPixels/1000000; %scale meters per pixel


sm = GuiGlobalsStruct.MyCZEMAPIClass;
StartingMagForAF =15000;
StartingMagForAS = 15000;

startScanRot = sm.Get_ReturnTypeSingle('AP_SCANROTATION');

CurrentWorkingDistance =sm.Get_ReturnTypeSingle('AP_WD');
startStigX =sm.Get_ReturnTypeSingle('AP_STIG_X');
startStigY =sm.Get_ReturnTypeSingle('AP_STIG_Y');

stage_x = sm.Get_ReturnTypeSingle('AP_STAGE_AT_X');
stage_y = sm.Get_ReturnTypeSingle('AP_STAGE_AT_Y'); 
stage_z = GuiGlobalsStruct.MyCZEMAPIClass.Get_ReturnTypeSingle('AP_STAGE_AT_Z');
stage_t = GuiGlobalsStruct.MyCZEMAPIClass.Get_ReturnTypeSingle('AP_STAGE_AT_T');
stage_r = GuiGlobalsStruct.MyCZEMAPIClass.Get_ReturnTypeSingle('AP_STAGE_AT_R');
stage_m = GuiGlobalsStruct.MyCZEMAPIClass.Get_ReturnTypeSingle('AP_STAGE_AT_M');

%%Take overview image

sm.Set_PassedTypeSingle('AP_SCANROTATION',0);

sm.Fibics_WriteFOV(FOV);
%Wait for image to be acquired
sm.Fibics_AcquireImage(ImageWidthInPixels,ImageHeightInPixels,DwellTimeInMicroseconds,FileName);
while(sm.Fibics_IsBusy)
    pause(.01); %1
end

%Wait for file to be written
IsReadOK = false;
while ~IsReadOK
    IsReadOK = true;
    try
        I = imread(FileName);
    catch MyException
        IsReadOK = false;
        pause(0.1);
    end
end


%%find signal

horiz = abs(I(:,1:end-1) - I(:,2:end));
vert = abs(I(1:end-1,:) - I(2:end,:));
difI = I;
difI(1:end-1,:) = difI(1:end-1,:)+vert;
difI(:,1:end-1) = difI(:,1:end-1)+horiz;

difI(difI>250) = 0;

focKern = ones(3,5);
focKern = focKern/sum(focKern(:));
fI= conv2(double(difI),focKern,'same');


%image(fI),pause(.01)

[y x] = find(fI == max(fI(:)),1);

yshift = y - ImageHeightInPixels/2
xshift = x - ImageHeightInPixels/2

%% move stage to signal position
pause(.01)

focusPosition = [stage_x - xshift * s stage_y + yshift * s];
sm.MoveStage(focusPosition(1),focusPosition(2),stage_z,stage_t,stage_r,stage_m);
while(strcmp(GuiGlobalsStruct.MyCZEMAPIClass.Get_ReturnTypeString('DP_STAGE_IS'),'Busy'))
    pause(.01)
end

wmBackLash
%% Start Autofocus

IsNeedToReleaseFromFibics = 0;
if IsNeedToReleaseFromFibics
    %*** START: This sequence is desigend to release the SEM from Fibics control
    sm.Execute('CMD_AUTO_FOCUS_FINE');
    pause(0.5);
    sm.Execute('CMD_ABORT_AUTO');
    while ~strcmp('Idle',sm.Get_ReturnTypeString('DP_AUTO_FUNCTION'))
    pause(0.02);
    end
    sm.Set_PassedTypeSingle('AP_WD',CurrentWorkingDistance);
    pause(0.1);
    %*** END
end


sm.Set_PassedTypeSingle('AP_Mag',StartingMagForAF);

%Temporary hard code settings
sm.Set_PassedTypeSingle('DP_AutoFunction_ScanRate',AFscanRate);
sm.Set_PassedTypeSingle('DP_IMAGE_STORE',2)

%%LongPauseForStability
pause(5);

sm.Execute('CMD_AUTO_FOCUS_FINE');

pause(0.5);
disp('Auto Focusing...');
while ~strcmp('Idle',sm.Get_ReturnTypeString('DP_AUTO_FUNCTION'))
    pause(0.02);
end
pause(0.01);
ResultWD =sm.Get_ReturnTypeSingle('AP_WD');
ResultWD1 = ResultWD*1000;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% RS Add
ResultStigX =sm.Get_ReturnTypeSingle('AP_STIG_X');
ResultStigY =sm.Get_ReturnTypeSingle('AP_STIG_Y');

if IsPerformAutoStig
    %*** Auto stig
    %%%%%%%%%%%%%%%
    for repeatStig = 1:3
        sm.Set_PassedTypeSingle('AP_Mag',StartingMagForAS / repeatStig);
        
        %Temporary hard code settings
        sm.Set_PassedTypeSingle('AP_Mag',20000 / repeatStig);
        sm.Set_PassedTypeSingle('DP_AutoFunction_ScanRate',AFscanRate);
        sm.Set_PassedTypeSingle('DP_IMAGE_STORE',2)
        pause(0.01);
        
        
        %LogFile_WriteLine('Starting autostig');
        sm.Execute('CMD_AUTO_STIG');
        pause(0.5);
        
        %%%%%%%%%%%
        
        disp('Auto Stig...');
        while ~strcmp('Idle',sm.Get_ReturnTypeString('DP_AUTO_FUNCTION'))
            pause(.1);
        end
        pause(0.1);
        ResultStigX1 =sm.Get_ReturnTypeSingle('AP_STIG_X')
        ResultStigY1 =sm.Get_ReturnTypeSingle('AP_STIG_Y')
        stig_difference_X = abs(ResultStigX1 - ResultStigX);
        stig_difference_Y = abs(ResultStigY1 - ResultStigY);
        if (stig_difference_X < 1) & (stig_difference_Y < 1)
            break % break out of repeating stig
        else
            'Repeating stig'
            %Reset Stig Values
            sm.Set_PassedTypeSingle('AP_STIG_X',startStigX);  %GuiGlobalsStruct.StigX_AtAcquitionStart);
            sm.Set_PassedTypeSingle('AP_STIG_Y',startStigY);  %GuiGlobalsStruct.StigY_AtAcquitionStart);
        end
        
    end %repeat Stig
    
    %*** Auto focusP
    %%%%%%%%%%%%%%%%%%%%%
    sm.Set_PassedTypeSingle('AP_Mag',StartingMagForAF);
    pause(0.1);
    
    
    sm.Set_PassedTypeSingle('DP_AutoFunction_ScanRate',AFscanRate);
    sm.Set_PassedTypeSingle('DP_IMAGE_STORE',2)
    
    sm.Execute('CMD_AUTO_FOCUS_FINE');
    pause(0.5);
    disp('Auto Focusing...');
    while ~strcmp('Idle',sm.Get_ReturnTypeString('DP_AUTO_FUNCTION'))
        pause(.1);
    end
    pause(0.1);
    
    
    ResultWD =sm.Get_ReturnTypeSingle('AP_WD');
    
    
    sm.Set_PassedTypeSingle('DP_AutoFunction_ScanRate',AFscanRate);
    sm.Set_PassedTypeSingle('DP_IMAGE_STORE',1)
    
    
    AutoWorkingDistance =sm.Get_ReturnTypeSingle('AP_WD');
    if (abs(AutoWorkingDistance - CurrentWorkingDistance)*1000)>1.5
        
        sm.Set_PassedTypeSingle('AP_WD', GuiGlobalsStruct.WD_AtAcquitionStart );
        sm.Set_PassedTypeSingle('AP_STIG_X',GuiGlobalsStruct.StigX_AtAcquitionStart);
        sm.Set_PassedTypeSingle('AP_STIG_Y',GuiGlobalsStruct.StigY_AtAcquitionStart);
        pause(.1)
    end
    
end %end Autofocus AutoStig autofocus

%% Return to original settings

sm.Set_PassedTypeSingle('AP_SCANROTATION',startScanRot);
sm.MoveStage(stage_x ,stage_y ,stage_z,stage_t,stage_r,stage_m);
while(strcmp(GuiGlobalsStruct.MyCZEMAPIClass.Get_ReturnTypeString('DP_STAGE_IS'),'Busy'))
    pause(.01)
end
wmBackLash

%% Refocus 
    if focOptions.IsDoQualCheck
        focOptions.IsDoQualCheck
        offsetX = [0 50]/1000000;
        offsetY = [0 0 ]/1000000;
        StageX = GuiGlobalsStruct.MyCZEMAPIClass.Get_ReturnTypeSingle('AP_STAGE_AT_X');
        StageY = GuiGlobalsStruct.MyCZEMAPIClass.Get_ReturnTypeSingle('AP_STAGE_AT_Y');
        stage_z = GuiGlobalsStruct.MyCZEMAPIClass.Get_ReturnTypeSingle('AP_STAGE_AT_Z');
        stage_t = GuiGlobalsStruct.MyCZEMAPIClass.Get_ReturnTypeSingle('AP_STAGE_AT_T');
        stage_r = GuiGlobalsStruct.MyCZEMAPIClass.Get_ReturnTypeSingle('AP_STAGE_AT_R');
        stage_m = GuiGlobalsStruct.MyCZEMAPIClass.Get_ReturnTypeSingle('AP_STAGE_AT_M');
        
        focOptions.IsDoQualCheck = false;
        
        for o = 1:length(offsetX)
            [q] = takeFocusImage(focOptions);
            LogFile_WriteLine(sprintf('Quality check registered %0.5g.',q.quality))
            
            
            
            if q.quality <= focOptions.QualityThreshold %if bad
                'Image failed quality check'
                LogFile_WriteLine(sprintf('!!!!! Autofocus failed to reach threshold %0.5g.',focOptions.QualityThreshold))
                
                %%Move over
                
                GuiGlobalsStruct.MyCZEMAPIClass.MoveStage(StageX + offsetX(o),StageY + offsetY(o),stage_z,stage_t,stage_r,stage_m);
                while(strcmp(GuiGlobalsStruct.MyCZEMAPIClass.Get_ReturnTypeString('DP_STAGE_IS'),'Busy'))
                    pause(.02)
                end
                wmBackLash
                
                GuiGlobalsStruct.MyCZEMAPIClass.Set_PassedTypeSingle('AP_WD', GuiGlobalsStruct.WD_AtAcquitionStart );
                GuiGlobalsStruct.MyCZEMAPIClass.Set_PassedTypeSingle('AP_STIG_X',GuiGlobalsStruct.StigX_AtAcquitionStart);
                GuiGlobalsStruct.MyCZEMAPIClass.Set_PassedTypeSingle('AP_STIG_Y',GuiGlobalsStruct.StigY_AtAcquitionStart);
                pause(.1)
                
                pause(0.1);
                'try new focus'
                
                Perform_AF_or_AFASAF(StartingMagForAF, IsPerformAutoStig, StartingMagForAS, focOptions);
                
            else %if quality ok
                break
            end
        end %repeat refocus
        
        GuiGlobalsStruct.MyCZEMAPIClass.MoveStage(StageX,StageY,stage_z,stage_t,stage_r,stage_m);
        while(strcmp(GuiGlobalsStruct.MyCZEMAPIClass.Get_ReturnTypeString('DP_STAGE_IS'),'Busy'))
            pause(.02)
        end
        wmBackLash
    end

    
    
    

