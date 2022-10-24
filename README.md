mac-dist-helpers
================

Helper makefiles for exporting & packaging macOS binaries for distribution

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

Quick Start
-----------

1. Copy either `Makefile-mac-app.mk` file into your project or include this repo as a submodule or subtree.
2. Include either `Makefile-mac-app.mk` and/or `Makefile-mac-dist.mk` file into a parent makefile and set the minimum require variables such as `mac.app.name` or `mac.dist.name`.
3. Set up the Apple Developer certificates and App Store Connect password in oyur keychain, see the Requirements section.
4. Run the makefile targets: `make distdmg`
5. Grab a coffee and hopefully there is a signed and notarized `.dmg` disk image waiting for you.

The signed disk image can be distributed to users who should be able to mount it and copy the project directory to `/Applications` or wherever.

Notarization Process
--------------------

As of fall 2022, the basic notarization process is:

1. Build project
2. Sign application/binaries with Apple Developer account
3. Submit application/binaries to Apple servers for notarization and wait (can be about 5 minutes)
4. Staple "ticket" to dmg and application/binaries on success
5. If distributing via .zip, re-build zip with newly notarized binaries

For details on the notarization process and how the tools used are wrapped by the makefiles, see the Apple docs on notarizaing macOS software before distribution: [Customizing the Notarization Workflow (Xcode 13+)](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution/customizing_the_notarization_workflow).

Layout
------

The mac-dist-helper makefiles are designed to be used for both single-app projects as well as distributable libraries and each component is provided as a separate makefile to be integrated within more complex projects:

* Makefile-mac-app.mk: build a single macOS .app from an Xcode project as an signed archive export
* Makefile-mac-dist.mk: assemble distribution zip or notarized dmg
    - dist: assemble files for distribution, can be single .app or directory with multiple files and subdirs
    - codesign: codesign files which are not signed via Xcode, ie. non-Xcode makefile builds
    - zip: package distribution as a zip file
    - dmg: package distribution as a (signed) macOS disk image
    - notarize: upload zip or dmg to Apple servers for notarization then staple ticket on success

### Makefile-mac-app.mk

Basic targets are:
* **app**: export a signed app
* **app-verify**: verify the app is both signed and accepted by the SIP system aka Gatekeeper
* **app-vars**: print app variables for debugging
* **app-clean**: clean export directory
* **app-clobber**: remove app export

Build files are generated in a temp directory, named `export` by default. The exported app is placed in the calling directory.

### Makefile-mac-dist.mk

Basic combined meta targets are:
* **distzip**: create a zip for distribution with notarized contents
* **distdmg**: create and notarize dmg for distribution
* **distvars**: print makefile variables for debugging
* **distclean**: clean entire dist build directory
* **distclobber**: clean dist zip and dmg files

If both makefiles are included, the **distclean** and **distclobber** targets also invoke **app-clean** and **app-clobber**.

Additional targets are available for each subsection, most of which are invoked by the combined targets above:
* **dist**: copy files into dist dir
* **dist-vars**: print dist variables for debugging
* **dist-clean**: clean dist directory
* **codesign**: codesign files, use manually if not exporting a .app from Xcode
* **codesign-remove**: remove code signature(s) from files
* **codesign-verify**: verify code signature(s)
* **codesign-list**: list available codesign identities
* **codesign-vars**: print codesign variables for debugging
* **zip**: create zip
* **zip-vars**: print zip variables for debugging
* **zip-clobber**: remove zip file
* **dmg**: create dmg
* **dmg-vars**: print dmg variables for debugging
* **dmg-clobber**: rm dmg file
* **notarize**: alias for **notarize-dmg**
* **notarize-dmg**: upload and notarize dmg
* **notarize-zip**: upload and notarize zip
* **notarize-verify**: verify signature and acceptance by the SIP system aka Gatekeeper
* **notarize-history**: print request history
* **notarize-vars**: print notarize variables for debugging
* **notarize-clean**: clean notarization directory

Build files are generated in a temp directory, named `dist` by default. The distribution zip and dmg files are placed in the calling directory.

Basic Usage
-----------

Basic usage involves including either or both makefiles in a parent makefile which sets required variables. 

### Cocoa Application Example

For a single native macOS Cocoa app called "HelloWorld" which is built from a "HelloWorld.xcodeproj" Xcode project and should be distributed with meta-data text files by the "Foo Bar Baz Developers" Apple Developer account:

```makefile
# app name to build (no extension) for Makefile-mac-app.mk
mac.app.name = HelloWorld

# dist name and app for Makefile-mac-dist.mk,
# define these if not using Makefile-mac-app.mk
#mac.dist.name = HelloWorld
#mac.dist.apps = $(mac.dist.name).app

# set version string
mac.dist.version = 0.1.0

# additional file to add to distribution
mac.dist.include = README.txt doc

# exclude any of these, .DS_Store and hidden files excluded by default
mac.dist.exclude = *.tmp

# codesign identity, usually a Developer ID Application string
mac.codesign.identity = Foo Bar Baz Developers

include Makefile-mac-app.mk
include Makefile-mac-dist.mk
```

Assuming the relevant Apple Developer signing certificates and App Store Connect password are installed (see following Requirements section), running the following will export a release archive and create a notarized `HelloWorld-0.1.0.dmg`:

```shell
make app
make distdmg
```

The mounted `HelloWorld-0.1.0` disk image contents should contain the app and meta-data within a version-named subdirectory and a convenience link to `/Applications` for drag-and-drop installation:
~~~
/Volumes/HelloWorld-0.1.0/HelloWorld-0.1.0/HelloWorld.app
/Volumes/HelloWorld-0.1.0/HelloWorld-0.1.0/README.txt
/Volumes/HelloWorld-0.1.0/HelloWorld-0.1.0/doc/...
/Volumes/HelloWorld-0.1.0/Applications <--- softlink
~~~

### Dynamic Library Example

For a dynamic library such as a [Pure Data](https://puredata.info) external built from C sources as a renamed `.dylib` called `foobar.pd_darwin` which shoudl be distributd with meta-data files by the "Pd Unicorns LLC" Apple Developer account:

```makefile

mac.dist.name = foobar
mac.dist.libs = foobar.pd_darwin

# set version string
mac.dist.version = 1.2.3

# additional file to add to distribution
mac.dist.include = README.txt LICENSE.txt *.pd

# codesign identity, usually a Developer ID Application string
mac.codesign.identity = Pd Unicrons LLC

include Makefile-mac-dist.mk

# override zip and dmg naming to include platform and arch
mac.dmg.name=$(mac.dist.name.version)-macos-$(shell uname -m)
mac.zip.name=$(mac.dist.name.version)-macos-$(shell uname -m)
```

Similar to `HelloWorld`, create a notarized `foobar-1.2.3-macos-arm64.dmg` with:

```shell
make codesign
make distdmg
```

The mounted `foobar-1.2.3-macos-arm64` disk image contents should contain the lib(s) and meta-data within a version-named subdirectory and a convenience link to `/Applications` for drag-and-drop installation:
~~~
/Volumes/foobar-1.2.3-macos-arm64/foobar-1.2.3/foobar.pd_darwin
/Volumes/foobar-1.2.3-macos-arm64/foobar-1.2.3/README.txt
/Volumes/foobar-1.2.3-macos-arm64/foobar-1.2.3/LICENSE.txt
/Volumes/foobar-1.2.3-macos-arm64/foobar-1.2.3/*.pd...
/Volumes/foobar-1.2.3-macos-arm64/Applications <--- softlink
~~~

### openFrameworks Application

The process for an [openFrameworks](https://openframeworks.cc) application is similar to that for a Cococa application except for several important points:
* openFrameworks projects use the "APPNAME Release" and "APPNAME Debug" naming, so the default `mac.app.project.scheme` variable needs to be overridden
* the `bin/data` directory needs to included, unless the application is including this within its internal `Resources` directory (not by default)

A basic makefile for an openFrameworks call `FooInteractive` might be:
```makefile
# app name to build
mac.app.name = FooInteractive

# openFrameworks projects use the "APPNAME Release" and "APPNAME Debug" naming
mac.app.project.scheme = $(mac.app.name) Release

# include openFrameworks project data
mac.dist.include = bin/data

include Makefile-mac-app.mk
include Makefile-mac-dist.mk
```

Documentation
-------------

Detailed documentation for the makefile variables and targets are currently provided by comments in each makefile component.

Requirements
------------

Minimum requirements:

* GNU Make 3.8+
* Xcode 13+ (or equivalent Commandline Tools version)\*
* Apple Developer account
* Apple Developer "Development" and "Developer ID application" signing certificates installed
* App Store Connect 2FA password installed in keychain

\**For reference, the [Xcode Releases website](https://xcodereleases.com) notes Xcode 13.0 required a minimum of macOS 11.3 (Big Sur).*

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

For details, see the [Apple docs on Certificates](https://developer.apple.com/support/certificates/).

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

`<username>` is the Apple ID username, usually your email address.

`<secret password>` is the app-specific generated password string for two-factor authentication with the Apple servers.

`<team id>` is the developer unique team id used when building and signing the project. If you don't know what it is you can:
* print the current signing identities using `Makefile-mac-dist.mk` via `make codesign-identities`, or
* check the UI in Xcode under the project target's "Signing and Capabilities" settings, or finally,
* log into [developer.app.com](https://developer.apple.com/account/#/membership) and check your account info

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

### Notarizing Zip Contents

When creating a zip with notarized binaries, keep in mind that the contents of the zip which is uploaded to Apple for notarization are *not* stapled on success, only the source binaries. After notarizing succeeds, the zip *must be rebuild* to included the newly notarized binaries. This is done by default when using `make notarize-zip`.

### App Translocation

Apple introduced "App Translocation" which transparently runs applications downloaded in unsigned packages in a random private temp location to make it harder to malware to load resources outside of the .app bundle. This protection is removed if the application is removed from "quarantine" such as if the user movies the .app into their `/Applications` directory.

For details, read the [description](https://www.synack.com/blog/untranslocating-apps/) from the security researcher who identified the original issue.

This process works fine for applications which bundle all of their resources internally, however it *completely breaks* [openFrameworks applications](https://openframeworks.cc) which keep their resources *outside* of the built .app in a `data` folder to make it easy to add and modify resources:

```
bin/MyImageViewer.app
bin/data/image.jpg
```

This application will run fine on the build system, however if the bin folder is copied to another system via a zip file, it will not be able to locate the `data` folder.

The best solution is to avoid App Translocation altogether by packaging the application and it's data within a signed disk image. This is the default action when invoking `make notarize`.

Development
-----------

Release steps:
1. Update changelog
2. Update makefile versions in `Makefile-mac-app.mk` and `Makefile-mac-dist.mk`
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
