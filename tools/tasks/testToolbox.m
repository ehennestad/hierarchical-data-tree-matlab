function testToolbox(varargin)
    installMatBox()
    projectRootDirectory = datatreetools.projectdir();
    matbox.tasks.testToolbox(projectRootDirectory, varargin{:})
end