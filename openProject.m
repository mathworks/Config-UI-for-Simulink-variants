% Copyright 2020 The MathWorks, Inc.

prj = matlab.project.rootProject;

if strcmp(prj.Name, 'configVariant')
variantConfigUI('vehicleVariantsLabel');
open(strcat(fileparts(which(mfilename)), '\doc\html\VariantConfigAppdoc.html'));
end