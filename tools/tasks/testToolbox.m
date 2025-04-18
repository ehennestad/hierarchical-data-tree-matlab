function testToolbox(varargin)
    installMatBox()
    projectRootDirectory = hdtreetools.projectdir();
    matbox.tasks.testToolbox(projectRootDirectory, varargin{:})
end