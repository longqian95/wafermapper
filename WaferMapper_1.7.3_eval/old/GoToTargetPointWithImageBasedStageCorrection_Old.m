%GoToTargetPointWithImageBasedStageCorrection

disp('In GoToTargetPointWithImageBasedStageCorrection');

LabelStr = GuiGlobalsStruct.MontageTarget.LabelStr;

%determine WaferNameIndex
WaferNameIndex = 0;
for i = 1:length(GuiGlobalsStruct.ListOfWaferNames)
    WaferName = GuiGlobalsStruct.ListOfWaferNames{i};
    WaferDirName = sprintf('%s\\%s',...
        GuiGlobalsStruct.UTSLDirectory, WaferName);
    
    
    if strcmp(GuiGlobalsStruct.WaferDirectory, WaferDirName)
        WaferNameIndex = i;
    end
    
end

WaferName = GuiGlobalsStruct.ListOfWaferNames{WaferNameIndex};
WaferName
%Determine SectionIndex
SectionIndex = str2num(LabelStr);

MySection = GuiGlobalsStruct.AlignedTargetList.WaferArray(WaferNameIndex).SectionArray(SectionIndex);
MySection


GuiGlobalsStruct.MontageTarget.MicronsPerPixel = MySection.SectionOveriewInfo.FOV_microns/MySection.SectionOveriewInfo.ImageWidthInPixels;
    GuiGlobalsStruct.MontageTarget.StageX_Meters_CenterOriginalOverview = MySection.SectionOveriewInfo.StageX_Meters;
    GuiGlobalsStruct.MontageTarget.StageY_Meters_CenterOriginalOverview = MySection.SectionOveriewInfo.StageY_Meters;
    GuiGlobalsStruct.MontageTarget.OverviewImageWidthInPixels = MySection.SectionOveriewInfo.ImageWidthInPixels;
    GuiGlobalsStruct.MontageTarget.OverviewImageHeightInPixels = MySection.SectionOveriewInfo.ImageHeightInPixels;
    
    GuiGlobalsStruct.MontageTarget.Alignment_r_offset = MySection.AlignmentParameters.r_offset;
    GuiGlobalsStruct.MontageTarget.Alignment_c_offset = MySection.AlignmentParameters.c_offset;
    GuiGlobalsStruct.MontageTarget.Alignment_AngleOffsetInDegrees = MySection.AlignmentParameters.AngleOffsetInDegrees;
    GuiGlobalsStruct.MontageTarget.LabelStr = MySection.LabelStr;
    
    
    
    
    
    
    %First get target point coords in pixels relative to center of image
    y_pixels = -( GuiGlobalsStruct.MontageTarget.r - floor(GuiGlobalsStruct.MontageTarget.OverviewImageHeightInPixels/2) );
    x_pixels = GuiGlobalsStruct.MontageTarget.c - floor(GuiGlobalsStruct.MontageTarget.OverviewImageWidthInPixels/2);
    
    %Then apply a rotation of this
    theta_rad = (pi/180)*GuiGlobalsStruct.MontageTarget.Alignment_AngleOffsetInDegrees;
    cosTheta = cos(theta_rad);
    sinTheta = sin(theta_rad);
    x_prime_pixels = cosTheta*x_pixels + sinTheta*y_pixels;
    y_prime_pixels = -sinTheta*x_pixels + cosTheta*y_pixels;
    
    %HERE IS WHERE I ADD IN THE CORRECTION FROM THE AlignedTargetList
    r_offset = MySection.YOffsetOfNewInPixels; %Note: Here is where the reversed Y-Axis sign change is fixed
    c_offset = - MySection.XOffsetOfNewInPixels;
    GuiGlobalsStruct.MontageTarget.Alignment_r_offset = GuiGlobalsStruct.MontageTarget.Alignment_r_offset...
        +r_offset;
    GuiGlobalsStruct.MontageTarget.Alignment_c_offset = GuiGlobalsStruct.MontageTarget.Alignment_c_offset...
        +c_offset;
    
    %Then apply the translation offsets that were needed to align this image
    x_prime_pixels = x_prime_pixels - GuiGlobalsStruct.MontageTarget.Alignment_c_offset;
    y_prime_pixels = y_prime_pixels + GuiGlobalsStruct.MontageTarget.Alignment_r_offset;
    
    %now convert this to stage coordinates
    StageX_Meters_CenterOriginalOverview = GuiGlobalsStruct.MontageTarget.StageX_Meters_CenterOriginalOverview;
    StageY_Meters_CenterOriginalOverview = GuiGlobalsStruct.MontageTarget.StageY_Meters_CenterOriginalOverview;
    
    
    
    StageX_Meters = StageX_Meters_CenterOriginalOverview - ...
        x_prime_pixels*(GuiGlobalsStruct.MontageTarget.MicronsPerPixel/1000000);
    StageY_Meters = StageY_Meters_CenterOriginalOverview - ...
        y_prime_pixels*(GuiGlobalsStruct.MontageTarget.MicronsPerPixel/1000000);%Note: This function already applies the stage correction transformation
    %and angle correction
    ScanRot_Degrees = -GuiGlobalsStruct.MontageTarget.Alignment_AngleOffsetInDegrees;% -GuiGlobalsStruct.MontageTarget.MontageNorthAngle;
    
    
    
    %NOTE: YOU NEED TO CHECK IF BETWEEN 0 and 360 and correct here
    if ScanRot_Degrees > 360
        ScanRot_Degrees = ScanRot_Degrees - 360;
    end
    
    if ScanRot_Degrees < 0
        ScanRot_Degrees = ScanRot_Degrees + 360;
    end
    
    MoveStageToTargetWithScanRot(StageX_Meters, StageY_Meters, ScanRot_Degrees);
    
    %************************************
    %Take another image the same resolution and size as the
    %AlignedTargetList image (which is just a crop of the original section
    %overview)
    MicronsPerPixel = MySection.SectionOveriewInfo.FOV_microns/MySection.SectionOveriewInfo.ImageWidthInPixels;
    FOV_microns = (MySection.half_w*2)*MicronsPerPixel;
    GuiGlobalsStruct.MyCZEMAPIClass.Fibics_WriteFOV(FOV_microns)
    pause(0.5);
    GuiGlobalsStruct.MyCZEMAPIClass.Fibics_ReadFOV();
    
    if ~exist(GuiGlobalsStruct.TempImagesDirectory,'dir')
        mkdir(GuiGlobalsStruct.TempImagesDirectory);
    end
    
    PerformAutoFocus;
    
    TempImageFileNameStr = sprintf('%s\\TempImage_%s.tif', GuiGlobalsStruct.TempImagesDirectory, MySection.LabelStr);
    ImageWidthInPixels = MySection.half_w*2;%8192;
    ImageHeightInPixels = MySection.half_h*2;%8192;
    DwellTimeInMicroseconds = 2;
    %Fibics_AcquireImage(MyCZEMAPIClass, ImageWidthInPixels, ImageHeightInPixels, DwellTimeInMicroseconds, FileNameStr,...
    %      FOV_microns, IsDoAutoRetakeIfNeeded, IsMagOverride, MagForOverride,  WaferNameStr, LabelStr)
    Fibics_AcquireImage(ImageWidthInPixels, ImageHeightInPixels, DwellTimeInMicroseconds, TempImageFileNameStr,...
        FOV_microns, true, false, -1,  WaferName, MySection.LabelStr);
    pause(1);
    
    %load this just aquired image
    IsReadOK = false;
    while ~IsReadOK
        IsReadOK = true;
        try
            CurrentImage = imread(TempImageFileNameStr, 'tif');
        catch MyException
            IsReadOK = false;
            %disp(sprintf('   imread exception: %s',MyException.identifier));
            pause(.1);
        end
    end
    
    %Load the cooresponding AlignedTargetList image
    ImageFileNameStr = sprintf('%s\\LowResAligned_%s_Section_%s.tif',...
        GuiGlobalsStruct.AlignedTargetListDir , WaferName,  MySection.LabelStr);
    
    ImageFileNameStr
    
    OriginalImage = imread(ImageFileNameStr, 'tif');
    
    H_gaussian = fspecial('gaussian',[5 5],1.5);
    OriginalImage_Filtered = imfilter(OriginalImage,H_gaussian);
    CurrentImage_Filtered = imfilter(CurrentImage,H_gaussian);
    
    %     I2 = IMCROP(I,RECT)
    %        X2 = IMCROP(X,MAP,RECT)
    %     RECT is a 4-element vector with the form [XMIN YMIN WIDTH HEIGHT]
    %Take 20 pixels off on all sides and make sure teh images are same size)
    [MaxR MaxC] = size(OriginalImage);
    OriginalImage_Filtered_cropped = imcrop(OriginalImage_Filtered,[20 20 MaxR-40 MaxC-40]);
    CurrentImage_Filtered_cropped = imcrop(CurrentImage_Filtered,[20 20 MaxR-40 MaxC-40]);
    
    figure(987);
    subplot(1,2,1);
    imshow(OriginalImage_Filtered_cropped,[0,255]);
    title('OriginalImage_Filtered_cropped');
    
    subplot(1,2,2);
    imshow(CurrentImage_Filtered_cropped,[0,255]);
    title('CurrentImage_Filtered_cropped');
    
    AnglesInDegreesToTryArray = [-1,0, 1];
    [XOffsetOfNewInPixels, YOffsetOfNewInPixels, AngleOffsetOfNewInDegrees] =...
        CalcPixelOffsetAndAngleBetweenTwoImages(OriginalImage_Filtered_cropped, CurrentImage_Filtered_cropped, AnglesInDegreesToTryArray)
    
    
    
    %uiwait(msgbox('Inspect these...'));
    
    
    %***********
    %Use this offset to move the stage into optimal position to align
    %with previous section's image
    disp('HERE IS COMPUTED OFFSET:');
    StageX_Microns_Offset = XOffsetOfNewInPixels*MicronsPerPixel;
    StageY_Microns_Offset = YOffsetOfNewInPixels*MicronsPerPixel;
    MyStr = sprintf('StageX_Microns_Offset = %d, StageY_Microns_Offset = %d',StageX_Microns_Offset, StageY_Microns_Offset);
    disp(MyStr);
    StageX_Meters_Offset = StageX_Microns_Offset/1000000;
    StageY_Meters_Offset = StageY_Microns_Offset/1000000;
    
    disp('Getting stage position');
    StageX_Meters = GuiGlobalsStruct.MyCZEMAPIClass.Get_ReturnTypeSingle('AP_STAGE_AT_X');
    StageY_Meters = GuiGlobalsStruct.MyCZEMAPIClass.Get_ReturnTypeSingle('AP_STAGE_AT_Y');
    stage_z = GuiGlobalsStruct.MyCZEMAPIClass.Get_ReturnTypeSingle('AP_STAGE_AT_Z');
    stage_t = GuiGlobalsStruct.MyCZEMAPIClass.Get_ReturnTypeSingle('AP_STAGE_AT_T');
    stage_r = GuiGlobalsStruct.MyCZEMAPIClass.Get_ReturnTypeSingle('AP_STAGE_AT_R');
    stage_m = GuiGlobalsStruct.MyCZEMAPIClass.Get_ReturnTypeSingle('AP_STAGE_AT_M');
    MyStr = sprintf('Stage Position(x,y,z,t,r,m) = (%0.7g, %0.7g, %0.7g, %0.7g, %0.7g, %0.7g, )'...
        ,StageX_Meters,StageY_Meters,stage_z,stage_t,stage_r, stage_m);
    disp(MyStr);
    disp(' ');
    
    StageX_Meters = StageX_Meters - StageX_Meters_Offset;
    StageY_Meters = StageY_Meters - StageY_Meters_Offset;
    
    MyStr = sprintf('Moving stage to(%0.5g, %0.5g)',StageX_Meters,StageY_Meters);
    disp(MyStr);
    GuiGlobalsStruct.MyCZEMAPIClass.MoveStage(StageX_Meters,StageY_Meters,stage_z,stage_t,stage_r,stage_m);
    while(strcmp(GuiGlobalsStruct.MyCZEMAPIClass.Get_ReturnTypeString('DP_STAGE_IS'),'Busy'))
        pause(.1)
    end
    pause(1)
    
    GuiGlobalsStruct.MyCZEMAPIClass.Execute('CMD_STAGE_BACKLASH');
    while(strcmp(GuiGlobalsStruct.MyCZEMAPIClass.Get_ReturnTypeString('DP_STAGE_IS'),'Busy'))
        pause(.1)
    end
    pause(1);