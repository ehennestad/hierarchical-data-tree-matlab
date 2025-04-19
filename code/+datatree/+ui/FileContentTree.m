classdef FileContentTree < handle
    % FileContentTree - Tree component for browsing nested file contents
    %
    %   This class provides a tree-based UI component for browsing the contents
    %   of files with nested structures, such as MAT files, HDF5 files, and
    %   file system directories.
    %
    %   Example:
    %       % Create a file content tree for a MAT file
    %       parent = uifigure;
    %       tree = FileContentTree(parent);
    %       tree.loadFile('data.mat');
    %
    %       % Set selection callback
    %       tree.NodeSelectionChangedFcn = @(src, event) disp(['Selected: ' event.SelectedNodes{1}.Name]);
    %
    %   See also ContentAdapter, TreeNodeProvider, ContentAdapterFactory
    
    properties
        % UI components
        UITree matlab.ui.container.CheckBoxTree % or uitree depending on MATLAB version
        
        % Data model
        Model datatree.model.TreeNodeProvider
        
        % File properties
        FilePath
        
        % Selection state
        SelectedNodes

        ExpandAllOnCreation (1,1) matlab.lang.OnOffSwitchState = "off"
    end
    
    properties (Dependent)
        Parent
    end
    
    properties (Access = public)
        % Callback properties
        NodeSelectionChangedFcn % Callback for node selection changes
        NodeExpandedFcn % Callback for node expansion
        NodeCollapsedFcn % Callback for node collapse
        
        % Appearance properties
        AllowMultipleSelection logical = false
        ShowIcons logical = false
    end
    
    methods
        function obj = FileContentTree(parent, options)
            % Constructor
            % parent: UI container to place the tree in
            % Optional Name-Value pairs:
            %   'Adapter': ContentAdapter instance or [] to use factory
            %   'FilePath': Path to file to load
            %   'AllowMultipleSelection': true/false
            %   'ShowIcons': true/false
            
            arguments
                parent
                options.Adapter {mustBeA(options.Adapter, ["double", "datatree.adapter.ContentAdapter"])} = []
                options.FilePath (1,1) string = missing
                options.AllowMultipleSelection (1,1) logical = false
                options.ShowIcons (1,1) logical = false
                options.ExpandAllOnCreation (1,1) matlab.lang.OnOffSwitchState = "off"
            end

            % Set properties
            obj.AllowMultipleSelection = options.AllowMultipleSelection;
            obj.ShowIcons = options.ShowIcons;
            obj.ExpandAllOnCreation = options.ExpandAllOnCreation;
            
            % Create UI components
            obj.createComponents(parent);
            
            % Initialize model
            if ~isempty(options.Adapter)
                obj.Model = datatree.model.TreeNodeProvider(options.Adapter);
            end

            % Load file if provided
            if ~ismissing(options.FilePath)
                obj.loadFile(options.FilePath);
            end
        end
        
        function set.Parent(obj, parent)
            % Set parent container
            obj.UITree.Parent = parent;
        end
        
        function parent = get.Parent(obj)
            % Get parent container
            parent = obj.UITree.Parent;
        end
        
        function loadFile(obj, filePath, adapter)
            % Load a file and display its contents
            % filePath: Path to file to load
            % adapter: Optional ContentAdapter instance (if not provided, factory will create one)
            
            obj.FilePath = filePath;
            
            % Create adapter if not provided
            if nargin < 3 || isempty(adapter)
                adapter = datatree.utility.ContentAdapterFactory.createAdapter(filePath);
                obj.Model = datatree.model.TreeNodeProvider(adapter);
            end
            
            % Open file with adapter
            obj.Model.Adapter.open(filePath);
            
            % Populate tree
            obj.populateTree();
        end
        
        function nodes = getSelectedNodes(obj)
            % Get currently selected nodes
            nodes = obj.SelectedNodes;
        end
        
        function expandNode(obj, node)
            % Expand a node
            % Find UI node
            uiNode = obj.findUINode(node);
            if ~isempty(uiNode)
                expand(uiNode);
            end
        end
        
        function collapseNode(obj, node)
            % Collapse a node
            % Find UI node
            uiNode = obj.findUINode(node);
            if ~isempty(uiNode)
                collapse(uiNode);
            end
        end
        
        function selectNode(obj, node)
            % Select a node
            % Find UI node
            uiNode = obj.findUINode(node);
            if ~isempty(uiNode)
                obj.UITree.SelectedNodes = uiNode;
            end
        end
        
        function delete(obj)
            % Destructor
            % Close adapter if open
            if ~isempty(obj.Model) && ~isempty(obj.Model.Adapter)
                obj.Model.Adapter.close();
            end
            
            % Delete UI components
            if isvalid(obj.UITree)
                delete(obj.UITree);
            end
        end
    end
    
    methods (Access = private)
        function createComponents(obj, parent)
            % Create UI components
            obj.UITree = uitree(parent, 'checkbox');
            %obj.UITree.Position = [0 0 parent.Position(3) parent.Position(4)];
            
            % % Set selection mode
            % if obj.AllowMultipleSelection
            %     obj.UITree.MultiSelect = 'on';
            % else
            %     obj.UITree.MultiSelect = 'off';
            % end
            
            % Set callbacks
            obj.UITree.SelectionChangedFcn = @(src, event) obj.onSelectionChanged(src, event);
            obj.UITree.NodeExpandedFcn = @(src, event) obj.onNodeExpanded(src, event);
            obj.UITree.NodeCollapsedFcn = @(src, event) obj.onNodeCollapsed(src, event);
        end
        
        function populateTree(obj)
            % Clear existing tree
            delete(obj.UITree.Children);
            
            % Get root nodes from model
            rootNodes = obj.Model.getRoot();
            
            % Add root nodes to tree
            for i = 1:length(rootNodes)
                node = rootNodes{i};
                obj.addTreeNode(obj.UITree, node);
            end

            if obj.ExpandAllOnCreation
                 obj.UITree.expand()
            end
        end
        
        function nodeUI = addTreeNode(obj, parentUI, node)
            % Add a node to the tree UI
            
            % Create UI node

            arguments
                obj
                parentUI
                node
            end

            nodeUI = uitreenode(parentUI);
            nodeUI.Text = node.Name;
            
            % Add icon if enabled
            if obj.ShowIcons
                nodeUI.Icon = obj.getIconForNode(node);
            end
            
            % Store node data
            nodeUI.NodeData = node;
            
            if isa(parentUI, 'matlab.ui.container.CheckBoxTree')
                %parentUI.NodeExpandedFcn = @(s,e) obj.expandNodeCallback(s,e);
            end

            % Add expand callback if node has children
            if obj.Model.hasChildren(node)
                obj.expandNodeCallback(nodeUI)
                %nodeUI.ExpandFcn = @(src, event) obj.expandNodeCallback(src, event);
            end
        end
        
        function expandNodeCallback(obj, nodeUI, ~)
            % Handle node expansion
            
            % Get node data
            node = nodeUI.NodeData;
            
            % Get children from model
            children = obj.Model.getChildren(node);
            
            % Add children to tree
            for i = 1:length(children)
                obj.addTreeNode(nodeUI, children{i});
            end
        end
        
        function onSelectionChanged(obj, ~, event)
            % Handle selection change
            
            % Update selected nodes
            selectedUINodes = event.SelectedNodes;
            obj.SelectedNodes = cell(length(selectedUINodes), 1);
            
            for i = 1:length(selectedUINodes)
                obj.SelectedNodes{i} = selectedUINodes(i).NodeData;
            end
            
            % Call user callback if defined
            if ~isempty(obj.NodeSelectionChangedFcn)
                eventData = struct('SelectedNodes', obj.SelectedNodes);
                obj.NodeSelectionChangedFcn(obj, eventData);
            end
        end
        
        function onNodeExpanded(obj, ~, event)
            % Handle node expansion
            
            % Call user callback if defined
            if ~isempty(obj.NodeExpandedFcn)
                node = event.Node.NodeData;
                eventData = struct('Node', node);
                obj.NodeExpandedFcn(obj, eventData);
            end
        end
        
        function onNodeCollapsed(obj, ~, event)
            % Handle node collapse
            
            % Call user callback if defined
            if ~isempty(obj.NodeCollapsedFcn)
                node = event.Node.NodeData;
                eventData = struct('Node', node);
                obj.NodeCollapsedFcn(obj, eventData);
            end
        end
        
        function icon = getIconForNode(obj, node)
            % Get icon for node based on type
            
            % Default icon path
            iconPath = fullfile(matlabroot, 'toolbox', 'matlab', 'icons');
            
            % Select icon based on node type
            switch node.Type
                case 'directory'
                    icon = fullfile(iconPath, 'foldericon.gif');
                case 'file'
                    icon = fullfile(iconPath, 'file_new.png');
                case 'mat'
                    icon = fullfile(iconPath, 'mat_file.gif');
                case 'group'
                    icon = fullfile(iconPath, 'foldericon.gif');
                case 'dataset'
                    icon = fullfile(iconPath, 'HDF_dataset.gif');
                case 'attribute'
                    icon = fullfile(iconPath, 'HDF_attribute.gif');
                case 'double'
                    icon = fullfile(iconPath, 'matrix.gif');
                case 'struct'
                    icon = fullfile(iconPath, 'struct.gif');
                case 'cell'
                    icon = fullfile(iconPath, 'cell.gif');
                case 'char'
                    icon = fullfile(iconPath, 'text.gif');
                otherwise
                    icon = fullfile(iconPath, 'file_new.png');
            end
            
            %icon = fullfile(iconPath, iconFilename);

            % Check if icon exists
            if ~isfile(icon)
                icon = fullfile(iconPath, 'file_new.png');
            end
        end
        
        function uiNode = findUINode(obj, node)
            % Find UI node corresponding to data node
            % This is a simple implementation that searches all nodes
            % A more efficient implementation would maintain a mapping
            
            % Start with root nodes
            uiNodes = obj.UITree.Children;
            uiNode = obj.findNodeRecursive(uiNodes, node);
        end
        
        function uiNode = findNodeRecursive(obj, uiNodes, targetNode)
            % Recursively search for a node
            uiNode = [];
            
            for i = 1:length(uiNodes)
                currentUINode = uiNodes(i);
                currentNode = currentUINode.NodeData;
                
                % Check if this is the target node
                if isequal(currentNode, targetNode)
                    uiNode = currentUINode;
                    return;
                end
                
                % Check children if expanded
                if currentUINode.Expanded && ~isempty(currentUINode.Children)
                    uiNode = obj.findNodeRecursive(currentUINode.Children, targetNode);
                    if ~isempty(uiNode)
                        return;
                    end
                end
            end
        end
    end
    
    methods (Static)
        function demo()
            % Demonstrate the FileContentTree component
            
            % Create figure
            f = uifigure('Name', 'File Content Tree Demo', 'Position', [100 100 800 600]);
            
            % Create layout
            gl = uigridlayout(f, [1 2]);
            gl.ColumnWidth = {'1x', '2x'};
            
            % Create tree panel
            treePanel = uipanel(gl);
            treePanel.Layout.Column = 1;
            
            % Create preview panel
            previewPanel = uipanel(gl);
            previewPanel.Layout.Column = 2;
            
            % Create preview text area
            previewText = uitextarea(previewPanel);
            previewText.Position = [10 10 previewPanel.Position(3)-20 previewPanel.Position(4)-20];
            previewText.Value = 'Select a node to preview its contents';
            
            % Create file content tree
            tree = datatree.ui.FileContentTree(treePanel, 'AllowMultipleSelection', false);
            
            % Create toolbar
            tb = uitoolbar(f);
            
            % Add open button
            openButton = uipushtool(tb, 'Icon', fullfile(matlabroot, 'toolbox', 'matlab', 'icons', 'file_open.png'));
            openButton.Tooltip = 'Open File';
            openButton.ClickedCallback = @(src, event) openFile();
            
            % Open file callback
            function openFile()
                [adapter, filePath] = datatree.utility.ContentAdapterFactory.createAdapterFromDialog();
                if ~isempty(adapter)
                    tree.loadFile(filePath, adapter);
                end
            end
            
            % Set selection callback
            tree.NodeSelectionChangedFcn = @(src, event) previewNode(event.SelectedNodes);
            
            % Preview node callback
            function previewNode(nodes)
                if isempty(nodes)
                    previewText.Value = 'No node selected';
                    return;
                end
                
                % Get first selected node
                node = nodes{1};
                
                % Get node data
                data = tree.Model.getNodeData(node);
                
                % Preview based on data type
                if isstruct(data)
                    % Show structure fields
                    fields = fieldnames(data);
                    preview = sprintf('Structure with %d fields:\n\n', length(fields));
                    for i = 1:min(length(fields), 20)
                        preview = [preview, fields{i}, '\n'];
                    end
                    if length(fields) > 20
                        preview = [preview, '...\n'];
                    end
                elseif iscell(data)
                    % Show cell array info
                    preview = sprintf('Cell array of size %s\n', mat2str(size(data)));
                elseif isnumeric(data)
                    % Show numeric array info
                    preview = sprintf('Numeric array (%s) of size %s\n', class(data), mat2str(size(data)));
                    if numel(data) <= 100
                        % Show small arrays
                        preview = [preview, '\n', mat2str(data)];
                    end
                elseif ischar(data)
                    % Show text
                    preview = sprintf('Character array:\n\n%s', data);
                else
                    % Generic preview
                    preview = sprintf('Data of type %s\n', class(data));
                end
                
                previewText.Value = preview;
            end
        end
    end
end
