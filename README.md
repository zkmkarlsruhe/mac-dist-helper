mac-app-builder
===============

Helper makefiles for building & packaging macOS binaries distribution

This code base has been developed by [ZKM | Hertz-Lab](https://zkm.de/en/about-the-zkm/organization/hertz-lab) as part of the project [»The Intelligent Museum«](#the-intelligent-museum).

Copyright (c) 2022 ZKM | Karlsruhe.  
Copyright (c) 2022 Dan Wilcox.

BSD Simplified License.

For information on usage and redistribution, and for a DISCLAIMER OF ALL
WARRANTIES, see the file, "LICENSE.txt," in this distribution.

Inspired by the [pd-lib-builder](https://github.com/pure-data/pd-lib-builder) makefile by Katja Vetter, et al.

Description
-----------

Building macOS applications is relatively easy using Xcode, however notarizing and packaging is more or less "left up to the developer." You can quickly build a .app *but* copying it to another computer either results in the app not running and/or security warnings presented to the user. The notarization process introduced by Apple requires binaries from a known developer account to be verified before running. In order to notarize a project, the project's *signed* binaries need to be uploaded to Apple via the toolchain included with Xcode, either `altool` (legacy) or `notarytool`. Oi, what a pain!

This set of makefiles automates the creation of a project distribution as well as the signing and notarization required by Apple to avoid the "malicious software" warning on systems running macOS 10.15+. Basically, give the makefile the name of your app or list of binaries, codesign identity, App Store Connect password\*, as well as additional package files (readmes, resources, etc) and the makefile will do the rest.

\* *Note: The App Store Connect password is stored in keychain and retrieved by keyname. No plain-text involved.*

The tools originated in custom makefiles for the distribution of [Zirkonium3](http://zkm.de/zirkonium) and the need to easily build and distribute experimental macOS applications made using [openFrameworks](https://openframeworks.cc).

Notarization
------------

As of fall 2022, the basic notarization process is:

1. Build project
2. Sign application/binaries with Apple Developer account
3. Submit application/binaries to Apple servers for notarization and wait (\~5 minutes)
4. Staple "ticket" to application/binaries on success

Once the project is notarized, the applications/binaries can then be packaged for distribution such as in a zip or dmg file.

For details on the notarization process and how the tools used are wrapped by the makefiles, see the Apple docs on notarizaing macOS software before distribution:

* [Customizing the Notarization Workflow (Xcode 13+)](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution/customizing_the_notarization_workflow)
* [Customizing the Notarization Workflow (Xcode 11-12)](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution/customizing_the_notarization_workflow/notarizing_apps_when_developing_with_xcode_12_and_earlier)

Basic Example
-------------

A single-application project named `Foo` which is built from a `Foo.xcodeproject` Xcode project and should be distributed with meta-data text files by the "Baz Developers" Apple Developer ID account.

Makefile:
```Makefile

mac.app.name = Foo

mac.dist.version = 1.2.3

mac.dist.include = CHANGES.txt LICENSE.txt README.md

mac.codesign.identity = Baz Developers (12345ABCDE)

mac.notarize.password = AC_PASSWORD

include mac-app-builder/mac-app-builder.mk

endif
```

Run:
```shell
make app dist notarize dmg
```

Results in:
```
build/Foo.app <-- signed and notarized
build/Foo-1.2.3.dmg <-- signed
dist/Foo-1.2.3 <-- used for contents of dmg
dist/Foo-1.2.3/Foo.app
dist/Foo-1.2.3/CHANGES.txt
dist/Foo-1.2.3/LICENSE.txt
dist/Foo-1.2.3/README.md
```

The signed `Foo-1.2.3.dmg` disk image can be distributed to users who should be able to mount it and copy the "Foo-1.2.3" directory to `/Applications` or wherever.

Layout & Usage
--------------

The mac-app-builder makefiles are designed to be used for both single-app projects as well as distributable libraries and each component is provided as a separate makefile to be integrated within more complex projects:

* app.mk: build a single macOS .app from an Xcode project as an signed archive export
* codesign.mk: codesign files which are signed via Xcode, ie. non-Xcode makefile builds
* dist.mk: assemble files for distribution, can be single .app or directory with multiple files and subdirs
* notarize.mk: zip binaries and upload to Apple servers for notarization then staple ticket on success
* zip.mk: package distribution as a zip file 
* dmg.mk: package distribution as a (signed) macOS disk image

All components are included together into the `mac-app-builder.mk` makefile which is designed to be included in a minimal makefile which sets the required variables. Either include this entire directory within the project (as a git subtree for instance) or add only those components you need within by including them within your existing makefile(s).

Documentation
-------------

Documentation for the makefile variables and targets are currently provided bu comments in each makefile component.

Requirements
------------

Minimum requirements:

* Xcode 11 (or equivalent Commandline Tools version)
* Apple Developer account
* Apple Developer "Development" and "Developer ID application" signing certificates installed
* App Store Connect 2FA password installed in keychain

Suggested requirements:

* Xcode 13+ (or equivalent Commandline Tools version)

*As of fall 2022, the legacy Xcode 11-12 process using `altool` works but is deprecated.*

Apple Developer Setup
---------------------

Installing the Apple Developer-specific requirements only needs to be done once on each build system.

### Apple Developer Signing Certificates

For code signature and notarization, an Apple Developer account and the following signatures are required.

Create an Apple Developer account at [developer.apple.com](https://developer.apple.com)

Create "Development" and "Developer ID application" singing certificates, either within Xcode or via the Apple Developer website.

In Xcode:
1. Open the Xcode preferences and select the Accounts tab
2. Create an account for your Apple ID, if you haven't done so already
3. Select the development team and click Manage Certificates...
4. Click the + icon and select the appropriate certificate the create

On the Apple Developer website:
1. login with your developer account to [developer.apple.com/account/resources/certificates/](https://developer.apple.com/account/resources/certificates/)
2. Click the + icon and select the appropriate certificate to create
3. Download the certificate to your computer and add it to the system keychain, usually by double-clicking the file

This process only needs to be done once on the build system.

*Note: If you want to use the same Apple Developer account and certificates on another build system, you will need to export the private keys used to create the certificates on the original build system and import them on the new one.*

For details, see the [Apple docs](https://developer.apple.com/support/certificates/).

### App Store Connect password

1. Create a new app-specific password for your AppleID bu following the [Apple guide](https://support.apple.com/en-us/HT204397) and name it something like "AC Notarization"
2. Copy and paste generated password somewhere safe. Keep private.
3. Install the password to your build system's keychain:

For Xcode 13+ (recommended)
```shell
xcrun notarytool store-credentials "AC_PASSWORD" \
               --apple-id <username> \
               --team-id <team id> \
               --password <secret password>
```

For Xcode 11-12 (legacy):
```shell
xcrun altool --store-password-in-keychain-item "AC_PASSWORD" \
               -u <username> \
               -p <secret password>
```

"username" is the Apple ID username, usually your email address.

"secret password" is the app-specific generated password string for two-factor authentication with the Apple servers.

"team id" is the developer unique team id used when building and signing the project. If you don't know what it is, either check the UI in Xcode under the project target's "Signing and Capabilities" settings or log into [developer.app.com](https://developer.apple.com/account/#/membership) and check your account info.

"AC_PASSWORD" is the keyname of the password stored within the system's keychain. It is recommended to keep this name, however you can use a custom one if required.

This process only needs to be done once on the build system and the password can be reused for different projects.

If you need to remove the password from the system:
* open the Keychain Access application
* select System
* search for the password keyname, ie. "AC_PASSWORD"
* select and press Delete/Backspace

Packaging Considerations
------------------------

Simple zip file or macOS disk image... what's the difference for distribution?

For basic, self-contained apps a zip file is quick and easy. However, disk images can be *signed* which is an important security consideration.

Recommendation:
* zip: use for simple self-contained apps or libraries
* dmg: use for any app which loads custom resources *outside* of the .app bundle

*Note: Normal system-provided dynamic library linking is fine for binaries within zip files.*

### App Translocation

Apple introduced "App Translocation" which transparently runs applications downloaded in unsigned packages in a random private temp location to make it harder to malware to load resources outside of the .app bundle. This protection is removed if the application is removed from "quarantine" such as if the user movies the .app into their `/Applications` directory.

For details, read the [description](https://www.synack.com/blog/untranslocating-apps/) from the security researcher who identified the original issue.

This process works fine for applications which bundle all of their resources internally, however it *completely breaks* [openFrameworks applications](https://openframeworks.cc) which keep their resources *outside* of the built .app in a `data` folder to make it easy to add and modify resources:

```
bin/MyImageViewer.app
bin/data/image.jpg
```

This application will run fine on the build system, however if the bin folder is copied to another system via a zip file, it will not be able to locate the `data` folder.

The best solution is to avoid App Translocation altogether by packaging the application and it's data within a signed disk image.

Development
-----------

Release steps:
1. Update changelog
2. Update makefile version in `mac-app-builder.mk`
3. Tag version commit, ala "0.3.0"
4. Push commit and tags to server:
~~~
git commit push
git commit push --tags
~~~

The Intelligent Museum
----------------------

An artistic-curatorial field of experimentation for deep learning and visitor participation

The [ZKM | Center for Art and Media](https://zkm.de/en) and the [Deutsches Museum Nuremberg](https://www.deutsches-museum.de/en/nuernberg/information/) cooperate with the goal of implementing an AI-supported exhibition. Together with researchers and international artists, new AI-based works of art will be realized during the next four years (2020-2023).  They will be embedded in the AI-supported exhibition in both houses. The Project „The Intelligent Museum” is funded by the Digital Culture Programme of the [Kulturstiftung des Bundes](https://www.kulturstiftung-des-bundes.de/en) (German Federal Cultural Foundation) and funded by the [Beauftragte der Bundesregierung für Kultur und Medien](https://www.bundesregierung.de/breg-de/bundesregierung/staatsministerin-fuer-kultur-und-medien) (Federal Government Commissioner for Culture and the Media).

As part of the project, digital curating will be critically examined using various approaches of digital art. Experimenting with new digital aesthetics and forms of expression enables new museum experiences and thus new ways of museum communication and visitor participation. The museum is transformed to a place of experience and critical exchange.
