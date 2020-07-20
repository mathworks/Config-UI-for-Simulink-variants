function variantConfigUI (model)
% variantConfigUI function searches for all variant subsystems in a model and uses
% set_param to change 'VariantControlModel' and
% 'LabelModeActiveChoice'. Adding new variants also changes UI size.
% Changing a pop up menu's value immediately changes the active variant in the Simulink
% model.
%
% Input:model: char variable containing model name
%
% example: variantConfigUI('vehicleVariantsLabel')

% Copyright 2020 The MathWorks, Inc.

if nargin<1
    error('VariantConfigUI function needs one input');
end


open_system(model);
pathname = fileparts(which(model));

app.data.model = fullfile(pathname, model);
app.Width = 700;
app.Heigth = [];
app.data.variants= [];
app.data.objects = [];

readVariants();
genFigure();
genVariants();
app.hfig.Visible = 'on';


    function readVariants()
        app.data.variants= [];
        
        [~, modelname, ~]=fileparts(app.data.model);
        cell_variants = find_system(modelname, 'LookUnderMasks', 'all', 'Variants', 'AllVariants', 'Variant', 'on');
        
        
        kk = 1;
        for ii=1:numel(cell_variants)
            
            if ~contains(get_param(cell_variants{ii}, 'Tag'), 'noUIvariant')
                if ~strcmp(get_param(cell_variants{ii}, 'VariantControlMode'), 'Label')
                    set_param(cell_variants{ii}, 'VariantControlMode', 'Label');
                    warning (['Variant property ''VariantControlMode'' for block ''' cell_variants{ii} ''' was set to ''Label''']);
                end
                name = strsplit(cell_variants{ii}, '/');
                app.data.variants(kk).name = name{end};
                app.data.variants(kk).path = cell_variants{ii};
                app.data.variants(kk).varinfo = get_param(cell_variants{ii}, 'Variants');
                app.data.variants(kk).initActive = get_param(cell_variants{ii}, 'LabelModeActiveChoice');
                app.data.variants(kk).items = {};
                app.data.variants(kk).labelVariants = {};
                
                % read items
                for jj=1:numel(app.data.variants(kk).varinfo)
                    tmp_name= strsplit(app.data.variants(kk).varinfo(jj).BlockName, '/');
                    app.data.variants(kk).items{jj} = tmp_name{end};
                    app.data.variants(kk).labelVariants{jj} = app.data.variants(kk).varinfo(jj).Name;
                end
                kk = kk+1;
            end
        end
        
    end

    function genFigure()
        % generate figure
        numRows = round(numel(app.data.variants)/2);
        app.Height = numRows*35 + 65;
        
        if ~isfield(app, 'hfig')
            % generate figure, label and button
            ScreenSize = get(0, 'ScreenSize');
            pos=  [(ScreenSize(3:4)-[app.Width app.Height])/2 [app.Width app.Height] ];
            app.hfig = uifigure('Position',pos,...
                'CloseRequestFcn',@(f, event)my_closereq(f),...
                'Visible', 'off');
            
            % generate label
            app.hlabel = uilabel('Parent',app.hfig,'Position',[10 pos(4)-35 pos(3)-40 35],'Text',app.data.model,'FontSize',15,'FontWeight','bold');
            app.hbutton = uibutton(app.hfig, 'push',...
                'Text', 'Update',...
                'FontWeight', 'bold',...
                'Position',[30+pos(3)-40-65,pos(4)-35+5, 65, 22],...
                'ButtonPushedFcn', @(btn,event) updateUI(btn));
        else
            % update positions
            oldPosition = app.hfig.Position;
            pos = [oldPosition(1) oldPosition(2)-(app.Height-oldPosition(4)) app.Width app.Height];
            app.hfig.Position = pos;
            app.hlabel.Position = [10 pos(4)-35 pos(3)-40 35];
            app.hbutton.Position = [30+pos(3)-40-65,pos(4)-35+5, 65, 22];
        end
    end

    function genVariants()
        if isfield(app.data, 'objects')
            if ~isempty(app.data.objects)
                delete([app.data.objects(:).label]);
                delete([app.data.objects(:).dropdown]);
            end
        end
        app.data.objects = [];
        if isfield(app, 'hPan')
            delete(app.hPan);
        end
        
        figurePosition =  app.hfig.Position;
        
        pos = [10 10  figurePosition(3)-20 figurePosition(4)-45];
        app.hPan = uipanel('Parent',app.hfig,'Position',pos,'Title','Simulink Variant Subsystems');
        
        dist = 30;
        heigthTotal = pos(4);
        x_initial = 5;
        sizeLabel =  100;
        sizeDropdown = 200;
        heigth = 22;
        offsetY = 20;
        jj = 0;
        for ii=1:numel(app.data.variants)
            if mod(ii,2)
                offset = 0;
                jj = jj+1;
            else
                offset = 320;
            end
            %Label
            app.data.objects(ii).label =  uilabel(app.hPan);
            app.data.objects(ii).label.FontWeight =  'bold';
            app.data.objects(ii).label.Position =  [x_initial+offset heigthTotal-offsetY-jj*dist sizeLabel heigth];
            app.data.objects(ii).label.Text = [app.data.variants(ii).name ':'];
            % DropDown
            app.data.objects(ii).dropdown = uidropdown(app.hPan);
            app.data.objects(ii).dropdown.Items = app.data.variants(ii).items;
            app.data.objects(ii).dropdown.Position = [x_initial+sizeLabel+offset+10 heigthTotal-offsetY-jj*dist sizeDropdown heigth];
            app.data.objects(ii).dropdown.Value = app.data.variants(ii).items {strcmp(app.data.variants(ii).labelVariants, app.data.variants(ii).initActive)};
            app.data.objects(ii).dropdown.ValueChangedFcn = @(this, event) update_variants(this, app.data.objects(ii), app.data.variants(ii));
        end
    end

    function update_variants(~,obj, var)
        try
            idx = strcmp(obj.dropdown.Value, var.items);
            set_param(var.path, 'LabelModeActiveChoice', var.varinfo(idx).Name);
        catch
            warning(['Update active label for variant' var.path 'was not successful. Label does not exist or model is closed']);
        end
    end

    function updateUI(~)
        readVariants();
        genFigure();
        genVariants();
    end

    function my_closereq(f)
        selection = questdlg('Close the figure window?',...
            'Confirmation',...
            'Yes','No','Yes');
        switch selection
            case 'Yes'
                delete(f)
                clear global app
            case 'No'
                return
        end
    end
end

