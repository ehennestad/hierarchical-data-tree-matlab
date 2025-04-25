classdef MatFileAdapter < datatree.adapter.ContentAdapter
    % MatFileAdapter - Adapter for MAT files
    %
    %   This class implements the ContentAdapter interface for MAT files.
    %   It provides methods to browse the contents of a MAT file as a tree.
    %
    %   Example:
    %       adapter = MatFileAdapter();
    %       adapter.open('data.mat');
    %       rootNodes = adapter.getRoot();
    %
    %   See also ContentAdapter, FileContentTree
    
    properties (SetAccess = private)
        FilePath % Path to the MAT file
        FileData % Contents of the MAT file
    end

    properties
        % For structure arrays, it might be convenient to see each struct
        % array element as a separate node in the tree
        ShowStructArrayElementsAsSeparateNodes (1,1) logical = true
        % It might also be good to have a cutoff, say, you dont want to
        % expand a struct array with 100s of elements
        NumStructElementsToSplit (1,1) double = 5
    end
    
    methods
        function obj = MatFileAdapter(filePath)
            % Constructor
            obj.FilePath = filePath;
        end
        
        function open(obj, filePath)
            % Open a MAT file
            % filePath: Path to the MAT file
            
            obj.FilePath = filePath;
            try
                % Load the file
                obj.FileData = load(filePath);
            catch ME
                error('MatFileAdapter:LoadError', 'Error loading MAT file: %s', ME.message);
            end
        end
        
        function nodes = getRoot(obj)
            % Get root nodes (top-level variables in the MAT file)
            
            if isempty(obj.FileData)
                nodes = {};
                return;
            end
            
            % Get field names
            fieldNames = fieldnames(obj.FileData);
            
            % Create nodes
            nodes = cell(length(fieldNames), 1);
            
            for i = 1:length(fieldNames)
                name = fieldNames{i};
                data = obj.FileData.(name);

                if iscell(data)
                    % Wrap in a cell, otherwise the new node structure will
                    % be a structure array
                    data = {data};
                end
                
                % Create node
                nodes{i} = struct(...
                    'Name', name, ...
                    'Path', name, ...
                    'Type', class(data), ...
                    'Data', data ...
                );
            end
        end
        
        function nodes = getChildren(obj, node)
            % Get children of a node
            % node: Parent node
            
            data = node.Data;
            path = node.Path;
            
            if isstruct(data)
                % Handle struct arrays - each element becomes a separate node
                if ~isscalar(data) && obj.doExpandStructArray(data)
                    % Create a node for each element in the struct array
                    numElements = numel(data);
                    nodes = cell(numElements, 1);
                    
                    for i = 1:numElements
                        % Create element name with index suffix
                        elementName = sprintf('%s_%d', node.Name, i);
                        % Create element path with parenthesis indexing
                        elementPath = sprintf('%s(%d)', path, i);
                        
                        % Create node for this struct array element
                        nodes{i} = struct(...
                            'Name', elementName, ...
                            'Path', elementPath, ...
                            'Type', 'struct', ...
                            'Data', data(i) ...
                        );
                    end
                    return;
                end

                % Handle structure fields for scalar structs
                fieldNames = fieldnames(data);
                
                if isempty(fieldNames)
                    nodes = {};
                    return;
                end
                
                nodes = cell(length(fieldNames), 1);
                
                for i = 1:length(fieldNames)
                    name = fieldNames{i};
                    childData = {data.(name)};
                    childPath = [path '.' name];
                    
                    % Create node
                    nodes{i} = struct(...
                        'Name', name, ...
                        'Path', childPath, ...
                        'Type', class(childData), ...
                        'Data', childData ...
                    );
                end
                
            elseif iscell(data)
                % Handle cell array elements
                if isempty(data) || all(size(data) == 0)
                    nodes = {};
                    return;
                end
                
                nodes = cell(numel(data), 1);
                
                for i = 1:numel(data)
                    % Create index string based on dimensions
                    dims = size(data);
                    if length(dims) <= 2
                        if dims(1) == 1 || dims(2) == 1
                            % 1D cell array
                            indexStr = sprintf('{%d}', i);
                        else
                            % 2D cell array
                            [row, col] = ind2sub(dims, i);
                            indexStr = sprintf('{%d,%d}', row, col);
                        end
                    else
                        % Multi-dimensional cell array
                        subs = cell(1, length(dims));
                        [subs{:}] = ind2sub(dims, i);
                        indexStr = '{';
                        for j = 1:length(subs)
                            if j > 1
                                indexStr = [indexStr ',' num2str(subs{j})];
                            else
                                indexStr = [indexStr num2str(subs{j})];
                            end
                        end
                        indexStr = [indexStr '}'];
                    end
                    
                    childData = data{i};
                    childPath = [path indexStr];
                    
                    % Create node
                    nodes{i} = struct(...
                        'Name', indexStr, ...
                        'Path', childPath, ...
                        'Type', class(childData), ...
                        'Data', childData ...
                    );
                end
                
            elseif isnumeric(data) && ~isscalar(data)
                % Handle non-scalar numeric arrays
                dims = size(data);
                
                if length(dims) <= 2
                    % 2D array
                    nodes = cell(2, 1);
                    
                    % Add size node
                    sizeStr = sprintf('%d×%d %s', dims(1), dims(2), class(data));
                    nodes{1} = struct(...
                        'Name', 'Size', ...
                        'Path', [path '.size'], ...
                        'Type', 'size', ...
                        'Data', dims ...
                    );
                    
                    % Add class node
                    nodes{2} = struct(...
                        'Name', 'Class', ...
                        'Path', [path '.class'], ...
                        'Type', 'class', ...
                        'Data', class(data) ...
                    );
                else
                    % Multi-dimensional array
                    nodes = cell(2, 1);
                    
                    % Add size node
                    sizeStr = 'Size: [';
                    for j = 1:length(dims)
                        if j > 1
                            sizeStr = [sizeStr '×' num2str(dims(j))];
                        else
                            sizeStr = [sizeStr num2str(dims(j))];
                        end
                    end
                    sizeStr = [sizeStr ']'];
                    
                    nodes{1} = struct(...
                        'Name', sizeStr, ...
                        'Path', [path '.size'], ...
                        'Type', 'size', ...
                        'Data', dims ...
                    );
                    
                    % Add class node
                    nodes{2} = struct(...
                        'Name', ['Class: ' class(data)], ...
                        'Path', [path '.class'], ...
                        'Type', 'class', ...
                        'Data', class(data) ...
                    );
                end
            else
                % No children for other types
                nodes = {};
            end
        end
        
        function tf = hasChildren(obj, node)
            % Check if a node has children
            % node: Node to check
            
            data = node.Data;
            
            % Structures and cell arrays have children
            if isstruct(data)
                if isscalar(data) || ~obj.doExpandStructArray(data)
                    % Scalar struct or non-expandable struct has children if it has fields
                    tf = ~isempty(fieldnames(data));
                else
                    % Non-scalar & expandable struct arrays always have children (the elements)
                    tf = true;
                end
            elseif iscell(data)
                tf = ~isempty(data) && any(size(data) > 0);
            elseif isnumeric(data) && ~isscalar(data)
                % Non-scalar numeric arrays have size and class children
                tf = false;
            else
                tf = false;
            end
        end
        
        function data = getNodeData(obj, node)
            % Get data associated with a node
            % node: Node to get data for
            
            data = node.Data;
        end
        
        function close(obj)
            % Close the file and clean up resources
            
            obj.FileData = [];
            obj.FilePath = '';
        end
    end

    methods (Access = private)
        function tf = doExpandStructArray(obj, structArray)
            tf = obj.ShowStructArrayElementsAsSeparateNodes && ...
                numel(structArray) <= obj.NumStructElementsToSplit;
        end
    end
end
