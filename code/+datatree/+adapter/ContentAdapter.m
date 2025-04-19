classdef (Abstract) ContentAdapter < handle
    % ContentAdapter - Interface for adapters that read nested content from files
    %
    %   This is an abstract class that defines the interface for content adapters.
    %   Content adapters are used to read hierarchical data from files and provide
    %   a consistent interface for tree-based viewers.
    %
    %   Subclasses must implement the following methods:
    %       - open
    %       - getRoot
    %       - getChildren
    %       - hasChildren
    %       - getNodeData
    %       - close
    %
    %   See also FileContentTree, TreeNodeProvider
    
    methods (Abstract)
        % Open a file and prepare for reading its contents
        open(obj, filePath)
        
        % Get the root node(s) of the content hierarchy
        rootNodes = getRoot(obj)
        
        % Get children of a specific node
        childNodes = getChildren(obj, node)
        
        % Check if a node has children
        tf = hasChildren(obj, node)
        
        % Get data associated with a node (for display/preview)
        data = getNodeData(obj, node)
        
        % Close the file and clean up resources
        close(obj)
    end
end
