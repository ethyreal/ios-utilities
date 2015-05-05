# Tealium iOS Utilities
=======================

###Brief###
These public classes are for Tealium clients and prospects to quickly and more conveniently implement Tealium mobile TIQ and AudienceStream libraries.

###Table of Contents###
- [Requirements](#requirements)
- [Cocoapods Integration](#cocoapod-integration)
- [Manual Integration](#manual-integration)
- [Swift Bridging](#swift-bridging)


###Requirements###
- Minimum target iOS Version 7.0+ 


###Cocoapods Integration###
In your project's *podfile*, add the following line:
   
```Objective-C
    pod 'TealiumUtilities'
```

Then run *pod update* to update your dependencies.


###Manual Integration###
1. Copy or clone the classes in this repo to your project
2. Add the "-ObjC" flag to your Project:target:build settings:linking:other linker flags option


###Swift Bridging###
If you're building in Swift, then you will need to also:

A. Link the provided *TealiumUtilities-Bridging-Header.h* to your Target:Build Settings:Swift Compiler:Objective-C Bridging Header option with *Pods/TealiumUtilities/TealiumUtilities-Bridging-Header.h*   --OR--

B. Import the same class headers into your own bridging header.

   
--------------------------------------------

Copyright (C) 2012-2015, Tealium Inc.