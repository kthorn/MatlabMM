%Script to traverse a micromanager directory structure and convert 3 color
%images to a single RGB tiff. Can flatfield and darkfield correct too.

DFdir = 'X:\KSTtemp\OspreyZyla\Zyla-DF-images\Undefined'; %Directory for DarkField Images.
FFdir = 'X:\KSTtemp\OspreyZyla\Zyla-FF-images'; %Directory for FlatField Images
RedName = 'Brightfield - Red';
GreenName = 'Brightfield - Green';
BlueName = 'Brightfield - Blue';
inDir = 'X:\KSTtemp\OspreyZyla\Zyla-tiles';
outDir = 'X:\KSTtemp\OspreyZyla\Zyla-tiles-8bit';
basename = 'Undefined'; %base text for each position; usually 'Undefined'
newbasename = 'Position'; %change Undefined to something nicer.
outputType = 'uint8'; %Output bitdepth; can be uint8 or uint16

disp('processing DarkField Images')
%Process DarkField Images
DFstack = squeeze(MMparse(DFdir));
DFim = mean(double(DFstack), 3);
clear DFstack;

disp('processing FlatField Images')
%Process FlatField Images
stack = squeeze(MMparse(FFdir, [], {RedName}));
redFF = mean(double(stack), 3) - DFim;
redFF = 1./redFF;
stack = squeeze(MMparse(FFdir, [], {GreenName}));
greenFF = mean(double(stack), 3) - DFim;
greenFF = 1./greenFF;
stack = squeeze(MMparse(FFdir, [], {BlueName}));
blueFF = mean(double(stack), 3) - DFim;
blueFF = 1./blueFF;
clear stack

%process data
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

disp('processing Images')
RE = [basename, '(\d+)']; %Regexp to get number at end of position folder name
%traverse over input directory
topDir = dir(inDir);
for n=1:size(topDir,1)
    if topDir(n).isdir && ~strcmp(topDir(n).name ,'.') && ~strcmp(topDir(n).name,'..')
        %disp('loading time:')
        %tic
        %inside a directory corresponding to a position
        posName = topDir(n).name;
        
        %get position index
        fileparts = regexp(posName, RE, 'tokens');
        if isempty(fileparts)
            index = 0;
        else
            fileparts = fileparts{1};
            index = str2double(fileparts{1});
        end
        outfile = fullfile(outDir, [newbasename, '_', sprintf('%05d', index), '.tif']);
        
        red = squeeze(MMparse(fullfile(inDir, posName), [], {RedName}));
        green = squeeze(MMparse(fullfile(inDir, posName), [], {GreenName}));
        blue = squeeze(MMparse(fullfile(inDir, posName), [], {BlueName}));
        %toc
        %disp('processing time:')
        %tic
        if ndims(red) > 2
            error('Code does not yet handle Z stacks or Time lapse data');
        end
        red = flatField(red, DFim, redFF);
        blue = flatField(blue, DFim, blueFF);
        green = flatField(green, DFim, greenFF);
        
        RGB = cat(3, red, green, blue);
        
        
        switch outputType
            case 'uint8'
                RGB = uint8(RGB * 255);                
            case 'uint16'
                RGB = uint16(RGB * 65535);
            otherwise
                error('Unsupported outputType');
        end
        imwrite(RGB, outfile);
        %toc
    end
end
