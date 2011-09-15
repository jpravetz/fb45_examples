sample-module3
==============

This is a simple module that is used by the sample-modules-shell project, used to demonstrate how to build a module that is included into another project.

The project was created as a new Flex Project with application type _Desktop_ so that AIR libraries would be included.
Note that setting this to Desktop will cause TestModule3.swf and TestModule3-app.xml to be generated and put in the output folder specified below. The module Module3.mxml was created under the test.module3 package.

The project _Properties > Flex Library Build Path > Output_ is set to _${DOCUMENTS}/sample-modules-shell/src/assets/modules_

Uncheck the option found at the project _Properties > Flex Compiler > Compiler Options > Copy non-embedded files to output folder_

_Do you have a better way to configure this project for use in AIR so that the *.swf and *-app.xml files are not produced?_
