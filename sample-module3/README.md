sample-module3
==============

This is a simple module that is used by the sample-modules-shell project, used to demonstrate how to build a module that is included into another project.

The project was created as a new Flex Project with application type _Desktop_ so that AIR libraries would be included.
Note that setting this to Desktop will cause TestModule3.swf and TestModule3-app.xml to be generated and put in the output folder specified below. The module Module3.mxml was created under the test.module3 package.

The project Properties > Flex Library Build Path > Output is set to ${DOCUMENTS}/sample-modules-shell/src/assets/modules

Uncheck the project option found at Properties > Flex Compiler > Compiler Options > Copy non-embedded files to output folder